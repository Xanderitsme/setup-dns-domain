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
    "mariadb-server"
    "php7.4"
    "libapache2-mod-php7.4"
    "php7.4-cli"
    "php7.4-mysql"
    "php7.4-json"
    "php7.4-opcache"
    "php7.4-mbstring"
    "php7.4-intl"
    "php7.4-xml"
    "php7.4-gd"
    "php7.4-zip"
    "php7.4-curl"
    "unzip"
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

# Configuración inicial de MariaDB
# apt install expect -y
# expect <<EOF
# spawn mysql_secure_installation
# expect "Enter current password for root (enter for none):"
# send "$MYSQL_ROOT_PASSWORD\r"
# expect "Change the root password?"
# send "n\r"
# expect "Remove anonymous users?"
# send "y\r"
# expect "Disallow root login remotely?"
# send "y\r"
# expect "Remove test database and access to it?"
# send "y\r"
# expect "Reload privilege tables now?"
# send "y\r"
# EOF

# Crear la base de datos y usuario
MYSQL_ROOT_PASSWORD="root"  # Cambiar esto si has configurado una contraseña
DB_NAME="joomladb"
DB_USER="usuariojoomla"
DB_PASS="joomla123"

mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Descargar Joomla
if ! is_package_installed "wget"; then
    echo "wget no está instalado. Instalando..."
    apt install -y wget
fi
wget https://downloads.joomla.org/cms/joomla4/4-0-3/Joomla_4.0.3-Stable-Full_Package.zip

# Descomprimir Joomla
unzip Joomla_4.0.3-Stable-Full_Package.zip -d /var/www/html/joomla

# Cambiar propiedad del directorio
if [ ! -d "/var/www/html/joomla" ]; then
    echo "El directorio Joomla no existe. Creando..."
    mkdir -p /var/www/html/joomla
fi
chown -R www-data:www-data /var/www/html/joomla

# Configurar Apache para Joomla
VHOST_CONF="/etc/apache2/sites-available/joomla.conf"
bash -c "cat > $VHOST_CONF <<EOF
<VirtualHost *:80>
    ServerName joomla.local
    DirectoryIndex index.html index.php
    DocumentRoot /var/www/html/joomla
    ErrorLog \${APACHE_LOG_DIR}/joomla-error.log
    CustomLog \${APACHE_LOG_DIR}/joomla-access.log combined
    <Directory /var/www/html/joomla>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF"

# Habilitar sitio Joomla y reiniciar Apache
a2ensite joomla
systemctl reload apache2

# Habilitar el puerto 80 en ufw
ufw allow 80/tcp

# Obtener la IP del equipo
echo "La dirección IP del servidor es: $IP_ADDRESS"

# Opcional: agregar entrada en el archivo hosts
# echo "$IP_ADDRESS    joomla.local" | tee -a /etc/hosts

echo "Instalación completada. Accede a Joomla en http://$IP_ADDRESS/Joomla"
