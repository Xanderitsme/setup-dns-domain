# Guía para utilizar el script de configuración de BIND 9

Este script facilita la configuración de un servidor DNS usando BIND 9 en tu servidor Linux. A continuación, te explico cómo usarlo de forma rápida y sencilla.

> [!NOTE]
> El script utilizado en esta guía se encuentra en el archivo `setup-dns-server.sh`

### Requisitos previos
1. **Sistema operativo basado en Debian** (como Ubuntu) con **BIND 9** disponible.
2. **Acceso root** o permisos sudo en el servidor.
3. **Archivo de configuración `dns_config`**: Asegúrate de tener el archivo `dns_config` en el mismo directorio que el script. Este archivo debe definir las siguientes variables:
   - `GATEWAY`: La puerta de enlace de tu red (por ejemplo, `192.168.1.0/24`).
   - `DOMAINS`: Lista de dominios a configurar (por ejemplo, `DOMAINS=("miweb.com" "otraweb.com")`).
   - `NETWORK`: Parte de la red (por ejemplo, `192.168.1`).

### Pasos para utilizar el script

1. **Prepara el archivo de configuración**  
   Asegúrate de tener el archivo `dns_config` en el mismo directorio que el script, con la siguiente información (como ejemplo):

   ```bash
   GATEWAY="192.168.1.0/24"
   DOMAINS=("misitio.com" "otromisitio.com")
   NETWORK="192.168.1"
   SUBDOMAIN="www"
   ```

2. **Haz el script ejecutable**  
   Copia el script en un archivo, por ejemplo, `configurar_dns.sh`, y asegúrate de que sea ejecutable:

   ```bash
   chmod +x configurar_dns.sh
   ```

3. **Ejecuta el script como root**  
   Ejecuta el script con permisos de root (o usando `sudo`):

   ```bash
   sudo ./configurar_dns.sh
   ```

4. **Lo que hace el script**  
   El script realiza las siguientes acciones:
   - **Verifica e instala** los paquetes necesarios: `bind9`, `bind9utils` y `bind9-doc`.
   - **Configura** el archivo `/etc/bind/named.conf.options` con la puerta de enlace y otros parámetros necesarios.
   - **Configura las zonas DNS**: Añade zonas directas para cada dominio y una zona inversa (PTR) para la red.
   - **Crea los archivos de zona** en `/etc/bind/zones/` para cada dominio y su zona inversa.
   - **Reinicia el servicio BIND 9** para aplicar la configuración.

5. **Accede al servidor DNS**  
   Una vez ejecutado el script, el servidor DNS debería estar configurado y listo para resolver los dominios configurados.

### Verificación
Puedes verificar la configuración con los siguientes comandos:

- **Comprobar el estado de BIND 9**:
  ```bash
  sudo systemctl status bind9
  ```

- **Probar la resolución de nombres**:
  Puedes usar `dig` o `nslookup` para verificar que los dominios y subdominios se resuelven correctamente.

  Ejemplo con `dig`:
  ```bash
  dig @localhost misitio.com
  ```

### Resumen de archivos creados

- **Archivos de zona directa**: `/etc/bind/zones/[dominio]`
- **Archivos de zona inversa**: `/etc/bind/zones/[network].rev`
- **Archivo de configuración de Apache (si se integra con el servidor web)**.
