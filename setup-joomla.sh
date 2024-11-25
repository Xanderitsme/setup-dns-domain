#!/bin/bash

# Actualizar repositorios
sudo apt update

# Instalar paquetes necesarios
sudo apt install apache2 mariadb-server php7.4 libapache2-mod-php7.4 php7.4-cli \
php7.4-mysql php7.4-json php7.4-opcache php7.4-mbstring php7.4-intl \
php7.4-xml php7.4-gd php7.4-zip php7.4-curl unzip -y

# Editar php.ini
PHP_INI_FILE="/etc/php/7.4/apache2/php.ini"
sudo sed -i 's/^memory_limit = .*/memory_limit = 512M/' $PHP_INI_FILE
sudo sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 256M/' $PHP_INI_FILE
sudo sed -i 's/^post_max_size = .*/post_max_size = 256M/' $PHP_INI_FILE
sudo sed -i 's/^output_buffering = .*/output_buffering = Off/' $PHP_INI_FILE
sudo sed -i 's/^max_execution_time = .*/max_execution_time = 300/' $PHP_INI_FILE
sudo sed -i 's/^;date.timezone =.*/date.timezone = America\/Lima/' $PHP_INI_FILE

# Configuración inicial de MariaDB
# sudo mysql_secure_installation <<EOF

# y
# n
# y
# y
# EOF

# Crear la base de datos y usuario
MYSQL_ROOT_PASSWORD="root"  # Cambiar esto si has configurado una contraseña
DB_NAME="joomladb"
DB_USER="usuariojoomla"
DB_PASS="joomla123"

sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Descargar Joomla
wget https://downloads.joomla.org/cms/joomla4/4-0-3/Joomla_4.0.3-Stable-Full_Package.zip

# Descomprimir Joomla
sudo unzip Joomla_4.0.3-Stable-Full_Package.zip -d /var/www/html/Joomla

# Cambiar propiedad del directorio
sudo chown -R www-data:www-data /var/www/html/Joomla

# Configurar Apache para Joomla
VHOST_CONF="/etc/apache2/sites-available/joomla.conf"
sudo bash -c "cat > $VHOST_CONF <<EOF
<VirtualHost *:80>
    ServerName serverweb
    DirectoryIndex index.html index.php
    DocumentRoot /var/www/html/Joomla
    ErrorLog \${APACHE_LOG_DIR}/joomla-error.log
    CustomLog \${APACHE_LOG_DIR}/joomla-access.log combined
    <Directory /var/www/html/Joomla>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF"

# Habilitar sitio Joomla y reiniciar Apache
sudo a2ensite joomla
sudo systemctl reload apache2

# Habilitar el puerto 80 en ufw
sudo ufw allow 80/tcp

# Obtener la IP del equipo
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "La dirección IP del servidor es: $IP_ADDRESS"

# Opcional: agregar entrada en el archivo hosts
# echo "$IP_ADDRESS    Joomla.unamad" | sudo tee -a /etc/hosts

echo "Instalación completada. Accede a Joomla en http://$IP_ADDRESS/Joomla"
