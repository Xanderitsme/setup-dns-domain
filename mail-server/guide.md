# Guía para Configurar un Servidor de Correos

## 1. Comprobar hostname y actualizarlo en caso de ser necesario

```bash
sudo hostname
```

Reemplazar `[domain]` por el nombre de tu dominio
```bash
sudo hostnamectl set-hostname [domain]
```

## 2. Instalar postfix

```bash
sudo apt isntall postfix
```

Realizar la configuración inicial
- Sitio de internet
- [dominio]

> **Opcional**: Puedes verificar que el dominio sea el correcto con este comando

```bash
# cat /etc/mailname
```

> **Opcional**: Si deseas cambiar el dominio puedes hacerlo con este comando
```bash
# sudo nano /etc/mailname
# sudo systemctl restart postfix
```

## 3. Agregar usuarios

Agregar al menos 2 usuarios:
- liz
- alice

Puedes agregar usuarios con el siguiente comando, solo reemplaza [username] con el nombre del usuario

```bash
sudo adduser [username]
```

## 4. Instalar mailx

bsd-mailx es un cliente de correo electrónico a través de la línea de comandos

```bash
sudo apt install bsd-mailx
```

## 5. Instalar dovecot pop3d

Ejecuta el siguiente comando

```bash
sudo apt install dovecot-pop3d
```

## 6. Configurar servidor pop en la red local

```bash
sudo nano /etc/postfix/main.cf
```

realizar los siguientes cambios: (reemplaza `[network]` con la ip de la red local, puedes utilizar el comando `ip r`)

```bash
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 [network]
home_mailbox = Maildir/
mailbox_command =
```

## 7. Configurar la autenticación de dovecot

Abrir el siguiente archivo

```bash
sudo nano /etc/dovecot/conf.d/10-auth.conf
```

reemplazar la siguiente linea:
```bash
disable_plaintext_auth = no
```

cerrar el archivo


Abrir el siguiente archivo

```bash
sudo nano /etc/dovecot/conf.d/10-mail.conf
```

Comentar esta linea:
```bash
# mail_location = mbox:~/mail:INBOX=/var/mail/%u
```

Descomentar esta linea:
```bash
mail_location = maildir:~/Maildir
```

## 7. Reiniciar postfix

Reinicia el servicio de postfix para aplicar los cambios de configuración:

```bash
sudo systemctl restart postfix
```

## 7. Reiniciar dovecot

Reinicia el servicio de dovecot para aplicar los cambios de configuración:

```bash
sudo systemctl restart dovecot
```

