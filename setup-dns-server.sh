#!/bin/bash

# Función para comprobar si un paquete está instalado
is_package_installed() {
    dpkg -l | grep -q "^ii  $1 "  # Busca el paquete en la lista de paquetes instalados
}

# Cargar el archivo de configuración
source ./dns_config

# Función para obtener la IP y red actuales
get_current_ip() {
    hostname -I | awk '{print $1}'
}

# Obtener IP y red actuales
SERVER_IP=$(get_current_ip)

# Paso 1: Verificar e instalar los paquetes que faltan
# Comprobar si los paquetes necesarios están instalados
echo "Verificando si los paquetes necesarios están instalados..."

# Lista de paquetes necesarios
PACKAGES=("bind9" "bind9utils" "bind9-doc")

for PACKAGE in "${PACKAGES[@]}"; do
    if ! is_package_installed "$PACKAGE"; then
        echo "$PACKAGE no está instalado. Instalando..."
        apt install -y "$PACKAGE"
    else
        echo "$PACKAGE ya está instalado."
    fi
done

# Paso 2: Configurar named.conf.options
echo "Configurando named.conf.options..."
cat <<EOL > /etc/bind/named.conf.options
acl LAN {
    $GATEWAY;
};
options {
    directory "/var/cache/bind";
    allow-query {
        localhost;
        LAN;
    };
    forwarders{
        8.8.8.8;
        1.1.1.1;
    };
    recursion yes;
};
EOL

# Paso 3: Vaciar y configurar named.conf.local
echo "Configurando named.conf.local..."
> /etc/bind/named.conf.local  # Vaciar el archivo antes de agregar nuevo contenido

# Bandera para comprobar si la zona inversa ya fue añadida
ZONE_INVERTIDA_AGREGADA=false

# Añadir zonas directas para cada dominio
for DOMAIN in "${DOMAINS[@]}"; do
    # Agregar la zona directa para cada dominio
    cat <<EOL >> /etc/bind/named.conf.local
zone "$DOMAIN" IN {
    type master;
    file "/etc/bind/zones/$DOMAIN";
};
EOL

    # Comprobar si la zona inversa ya ha sido agregada
    if [ "$ZONE_INVERTIDA_AGREGADA" = false ]; then
        # Agregar la zona inversa solo una vez (para la red)
        cat <<EOL >> /etc/bind/named.conf.local
zone "${NETWORK}.in-addr.arpa" IN {
    type master;
    file "/etc/bind/zones/$NETWORK.rev";
};
EOL
        ZONE_INVERTIDA_AGREGADA=true  # Marcar que la zona inversa ya fue agregada
    fi
done

# Paso 4: Crear directorio para archivos de zona
echo "Creando directorio para archivos de zona..."
mkdir -p /etc/bind/zones

# Paso 5: Crear archivos de zona directa para cada dominio
for DOMAIN in "${DOMAINS[@]}"; do
    echo "Creando archivo de zona directa para $DOMAIN..."
    > /etc/bind/zones/$DOMAIN  # Vaciar el archivo de zona antes de agregar nuevo contenido
    cat <<EOL > /etc/bind/zones/$DOMAIN
\$TTL    604800
@       IN      SOA     $DOMAIN. root.$DOMAIN. (
                          3         ; Serial
                     604800         ; Refresh
                      86400         ; Retry
                    2419200         ; Expire
                     604800 )       ; Negative Cache TTL
@       IN      NS      $SUBDOMAIN.$DOMAIN.
$SUBDOMAIN      IN      A       $SERVER_IP
EOL
done

# Paso 6: Crear archivo de zona inversa
echo "Creando archivo de zona inversa..."
> /etc/bind/zones/$NETWORK.rev  # Vaciar el archivo de zona inversa antes de agregar nuevas entradas

# Agregar la parte inicial del archivo de zona inversa (SOA y NS)
cat <<EOL > /etc/bind/zones/$NETWORK.rev
\$TTL    604800
@       IN      SOA     $SERVER_IP. root.$NETWORK. (
                          2         ; Serial
                     604800         ; Refresh
                      86400         ; Retry
                    2419200         ; Expire
                     604800 )       ; Negative Cache TTL
@       IN      NS      www.$NETWORK.in-addr.arpa.
EOL

# Agregar las entradas PTR al archivo de zona inversa
for DOMAIN in "${DOMAINS[@]}"; do
    # Extraer el último octeto de la IP para usar en la zona inversa
    IP_LAST_OCTET=$(echo $SERVER_IP | cut -d '.' -f4)

    # Agregar la entrada PTR para la IP y dominio
    echo "$IP_LAST_OCTET      IN      PTR     $DOMAIN." >> /etc/bind/zones/$NETWORK.rev
done

# Paso 7: Reiniciar BIND 9
echo "Reiniciando BIND 9..."
systemctl restart bind9

echo "Configuración completada."
