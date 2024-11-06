# Guía rápida para usar el script de configuración de dominio y subdominio en Apache

Este script te permite configurar rápidamente un nuevo sitio web en Apache con un dominio y subdominio personalizados. A continuación, se detallan los pasos para utilizarlo.

> [!NOTE]
> El script utilizado en esta guía se encuentra en el archivo `setup-domain-apache.sh`

### Requisitos previos

1. Asegúrate de tener **Apache2** instalado en tu servidor.
2. El script necesita permisos de **root** para crear archivos de configuración y reiniciar Apache.

### Pasos para usar el script

1. **Prepara el script**: Copia el script en un archivo, por ejemplo, `setup-domain-apache.sh`.

2. **Hazlo ejecutable**: Asegúrate de que el script sea ejecutable con el siguiente comando:

   ```bash
   chmod +x configurar_sitio.sh
   ```

3. **Ejecuta el script**: Corre el script como usuario `root` o con `sudo`:

   ```bash
   sudo ./configurar_sitio.sh
   ```

4. **Introduce los datos solicitados**: El script pedirá dos cosas:
   - **Dominio**: Ingresa el nombre del dominio, por ejemplo, `misitio.com`.
   - **Subdominio**: Ingresa el subdominio (por ejemplo, `www`). Si dejas este campo vacío, se asignará un valor predeterminado de `www`.

5. **Configuración automática**: El script realizará lo siguiente:
   - Creará el directorio raíz para el sitio en `/var/www/[dominio]`.
   - Generará un archivo `index.php` básico con el nombre de tu dominio.
   - Creará un archivo de configuración de Apache para el dominio y subdominio proporcionados.
   - Activará el sitio en Apache y recargará el servidor para aplicar los cambios.

6. **Accede al sitio**: Una vez completado, podrás acceder a tu sitio web en:

   ```
   http://[subdominio].[dominio]
   ```

   Ejemplo: si ingresas `mysite.com` como dominio y `www` como subdominio, el sitio estará disponible en `http://www.mysite.com`.
