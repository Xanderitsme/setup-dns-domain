# Guía para Configurar un Servidor LDAP en Ubuntu

Este tutorial te guiará paso a paso para configurar un servidor LDAP en Ubuntu, incluyendo la instalación de herramientas necesarias, configuración del servidor y ajustes adicionales.

## 1. **Instalar los Paquetes Necesarios**

Primero, instalamos los paquetes esenciales para LDAP:

```bash
sudo apt update
sudo apt install slapd ldap-utils phpldapadmin libnss-ldap libpam-ldap -y
```

## 2. **Configurar el Servidor LDAP**

### 2.1 **Configuración Inicial de `slapd`**

Después de la instalación, configura el servidor LDAP con el siguiente comando:

```bash
sudo dpkg-reconfigure slapd
```

Completa los siguientes campos según tu configuración (reemplaza `[dominio]` y `[base-dominio]` con tu propio dominio y nombre de organización):

- **Omitir configuración LDAP:** No
- **Nombre de dominio:** `[dominio]` (ej. `misitio.com`)
- **Nombre de la organización:** `[base-dominio]` (ej. `misitio`)
- **Contraseña del servidor LDAP:** Elige y confirma una contraseña segura para el administrador LDAP.
- **Remover base de datos:** No
- **Mover base de datos antigua:** Sí

## 3. **Configurar Archivos de Configuración LDAP**

### 3.1 **Configurar `/etc/ldap/ldap.conf`**

Edita el archivo de configuración principal de LDAP:

```bash
sudo nano /etc/ldap/ldap.conf
```

Modifica las siguientes líneas (reemplaza `[base-domain]` con tu dominio y `[ip]` con la IP de tu servidor):

```bash
BASE   dc=[base-domain],dc=com
URI    ldap://[ip]:389
TLS_CACERT      /etc/ssl/certs/ca-certificates.crt
```

### 3.2 **Configurar `/etc/nsswitch.conf`**

Este archivo define cómo se resuelven las consultas de nombre, como usuarios, grupos y contraseñas. Edita el archivo:

```bash
sudo nano /etc/nsswitch.conf
```

Asegúrate de que las siguientes líneas se vean como sigue:

```bash
passwd:         files ldap
group:          files ldap
shadow:         files ldap
gshadow:        files
hosts:          files dns
networks:       files
protocols:      db files
services:       db files
ethers:         db files
rpc:            db files
netgroup:       nis
```

## 4. **Configurar PHP LDAP Admin (Opcional)**

### 4.1 **Configurar `phpldapadmin`**

Edita la configuración de `phpldapadmin` para que se conecte a tu servidor LDAP:

```bash
sudo nano /etc/phpldapadmin/config.php
```

Busca las siguientes líneas y cámbialas con los valores adecuados:

```php
$servers->setValue('server','name','[nombre de la organización]');
$servers->setValue('server','host','[ip]');
$servers->setValue('server','base',array('dc=[base-domain],dc=com'));
```

### 4.2 **Verificación a Través de la Web (Opcional)**

Puedes verificar el acceso a LDAP a través de la interfaz web de `phpldapadmin` en:

```
http://[ip]/phpldapadmin
```

Inicia sesión con las siguientes credenciales:

- **Usuario:** `cn=admin,dc=[base-domain],dc=com`
- **Contraseña:** La contraseña que configuraste previamente.

Intenta crear grupos o usuarios para verificar que todo esté funcionando.

## 5. **Configurar Autenticación y Creación de Directorios de Inicio (Home Directories)**

### 5.1 **Configurar `mkhomedir` para Crear Directorios de Inicio Automáticamente**

Edita el archivo de configuración de PAM para crear directorios de inicio al iniciar sesión:

```bash
sudo nano /usr/share/pam-configs/mkhomedir
```

Modifica el archivo para que se vea así:

```bash
Name: Create home directory on login
Default: yes
Priority: 900
Session-Type: Additional
Session:
        required                        pam_mkhomedir.so umask=0022 skel=/etc/skel
```

### 5.2 **Actualizar la Configuración de PAM**

Ejecuta el siguiente comando para aplicar la configuración:

```bash
sudo pam-auth-update
```

En la interfaz que aparece, selecciona todas las opciones excepto "Autenticación biométrica".

### 5.3 **Ajustes en Archivos de PAM**

Asegúrate de que los siguientes archivos tengan las configuraciones correctas.

- Edita `/etc/pam.d/common-account`:

```bash
sudo nano /etc/pam.d/common-account
```

Asegúrate de que contenga la siguiente línea (agregarla si no está):

```bash
account required pam_unix.so
```

- Edita `/etc/pam.d/common-session`:

```bash
sudo nano /etc/pam.d/common-session
```

Agrega la siguiente línea si no está:

```bash
session required pam_limits.so
```

## 6. **Comprobar el Funcionamiento**

Una vez que hayas completado todos estos pasos, el servidor LDAP debe estar funcionando correctamente. Puedes comprobarlo con el comando `ldapsearch` para verificar que la base de datos LDAP responde correctamente.

Ejemplo de búsqueda de usuarios:

```bash
ldapsearch -x -b "dc=[base-domain],dc=com" "(objectClass=inetOrgPerson)"
```
