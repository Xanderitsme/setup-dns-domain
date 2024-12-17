# Guía para Configurar un Servidor LDAP en Ubuntu

Este tutorial te guiará paso a paso para configurar un servidor LDAP en Ubuntu, incluyendo la instalación de herramientas necesarias, configuración del servidor y ajustes adicionales.

## 1. **Instalar los Paquetes Necesarios**

### 1.1 **Instalar `slapd` y `ldap-utils`**

Primero, instalamos los paquetes esenciales para el servidor LDAP (`slapd`), que es el demonio principal de LDAP, y `ldap-utils`, que nos proporciona herramientas útiles para interactuar con el servidor LDAP:

```bash
sudo apt install slapd ldap-utils -y
```

Durante la instalación, se te pedirá que ingreses una contraseña para el administrador de LDAP. Esta contraseña se usará para gestionar el servidor LDAP, así que asegúrate de elegir una contraseña segura.

### 1.2 **Configurar `slapd`**

Una vez instalado `slapd`, necesitarás hacer una configuración inicial para establecer los parámetros básicos de tu servidor LDAP. Ejecuta el siguiente comando:

```bash
sudo dpkg-reconfigure slapd
```

Completa los siguientes campos:

- **Omitir configuración LDAP:** No
- **Nombre de dominio:** `[dominio]` (ej. `empresa.com`)
- **Nombre de la organización:** `[base-dominio]` (ej. `empresa`)
- **Contraseña del servidor LDAP:** Elige y confirma una contraseña segura para el administrador LDAP.
- **Remover base de datos:** No
- **Mover base de datos antigua:** Sí

### 1.3 **Verificar la Instalación**

Para verificar que `slapd` está funcionando correctamente, puedes usar el siguiente comando para buscar información en el servidor LDAP:

```bash
ldapsearch -x
```

Si ves un resultado que incluye la información de tu servidor LDAP, significa que la instalación fue exitosa.

---

## 2. **Configurar Archivos de Configuración LDAP**

### 2.1 **Configurar el Archivo `/etc/ldap/ldap.conf`**

Este archivo contiene la configuración global de tu cliente LDAP. Debes editarlo para que apunte al servidor LDAP correctamente:

```bash
sudo nano /etc/ldap/ldap.conf
```

Modifica las siguientes líneas (reemplaza `[base-domain]` con tu dominio y `[ip]` con la IP de tu servidor LDAP):

```bash
BASE   dc=[base-domain],dc=com
URI    ldap://[ip]:389
TLS_CACERT      /etc/ssl/certs/ca-certificates.crt
```

### 2.2 **Configurar el Archivo `/etc/nsswitch.conf`**

Este archivo configura cómo se resuelven las consultas de usuario, grupos y contraseñas. Debes editarlo para que use LDAP como fuente de información:

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

---

## 3. **Instalar y Configurar `libnss-ldap` y `libpam-ldap`**

### 3.1 **Instalar `libnss-ldap` y `libpam-ldap`**

Estos paquetes permiten que tu sistema utilice LDAP para autenticar usuarios. Debes instalarlos de forma independiente para asegurarte de completar la configuración interactiva que se muestra durante la instalación:

```bash
sudo apt install libnss-ldap libpam-ldap -y
```

Durante la instalación, se te pedirá que completes varios parámetros. Asegúrate de completar los siguientes valores:

- **LDAP server uniform resource identifier:** `ldap://[ip]` (reemplaza `[ip]` con la IP de tu servidor LDAP).
- **Distinguished name of the search base:** `dc=[base-domain],dc=com` (reemplaza `[base-domain]` con tu dominio, por ejemplo `misitio`).
- **LDAP version to use:** `3` (elige la versión más alta disponible).
- **Make local root database admin:** `yes` (esto le da permisos administrativos a la cuenta `root` local).
- **Does the LDAP database require login?:** `no` (esto es para indicar que no es necesario iniciar sesión para acceder al LDAP).
- **LDAP account for root:** `cn=admin,dc=[base-domain],dc=com` (reemplaza `[base-domain]` con tu dominio).
- **LDAP root account password:** Introduce la contraseña que configuraste para el administrador LDAP.

---

## 4. **Instalar y Configurar `phpldapadmin` (Opcional)**

Si deseas administrar tu servidor LDAP de forma visual a través de un navegador web, puedes instalar `phpldapadmin`. Este es un cliente web que permite interactuar con el servidor LDAP.

### 4.1 **Instalar `phpldapadmin`**

Para instalar `phpldapadmin`, usa el siguiente comando:

```bash
sudo apt install phpldapadmin -y
```

### 4.2 **Configurar `phpldapadmin`**

Una vez instalado, edita el archivo de configuración de `phpldapadmin` para que se conecte correctamente a tu servidor LDAP:

```bash
sudo nano /etc/phpldapadmin/config.php
```

Busca las siguientes líneas y modifícalas con los valores correctos:

```php
$servers->setValue('server','name','[nombre de la organización]');
$servers->setValue('server','host','[ip]');
$servers->setValue('server','base',array('dc=[base-domain],dc=com'));
```

- **[nombre de la organización]:** El nombre de tu organización (ej. `empresa`).
- **[ip]:** La dirección IP de tu servidor LDAP.
- **[base-domain]:** Tu dominio (ej. `empresa`).

### 4.3 **Acceder a `phpldapadmin` (Opcional)**

Puedes acceder a la interfaz web de `phpldapadmin` desde un navegador usando la siguiente URL:

```
http://[ip]/phpldapadmin
```

Inicia sesión con las siguientes credenciales:

- **Usuario:** `cn=admin,dc=[base-domain],dc=com`
- **Contraseña:** La contraseña que configuraste para el administrador LDAP.

---

## 5. **Configurar la Creación Automática de Directorios de Inicio (Home Directories)**

### 5.1 **Configurar `mkhomedir` para Crear Directorios de Inicio al Iniciar Sesión**

Edita el archivo de configuración de PAM para que los directorios de inicio se creen automáticamente cuando los usuarios inicien sesión:

```bash
sudo nano /usr/share/pam-configs/mkhomedir
```

Asegúrate de que el archivo contenga lo siguiente:

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

---

## 6. **Ajustes Finales en los Archivos de PAM**

### 6.1 **Modificación de `/etc/pam.d/common-account`**

Asegúrate de que el archivo `/etc/pam.d/common-account` contenga la siguiente línea. Si no está, agrégala:

```bash
sudo nano /etc/pam.d/common-account
```

Agrega:

```bash
account required pam_unix.so
```

### 6.2 **Modificación de `/etc/pam.d/common-session`**

Haz lo mismo con el archivo `/etc/pam.d/common-session`, asegurándote de que contenga la siguiente línea:

```bash
sudo nano /etc/pam.d/common-session
```

Agrega:

```bash
session required pam_limits.so
```

---

## 7. **Verificar el Funcionamiento**

Una vez que hayas completado estos pasos, puedes verificar que el servidor LDAP esté funcionando correctamente. Puedes hacerlo con un comando como `ldapsearch`:

```bash
ldapsearch -x -b "dc=[base-domain],dc=com" "(objectClass=inetOrgPerson)"
```

---

¡Con esto, tu servidor LDAP estará configurado correctamente y listo para ser usado!
