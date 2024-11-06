# Configuración de un nuevo dominio usando Apache2

## 1. Crear el directorio raíz

Primero, crea el directorio raíz para tu dominio. Reemplaza `[domain]` con el nombre de dominio que desees (por ejemplo, `mysite.com`).

```bash
sudo mkdir /var/www/[domain]
```

## 2. Crear el archivo de índice en el directorio raíz

A continuación, crea un archivo `index.php` en el directorio raíz. Reemplaza `[domain]` con el nombre de tu dominio.

```bash
sudo echo '<?php echo "Este es el sitio de [domain]";' >> /var/www/[domain]/index.php
```

> **Nota**: El contenido del archivo `index.php` es solo un ejemplo. Puedes editarlo más tarde según tus necesidades.

## 3. Crear el archivo de configuración del sitio

Crea el archivo de configuración para tu dominio. Reemplaza `[domain]` con el nombre de tu dominio y `[subdomain]` con el subdominio deseado (por ejemplo, `www`).

```bash
sudo nano /etc/apache2/sites-available/[domain].conf
```

Pega el siguiente contenido en el archivo. Asegúrate de reemplazar `[subdomain]` y `[domain]` por los valores correspondientes:

```apache
<VirtualHost *:80>
    ServerName [subdomain].[domain]
    DirectoryIndex index.html index.php
    DocumentRoot /var/www/[domain]
    ErrorLog ${APACHE_LOG_DIR}/[domain]-error.log
    CustomLog ${APACHE_LOG_DIR}/[domain]-access.log combined

    <Directory /var/www/[domain]>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

Una vez que hayas pegado el contenido, guarda y cierra el archivo.

## 4. Activar el sitio

Activa el archivo de configuración del sitio usando el siguiente comando, reemplazando `[domain]` con el nombre de tu dominio.

```bash
sudo a2ensite [domain].conf
```

## 5. Recargar Apache para aplicar la nueva configuración

Finalmente, recarga Apache para que los cambios surtan efecto.

```bash
sudo systemctl reload apache2
```

---

¡Listo! Ahora tu nuevo dominio debería estar configurado y funcionando con Apache2. Puedes probar accediendo a tu dominio o subdominio a través de un navegador para asegurarte de que el servidor esté sirviendo el archivo `index.php` correctamente.
