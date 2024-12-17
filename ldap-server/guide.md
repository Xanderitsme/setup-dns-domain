# Guía para Configurar un Servidor ldap

instalar paquetes
```bash
sudo apt install slapd ldap-utils -y
```

ingresa una nueva contraseña para el servidor ldap y luego confirma la contraseña

realizar la configuración inicial
```bash
sudo dpkg-reconfigure slapd
```

completa los campos de la siguiente manera (reemplaza [dominio] con tu dominio por ejemplo `misitio.com` [base-dominio] ejemplo `misitio`):

  - Omitir configuración ldap: `no`
  - Nombre de dominio: `[dominio]`
  - Nombre de la organización: `[base-dominio]`
  - contraseña servidor ldap: `crea tu propia contraseña`
  - confirmar contraseña: `vuelve a introducir tu contraseña`
  - remover base de datos: `no`
  - mover base de datos antigua: `yes`

```bash
sudo nano /etc/ldap/ldap.conf
```

modifica el archivo de esta forma (reemplaza `[base-domain]` y `[ip]` con los valores correspondientes, `[ip]` es la ip del servidor actual lo puedes obtener al ejecutar `hostname -I`)

```bash
#
# LDAP Defaults
#

# See ldap.conf(5) for details
# This file should be world readable but not world writable.

BASE   dc=[base-domain],dc=com
URI    ldap://[ip]:389

#SIZELIMIT      12
#TIMELIMIT      15
#DEREF          never

# TLS certificates (needed for GnuTLS)
TLS_CACERT      /etc/ssl/certs/ca-certificates.crt
```

```bash
sudo nano /etc/nsswitch.conf
```

realiza los siguientes cambios

```bash
# /etc/nsswitch.conf
#
# Example configuration of GNU Name Service Switch functionality.
# If you have the `glibc-doc-reference' and `info' packages installed, try:
# `info libc "Name Service Switch"' for information about this file.

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

instalar phpldapadmin

```bash
sudo apt install phpldapadmin -y
```

```bash
sudo nano /etc/phpldapadmin/config.php
```

busca estos valores y cambialos

```bash
$servers->setValue('server','name','[nombre de la organizacion]');

$servers->setValue('server','host','[ip]');

$servers->setValue('server','base',array('dc=[base-domain],dc=com'));
```