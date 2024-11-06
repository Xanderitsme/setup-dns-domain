# Guía para Configurar un Servidor DNS

## 1. Instalar BIND 9 en el servidor DNS

Para comenzar, instala BIND 9 junto con las utilidades necesarias:

```bash
sudo apt install bind9 bind9utils bind9-doc -y
```

> **Opcional**: Puedes verificar el estado de BIND 9 para asegurarte de que se haya instalado correctamente:

```bash
# sudo systemctl status bind9
```

## 2. Configurar el archivo `named.conf.options`

Edita el archivo `named.conf.options` para ajustar la configuración de BIND. Abre el archivo con el siguiente comando:

```bash
sudo nano /etc/bind/named.conf.options
```

A continuación, pega el siguiente contenido, reemplazando `[default gateway]` con la dirección de tu puerta de enlace predeterminada (por ejemplo, `192.168.1.0/24`, que puedes obtener con el comando `ip r`):

```bash
acl LAN {
    [default gateway];
};

options {
    directory "/var/cache/bind";
    allow-query {
        localhost;
        LAN;
    };
    forwarders {
        8.8.8.8;
        1.1.1.1;
    };
    recursion yes;
};
```

> **Opcional**: Verifica la sintaxis del archivo para asegurarte de que no haya errores:

```bash
# named-checkconf /etc/bind/named.conf.options
```

## 3. Configurar el archivo `named.conf.local`

Edita el archivo `named.conf.local` para añadir las configuraciones de las zonas directa e inversa. Abre el archivo con el siguiente comando:

```bash
sudo nano /etc/bind/named.conf.local
```

Pega el siguiente contenido, reemplazando `[subdomain]` con el subdominio que desees (por ejemplo, `mysite.com`), y `[network]` con la parte de tu red que obtienes de `ip r` (por ejemplo, `192.168.1`):

```bash
zone "[subdomain]" IN {
    // Forward zone file
    type master;
    file "/etc/bind/zones/[subdomain]";
};

zone "[network].in-addr.arpa" IN {
    // Reverse zone file
    type master;
    file "/etc/bind/zones/[subdomain].rev";
};
```

## 4. Crear el directorio para los archivos de zona

Crea el directorio donde se almacenarán los archivos de zona:

```bash
sudo mkdir /etc/bind/zones
```

## 5. Configurar la zona directa (Forward Zone)

Ahora, crea el archivo de zona directa para el dominio. Abre el archivo de zona con el siguiente comando (reemplaza `[subdomain]` por tu subdominio):

```bash
sudo nano /etc/bind/zones/[subdomain]
```

Pega el siguiente contenido, reemplazando `[domain]` por tu dominio, `[subdomain]` por tu subdominio y `[ip]` por la dirección IP de tu servidor (puedes obtenerla con el comando `hostname -I`):

```bash
$TTL    604800
; SOA record with MNAME and RNAME updated
@       IN      SOA     [subdomain]. root.[subdomain]. (
                              3         ; Serial Note: increment after each change
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; Name server record
@       IN      NS      [domain].[subdomain].

; A record for name server
[domain]      IN      A       [ip]

; A record for client
client1      IN      A       [ip]
```

> **Opcional**: Puedes verificar la configuración del archivo de zona con el siguiente comando:

```bash
# named-checkzone [subdomain] /etc/bind/zones/[subdomain]
```

## 6. Configurar la zona inversa (Reverse Zone)

Ahora, configura el archivo de zona inversa para realizar las búsquedas inversas (PTR). Abre el archivo con el siguiente comando:

```bash
sudo nano /etc/bind/zones/[subdomain].rev
```

Pega el siguiente contenido, reemplazando `[domain]` con tu dominio, `[subdomain]` con tu subdominio, y `[ip]` con la dirección IP de tu servidor:

```bash
$TTL    604800
; SOA record with MNAME and RNAME updated
@       IN      SOA     [subdomain]. root.[subdomain]. (
                              2         ; Serial Note: increment after each change
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; Name server record
@       IN      NS      [domain].[subdomain].

; A record for name server
[domain]      IN      A       [ip]

; PTR record for name server
2       IN      PTR     [domain].[subdomain]

; PTR record for client
3       IN      PTR     client1.[subdomain]
```

> **Opcional**: Verifica la configuración de la zona inversa con el siguiente comando:

```bash
# named-checkzone [subdomain] /etc/bind/zones/[subdomain].rev
```

## 7. Reiniciar el servicio BIND 9

Finalmente, reinicia el servicio de BIND 9 para aplicar los cambios de configuración:

```bash
sudo systemctl restart bind9
```

---

¡Y eso es todo! Con estos pasos, habrás configurado correctamente tu servidor DNS.
