#!/bin/bash

# Verificar si el script se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root" 
   exit 1
fi

# 1. Configurar hostname
read -p "Ingresa el nombre de dominio (hostname): " domain
hostnamectl set-hostname "$domain"
echo "$domain" > /etc/mailname

# 2. Instalar postfix
apt update
apt install -y postfix

# Configurar postfix
postconf -e "myhostname = $domain"
postconf -e "home_mailbox = Maildir/"
postconf -e "mailbox_command ="

# 3. Agregar usuarios
for user in liz alice; do
    if ! id "$user" &>/dev/null; then
        adduser --disabled-password --gecos "" "$user"
        echo "Usuario $user creado."
    else
        echo "Usuario $user ya existe."
    fi
done

# 4. Instalar mailx
apt install -y bsd-mailx

# 5. Instalar dovecot pop3d
apt install -y dovecot-pop3d

# 6. Configurar red local para postfix
read -p "Ingresa la red local en formato CIDR (e.g., 192.168.1.0/24): " network
sed -i "s/^mynetworks = .*/mynetworks = 127.0.0.0\/8 [::ffff:127.0.0.0]\/104 [::1]\/128 $network/" /etc/postfix/main.cf

# 7. Configurar autenticación y almacenamiento en Dovecot
# Configurar autenticación
sed -i "s/^#\?disable_plaintext_auth = .*/disable_plaintext_auth = no/" /etc/dovecot/conf.d/10-auth.conf

# Configurar almacenamiento de correo
sed -i "s/^#\?mail_location = mbox.*$/# mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/" /etc/dovecot/conf.d/10-mail.conf
sed -i "s/^#\?mail_location = maildir.*$/mail_location = maildir:~\/Maildir/" /etc/dovecot/conf.d/10-mail.conf

# Reiniciar servicios
systemctl restart postfix
echo "Postfix reiniciado."

systemctl restart dovecot
echo "Dovecot reiniciado."

echo "\nServidor de correo configurado exitosamente."
