# Guía para Configurar un Servidor de Correo

Sigue estos pasos para configurar un servidor de correo funcional utilizando Postfix y Dovecot.

---

## Paso 1: Configurar el Nombre del Host (hostname)

1. Verifica el hostname actual:
   ```bash
   sudo hostname
   ```
2. Cambia el hostname al nombre de tu dominio:
   ```bash
   sudo hostnamectl set-hostname [tu-dominio]
   echo "[tu-dominio]" | sudo tee /etc/mailname
   ```

---

## Paso 2: Instalar y Configurar Postfix

1. Instala Postfix:
   ```bash
   sudo apt install -y postfix
   ```
2. Configura Postfix:

   - Tipo de servidor: **Sitio de internet**
   - Nombre del dominio: `[tu-dominio]`

3. Verifica la configuración:

   ```bash
   cat /etc/mailname
   ```

   Si necesitas cambiar el dominio, edita `/etc/mailname` y reinicia Postfix:

   ```bash
   sudo nano /etc/mailname
   ```

   ```bash
   sudo systemctl restart postfix
   ```

4. Configura el buzón y redes locales:
   ```bash
   sudo nano /etc/postfix/main.cf
   ```
   Asegúrate de incluir estas líneas (sustituye `[red-local]` por la IP de tu red):
   ```
   mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 [red-local]
   home_mailbox = Maildir/
   mailbox_command =
   ```

---

## Paso 3: Crear Usuarios

Crea los usuarios necesarios (ejemplo: `liz` y `alice`):

```bash
sudo adduser liz
sudo adduser alice
```

---

## Paso 4: Instalar un Cliente de Correo

Instala `bsd-mailx`, un cliente de correo basado en línea de comandos:

```bash
sudo apt install -y bsd-mailx
```

---

## Paso 5: Instalar y Configurar Dovecot

1. Instala Dovecot con soporte POP3:

   ```bash
   sudo apt install -y dovecot-pop3d
   ```

2. Configura la autenticación:

   - Edita el archivo `/etc/dovecot/conf.d/10-auth.conf` y establece:
     ```
     disable_plaintext_auth = no
     ```

3. Configura el almacenamiento de correos:
   - Edita el archivo `/etc/dovecot/conf.d/10-mail.conf`:
     - Comenta:
       ```
       # mail_location = mbox:~/mail:INBOX=/var/mail/%u
       ```
     - Descomenta o añade:
       ```
       mail_location = maildir:~/Maildir
       ```

---

## Paso 6: Reiniciar Servicios

Reinicia los servicios para aplicar los cambios:

```bash
sudo systemctl restart postfix
sudo systemctl restart dovecot
```
