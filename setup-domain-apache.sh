#!/bin/bash

# Solicitar información al usuario

while [ -z "$DOMINIO" ]; do
read -p "Introduce el dominio (ejemplo: mysite.com): " DOMINIO
if [ -z "$DOMINIO" ]; then
echo "El dominio no puede estar vacío. Por favor, introduce un valor."
fi
done

read -p "Introduce el subdominio (ejemplo: www): " SUBDOMINIO

# Establecer un valor por defecto si el subdominio esta vacio

SUBDOMINIO="${SUBDOMINIO:-www}"

# Crear el directorio raíz

echo "Creando el directorio raíz /var/www/$DOMINIO"
mkdir -p /var/www/$DOMINIO

# Crear el archivo raíz para el sitio

ROOT_DOCUMENT="/var/www/$DOMINIO/index.php"
echo "Creando el archivo raíz $ROOT_DOCUMENT"
cat <<EOF > "$ROOT_DOCUMENT"

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width">
  <title>$DOMINIO</title>
</head>
<body>
	<p>Este el sitio web de $DOMINIO</p>
</body>
EOF

# Crear el archivo de configuración para el sitio

CONFIG_FILE="/etc/apache2/sites-available/$DOMINIO.conf"
echo "Creando el archivo de configuración para el sitio $CONFIG_FILE"
cat <<EOF > "$CONFIG_FILE"
<VirtualHost \*:80>
ServerName $SUBDOMINIO.$DOMINIO
DirectoryIndex index.html index.php
DocumentRoot /var/www/$DOMINIO
    ErrorLog \${APACHE_LOG_DIR}/$DOMINIO-error.log
CustomLog \${APACHE_LOG_DIR}/$DOMINIO-access.log combined
    <Directory /var/www/$DOMINIO>
Options FollowSymLinks
AllowOverride All
Require all granted
</Directory>
</VirtualHost>
EOF

# Habilitar el sitio en Apache

echo "Habilitando el sitio en Apache"
a2ensite $DOMINIO.conf

# Recargar Apache para aplicar los cambios

echo "Recargando Apache para aplicar la nueva configuración"
systemctl reload apache2

echo "El sitio $DOMINIO con subdominio $SUBDOMINIO ha sido configurado correctamente en: http://$SUBDOMINIO.$DOMINIO"
