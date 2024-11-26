#!/bin/bash

# Verificar si el script es ejecutado por el usuario root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ser ejecutado como root."
    echo "Por favor, ejecute el script con sudo:"
    echo "    sudo $0"
    exit 1
else
    echo "El script está siendo ejecutado como root."
fi

# Función para comprobar si un paquete está instalado
is_package_installed() {
    dpkg -l | grep -q "^ii  $1 "  # Busca el paquete en la lista de paquetes instalados
}

# Función para obtener la IP y red actuales
get_current_ip() {
    hostname -I | awk '{print $1}'
}

# Obtener IP y red actuales
IP_ADDRESS=$(get_current_ip)

# Actualizar repositorios
apt update

# Paso 1: Verificar e instalar los paquetes que faltan
# Comprobar si los paquetes necesarios están instalados
echo "Verificando si los paquetes necesarios están instalados..."

# Lista de paquetes necesarios
PACKAGES=(
    "apache2" 
    "php"
)

for PACKAGE in "${PACKAGES[@]}"; do
    if ! is_package_installed "$PACKAGE"; then
        echo "$PACKAGE no está instalado. Instalando..."
        apt install -y "$PACKAGE"
    else
        echo "$PACKAGE ya está instalado."
    fi
done

# Editar php.ini
PHP_INI_FILE="/etc/php/7.4/apache2/php.ini"
sed -i 's/^memory_limit = .*/memory_limit = 512M/' $PHP_INI_FILE
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 256M/' $PHP_INI_FILE
sed -i 's/^post_max_size = .*/post_max_size = 256M/' $PHP_INI_FILE
sed -i 's/^output_buffering = .*/output_buffering = Off/' $PHP_INI_FILE
sed -i 's/^max_execution_time = .*/max_execution_time = 300/' $PHP_INI_FILE
sed -i 's/^;date.timezone =.*/date.timezone = America\/Lima/' $PHP_INI_FILE

# Cambiar propiedad del directorio
chown -R www-data:www-data /var/www/html/

# Habilitar el puerto 80 en ufw
ufw allow 80/tcp

echo "Instalación completada. Accede ahora http://$IP_ADDRESS"
