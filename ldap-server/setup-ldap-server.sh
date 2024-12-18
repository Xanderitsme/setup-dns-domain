#!/bin/bash

# Script para configurar un servidor LDAP en Ubuntu automáticamente

# Comprobar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Función para comprobar si un paquete está instalado
is_package_installed() {
    dpkg -l | grep -q "^ii  $1 "  # Busca el paquete en la lista de paquetes instalados
}

# Función para mostrar mensajes
msg() {
    echo -e "\n\e[1;32m$1\e[0m\n"
}

# Función para agregar una línea solo si no está presente
ensure_line_in_file() {
    local line="$1"
    local file="$2"
    if ! grep -Fxq "$line" "$file"; then
        echo "$line" | sudo tee -a "$file" > /dev/null
        msg "Agregado: '$line' en $file"
    else
        msg "La línea ya está presente en $file: '$line'"
    fi
}

# Verificar si existe el archivo de configuración externo
CONFIG_FILE="ldap.conf"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Archivo de configuración '$CONFIG_FILE' no encontrado."
  exit 1
fi

# Cargar variables desde el archivo de configuración
source "$CONFIG_FILE"

# 1. Instalación de paquetes necesarios
msg "Instalando slapd y ldap-utils..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils

# Configurar slapd de forma no interactiva
msg "Configurando slapd..."
echo "slapd slapd/no_configuration boolean false" | sudo debconf-set-selections
echo "slapd slapd/domain string $LDAP_DOMAIN" | sudo debconf-set-selections
echo "slapd shared/organization string $LDAP_BASE_DOMAIN" | sudo debconf-set-selections
echo "slapd slapd/password1 password $LDAP_ADMIN_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/password2 password $LDAP_ADMIN_PASSWORD" | sudo debconf-set-selections
echo "slapd slapd/backend select MDB" | sudo debconf-set-selections
echo "slapd slapd/purge_database boolean false" | sudo debconf-set-selections
echo "slapd slapd/move_old_database boolean true" | sudo debconf-set-selections
sudo dpkg-reconfigure -f noninteractive slapd

# Verificar instalación
msg "Verificando la instalación del servidor LDAP..."
ldapsearch -x

# 2. Configurar archivos de configuración LDAP
msg "Configurando /etc/ldap/ldap.conf..."
sudo bash -c "cat > /etc/ldap/ldap.conf" <<EOF
BASE    dc=${LDAP_BASE_DOMAIN},dc=com
URI     ldap://${SERVER_IP}:389
TLS_CACERT      /etc/ssl/certs/ca-certificates.crt
EOF

msg "Configurando /etc/nsswitch.conf..."
sudo sed -i 's/^passwd:         .*/passwd:         files ldap/' /etc/nsswitch.conf
sudo sed -i 's/^group:          .*/group:          files ldap/' /etc/nsswitch.conf
sudo sed -i 's/^shadow:         .*/shadow:         files ldap/' /etc/nsswitch.conf

# 3. Instalar y configurar libnss-ldap y libpam-ldap
msg "Instalando libnss-ldap y libpam-ldap..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y libnss-ldap libpam-ldap

# Configuración no interactiva
msg "Configurando libnss-ldap y libpam-ldap..."
echo "ldap-auth-config ldap-auth-config/ldapns/ldap-server string ldap://${SERVER_IP}" | sudo debconf-set-selections
echo "ldap-auth-config ldap-auth-config/ldapns/base-dn string dc=${LDAP_BASE_DOMAIN},dc=com" | sudo debconf-set-selections
echo "ldap-auth-config ldap-auth-config/ldapns/ldap_version select 3" | sudo debconf-set-selections
echo "ldap-auth-config ldap-auth-config/ldapns/ldap-login-pass password $LDAP_ADMIN_PASSWORD" | sudo debconf-set-selections
sudo pam-auth-update --enable mkhomedir

# 4. Instalar y configurar phpldapadmin
msg "Instalando phpldapadmin..."
sudo apt install -y phpldapadmin

msg "Configurando phpldapadmin..."
sudo sed -i "s|\$servers->setValue('server','host','.*');|\$servers->setValue('server','host','$SERVER_IP');|g" /etc/phpldapadmin/config.php
sudo sed -i "s|\$servers->setValue('server','base',array('.*'));|\$servers->setValue('server','base',array('dc=${LDAP_BASE_DOMAIN},dc=com'));|g" /etc/phpldapadmin/config.php
sudo sed -i "s|\$servers->setValue('server','name','.*');|\$servers->setValue('server','name','$PHPLDAPADMIN_ORG');|g" /etc/phpldapadmin/config.php

# 5. Configurar creación automática de directorios de inicio
msg "Configurando creación automática de directorios de inicio..."
sudo bash -c "cat > /usr/share/pam-configs/mkhomedir" <<EOF
Name: Create home directory on login
Default: yes
Priority: 900
Session-Type: Additional
Session:
        required                        pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF

sudo pam-auth-update --enable mkhomedir

# Ajustes finales en PAM
msg "Ajustando archivos PAM..."

ensure_line_in_file "account required pam_unix.so" "/etc/pam.d/common-account"
ensure_line_in_file "session required pam_limits.so" "/etc/pam.d/common-session"

# 6. Reiniciar servicios
msg "Reiniciando servicios LDAP..."
sudo systemctl restart slapd

# 7. Verificación
msg "Verificación final del servidor LDAP..."
ldapsearch -x -b "dc=${LDAP_BASE_DOMAIN},dc=com" "(objectClass=inetOrgPerson)"

msg "Configuración completada. Accede a phpldapadmin en: http://${SERVER_IP}/phpldapadmin"
