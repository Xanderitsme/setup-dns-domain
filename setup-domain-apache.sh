#!/bin/bash

# Solicitar información al usuario

while [ -z "$DOMAIN" ]; do
read -p "Introduce el dominio (ejemplo: mysite.com): " DOMINIO
if [ -z "$DOMAIN" ]; then
echo "El dominio no puede estar vacío. Por favor, introduce un valor."
fi
done

read -p "Introduce el subdominio (ejemplo: www): " SUBDOMAIN

# Establecer un valor por defecto si el subdominio esta vacio

SUBDOMAIN="${SUBDOMAIN:-www}"

# Crear el directorio raíz

echo "Creando el directorio raíz /var/www/$DOMAIN"
mkdir -p /var/www/$DOMAIN

# Crear el archivo raíz para el sitio

ROOT_DOCUMENT="/var/www/$DOMAIN/index.php"
echo "Creando el archivo raíz $ROOT_DOCUMENT"
cat <<EOF > "$ROOT_DOCUMENT"

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width">
  <title>$DOMAIN</title>
</head>
<body>
	<p>Este el sitio web de $DOMAIN</p>
</body>
EOF

# Crear el archivo de configuración para el sitio

CONFIG_FILE="/etc/apache2/sites-available/$DOMAIN.conf"
echo "Creando el archivo de configuración para el sitio $CONFIG_FILE"
cat <<EOF > "$CONFIG_FILE"
<VirtualHost *:80>
    ServerName $SUBDOMAIN.$DOMAIN
    DirectoryIndex index.html index.php
    DocumentRoot /var/www/$DOMAIN
    ErrorLog ${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog ${APACHE_LOG_DIR}/$DOMAIN-access.log combined

    <Directory /var/www/$DOMAIN>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Habilitar el sitio en Apache

echo "Habilitando el sitio en Apache"
a2ensite $DOMAIN.conf

# Recargar Apache para aplicar los cambios

echo "Recargando Apache para aplicar la nueva configuración"
systemctl reload apache2

echo "El sitio $DOMAIN con subdominio $SUBDOMAIN ha sido configurado correctamente en: http://$SUBDOMAIN.$DOMAIN"
