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

Pega el siguiente contenido, reemplazando `[domain]` con el dominio que desees (por ejemplo, `mysite.com`), y `[network]` con el segmento de tu red que obtienes de `ip r` (por ejemplo, `192.168.1`):

> [!NOTE]
> `[network]` se refiere a los 3 primeros octetos de la IP que obtienes al ejecutar `ip r`. Es decir, si al ejecutar dicho comando obtienes `192.168.1.0/24`, entonces tu segmento de red (`[network]`) será `192.168.1`.

```bash
zone "[domain]" IN {
    // Forward zone file
    type master;
    file "/etc/bind/zones/[domain]";
};

# Agregar más configuraciones similares en caso de tener varios dominios
# zone "[domain2]" IN {
#     // Forward zone file
#     type master;
#     file "/etc/bind/zones/[domain]";
# };

zone "[network].in-addr.arpa" IN {
    // Reverse zone file
    type master;
    file "/etc/bind/zones/[domain].rev";
};
```

## 4. Crear el directorio para los archivos de zona

Crea el directorio donde se almacenarán los archivos de zona:

```bash
sudo mkdir /etc/bind/zones
```

## 5. Configurar la zona directa (Forward Zone)

Ahora, crea el archivo de zona directa para el dominio. Abre el archivo de zona con el siguiente comando (reemplaza `[domain]` por tu dominio):

```bash
sudo nano /etc/bind/zones/[domain]
```

Pega el siguiente contenido, reemplazando `[subdomain]` por tu subdominio (como `ns1`), `[domain]` por el nombre de tu dominio (por ejemplo, `domain1.com`), y `[ip]` por la dirección IP de tu servidor (puedes obtenerla con el comando `hostname -I`):

```bash
$TTL    604800
@       IN      SOA     [domain]. root.[domain]. (
                          3         ; Serial
                     604800         ; Refresh
                      86400         ; Retry
                    2419200         ; Expire
                     604800 )       ; Negative Cache TTL
@       IN      NS      [subdomain].[domain].
[subdomain]      IN      A       [ip]
```

> **Opcional**: Puedes verificar la configuración del archivo de zona con el siguiente comando:

```bash
# named-checkzone [domain] /etc/bind/zones/[domain]
```

> [!NOTE]
> Repite este paso para cada dominio que desees registrar. Si tienes varios dominios, deberás crear un archivo de zona para cada uno, con un contenido similar.

## 6. Configurar la zona inversa (Reverse Zone)

La zona inversa permite realizar búsquedas de tipo PTR para resolver direcciones IP a nombres de dominio. Para configurarla correctamente, crea el archivo de zona inversa.

### 6.1. Crear el archivo de zona inversa

Abre el archivo de zona inversa con el siguiente comando (reemplaza `[network]` por tu segmento de red, por ejemplo, `192.168.1`):

```bash
sudo nano /etc/bind/zones/[network].rev
```

Pega el siguiente contenido, reemplazando `[network]` con el segmento de red y `[ip]` con la dirección IP de tu servidor:

```bash
$TTL    604800
@       IN      SOA     [ip]. root.[network]. (
                          2         ; Serial
                     604800         ; Refresh
                      86400         ; Retry
                    2419200         ; Expire
                     604800 )       ; Negative Cache TTL
@       IN      NS      www.[network].in-addr.arpa.
```

### 6.2. Agregar los punteros (PTR) para cada dominio

En una zona inversa, los punteros (registros PTR) se utilizan para resolver direcciones IP a nombres de dominio. Estos registros son cruciales para la reversa de resolución de nombres.

Agrega los registros PTR para cada dominio de la siguiente manera:

1. **Extraer el último octeto de la IP del servidor**: Por ejemplo, si tu IP es `192.168.1.10`, el último octeto es `10`.
   
2. **Agregar los registros PTR**: Para cada dominio, debes agregar una entrada PTR que resuelva la IP a su nombre de dominio.

Continuando con el archivo de zona inversa, agrega las siguientes líneas debajo de las configuraciones anteriores, reemplazando `[subdomain]` y `[domain]` por el subdominio y el dominio correspondientes:

```bash
# Puntero PTR para el dominio
[ultima parte de la ip] IN PTR [subdomain].[domain].
```

Por ejemplo, si tienes un dominio `ns1.domain1.com` con la IP `192.168.1.10`, deberías agregar lo siguiente:

```bash
10      IN PTR ns1.domain1.com.
```

> [!NOTE]
> Si tienes múltiples dominios configurados, repite este paso para cada dominio, agregando una entrada PTR correspondiente a la IP de cada uno.

### Ejemplo completo de zona inversa

Si tienes la IP `192.168.1.10` para `ns1.domain1.com` y `192.168.1.20` para `ns2.domain2.com`, la zona inversa quedaría de la siguiente manera:

```bash
$TTL    604800
@       IN      SOA     192.168.1.10. root.192.168.1. (
                          2         ; Serial
                     604800         ; Refresh
                      86400         ; Retry
                    2419200         ; Expire
                     604800 )       ; Negative Cache TTL
@       IN      NS      www.192.168.1.in-addr.arpa.

# Registros PTR
10      IN PTR ns1.domain1.com.
20      IN PTR ns2.domain2.com.
```

## 7. Reiniciar el servicio BIND 9

Finalmente, reinicia el servicio de BIND 9 para aplicar los cambios de configuración:

```bash
sudo systemctl restart bind9
```

---

¡Y eso es todo! Con estos pasos, habrás configurado correctamente tu servidor DNS.
