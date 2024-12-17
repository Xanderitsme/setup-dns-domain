#!/bin/bash

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root" 
   exit 1
fi

# Paso 1: Configurar hostname
read -p "Ingresa el nombre de dominio (hostname): " domain
hostnamectl set-hostname "$domain"
echo "$domain" > /etc/mailname

# Paso 2: Instalar y Configurar Postfix
apt update
apt install -y postfix postfix-ldap

# Configurar Postfix
echo "Configurando Postfix..."
postconf -e "myhostname = $domain"
postconf -e "home_mailbox = Maildir/"
postconf -e "mailbox_command ="
read -p "Ingresa la red local en formato CIDR (e.g., 192.168.1.0/24): " network
postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $network"
postconf -e "virtual_alias_maps = ldap:/etc/postfix/ldap-aliases.cf"
postconf -e "virtual_mailbox_maps = ldap:/etc/postfix/ldap-mailboxes.cf"
postconf -e "virtual_transport = lmtp:unix:private/dovecot-lmtp"

# Configurar acceso LDAP en Postfix
cat > /etc/postfix/ldap-aliases.cf <<EOL
server_host = ldap://localhost
search_base = dc=example,dc=com
query_filter = (&(mail=%s)(objectClass=inetOrgPerson))
result_attribute = mail
bind = no
EOL

cat > /etc/postfix/ldap-mailboxes.cf <<EOL
server_host = ldap://localhost
search_base = dc=example,dc=com
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
hosts = localhost
dn = cn=admin,dc=example,dc=com
dnpass = admin_password
base = dc=example,dc=com
user_attrs = homeDirectory=home,uidNumber=uid,gidNumber=gid
user_filter = (&(objectClass=posixAccount)(uid=%u))
pass_filter = (&(objectClass=posixAccount)(uid=%u))
EOL

sed -i "s/^#\?disable_plaintext_auth = .*/disable_plaintext_auth = no/" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/^#\?auth_mechanisms = .*/auth_mechanisms = plain login/" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/^#\?!include auth-system.conf.ext/!include auth-ldap.conf.ext/" /etc/dovecot/conf.d/10-auth.conf

# Reiniciar Dovecot
systemctl restart dovecot
echo "Dovecot configurado y reiniciado."

# Paso 4: Finalización
echo "\nServidor de correo configurado exitosamente con soporte LDAP."
