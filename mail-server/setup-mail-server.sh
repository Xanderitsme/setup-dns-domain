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
apt install -y postfix

# Configurar Postfix
echo "Configurando Postfix..."
postconf -e "myhostname = $domain"
postconf -e "home_mailbox = Maildir/"
postconf -e "mailbox_command ="
read -p "Ingresa la red local en formato CIDR (e.g., 192.168.1.0/24): " network
postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 $network"

# Reiniciar Postfix
systemctl restart postfix
echo "Postfix configurado y reiniciado."

# Paso 3: Crear Usuarios
for user in liz alice; do
    if ! id "$user" &>/dev/null; then
        adduser --disabled-password --gecos "" "$user"
        echo "Usuario $user creado."
    else
        echo "Usuario $user ya existe."
    fi
done

# Paso 4: Instalar mailx
apt install -y bsd-mailx
echo "mailx instalado."

# Paso 5: Instalar y Configurar Dovecot
apt install -y dovecot-pop3d

# Configurar autenticación en Dovecot
sed -i "s/^#\?disable_plaintext_auth = .*/disable_plaintext_auth = no/" /etc/dovecot/conf.d/10-auth.conf

# Configurar almacenamiento de correos en Dovecot
sed -i "s/^#\?mail_location = mbox.*$/# mail_location = mbox:~\/mail:INBOX=\/var\/mail\/%u/" /etc/dovecot/conf.d/10-mail.conf
sed -i "s/^#\?mail_location = maildir.*$/mail_location = maildir:~\/Maildir/" /etc/dovecot/conf.d/10-mail.conf

# Reiniciar Dovecot
systemctl restart dovecot
echo "Dovecot configurado y reiniciado."

# Finalización
echo "\nServidor de correo configurado exitosamente."
