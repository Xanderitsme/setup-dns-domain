#!/bin/bash

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root" 
   exit 1
fi

# ========================
# Variables de configuración
# ========================
read -p "Ingresa el nombre de dominio (hostname): " DOMAIN
read -p "Ingresa la red local en formato CIDR (e.g., 192.168.1.0/24): " NETWORK

# Configuración del servidor LDAP
LDAP_SERVER="ldap://localhost"  # Cambiar a la IP o hostname del servidor LDAP
LDAP_BASE="dc=example,dc=com"   # Base de búsqueda en LDAP
LDAP_ADMIN_DN="cn=admin,$LDAP_BASE" # Usuario administrador de LDAP
LDAP_ADMIN_PASS="admin_password"    # Contraseña del usuario administrador
LDAP_USER_FILTER="(&(objectClass=posixAccount)(uid=%u))" # Filtro de usuario LDAP
LDAP_ATTRS="homeDirectory=home,uidNumber=uid,gidNumber=gid" # Atributos mapeados

# ========================
# Inicio del script
# ========================

# Paso 1: Configurar hostname
hostnamectl set-hostname "$DOMAIN"
echo "$DOMAIN" > /etc/mailname

# Paso 2: Instalar y Configurar Postfix
apt update
apt install -y postfix postfix-ldap

# Configurar Postfix
echo "Configurando Postfix..."
postconf -e "myhostname = $DOMAIN"
postconf -e "home_mailbox = Maildir/"
postconf -e "mailbox_command ="
postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $NETWORK"
postconf -e "virtual_alias_maps = ldap:/etc/postfix/ldap-aliases.cf"
postconf -e "virtual_mailbox_maps = ldap:/etc/postfix/ldap-mailboxes.cf"
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

# Configurar acceso LDAP en Postfix
cat > /etc/postfix/ldap-aliases.cf <<EOL
server_host = $LDAP_SERVER
search_base = $LDAP_BASE
query_filter = (&(mail=%s)(objectClass=inetOrgPerson))
result_attribute = mail
bind = no
EOL

cat > /etc/postfix/ldap-mailboxes.cf <<EOL
server_host = $LDAP_SERVER
search_base = $LDAP_BASE
query_filter = (&(mail=%s)(objectClass=inetOrgPerson))
result_attribute = mail
bind = no
EOL

# Reiniciar Postfix
systemctl restart postfix
echo "Postfix configurado y reiniciado."

# Paso 3: Instalar y Configurar Dovecot
apt install -y dovecot-core dovecot-ldap dovecot-imapd dovecot-pop3d

# Configurar almacenamiento de correos en Dovecot
sed -i "s/^#\?mail_location = .*/mail_location = maildir:~\/Maildir/" /etc/dovecot/conf.d/10-mail.conf

# Configurar autenticación LDAP en Dovecot
cat > /etc/dovecot/dovecot-ldap.conf.ext <<EOL
hosts = $LDAP_SERVER
dn = $LDAP_ADMIN_DN
dnpass = $LDAP_ADMIN_PASS
base = $LDAP_BASE
user_attrs = $LDAP_ATTRS
user_filter = $LDAP_USER_FILTER
pass_filter = $LDAP_USER_FILTER
EOL

sed -i "s/^#\?disable_plaintext_auth = .*/disable_plaintext_auth = no/" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/^#\?auth_mechanisms = .*/auth_mechanisms = plain login/" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/^#\?!include auth-system.conf.ext/!include auth-ldap.conf.ext/" /etc/dovecot/conf.d/10-auth.conf

# Reiniciar Dovecot
systemctl restart dovecot
echo "Dovecot configurado y reiniciado."

# Paso 4: Finalización
echo "\nServidor de correo configurado exitosamente con soporte LDAP."
