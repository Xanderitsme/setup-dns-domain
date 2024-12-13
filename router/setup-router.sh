#!/bin/bash

# Comprobar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root."
  exit 1
fi

# Verificar argumento de archivo de configuración de Netplan
if [ -z "$1" ]; then
  echo "Uso: $0 <ruta_al_archivo_netplan>"
  exit 1
fi

NETPLAN_FILE="$1"

# Verificar si existe el archivo de configuración externo
CONFIG_FILE="router.conf"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Archivo de configuración '$CONFIG_FILE' no encontrado."
  exit 1
fi

# Cargar variables desde el archivo de configuración
source "$CONFIG_FILE"

# Configurar Netplan
echo "Configurando Netplan..."
cat <<EOF > $NETPLAN_FILE
network:
  version: 2
  ethernets:
    $WAN_INTERFACE:
      dhcp4: true
    $LAN_INTERFACE:
      addresses: [$LAN_NETWORK]
      nameservers:
        addresses: [$DNS_SERVERS]
  renderer: networkd
EOF

# Aplicar configuración de Netplan
echo "Aplicando configuración de Netplan..."
sudo netplan apply

# Habilitar el reenvío de paquetes
echo "Habilitando el reenvío de paquetes..."
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p

# Configurar reglas de iptables
echo "Configurando reglas de iptables..."
iptables -P FORWARD ACCEPT
iptables -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE

# Instalar iptables-persistent para guardar configuración
echo "Instalando iptables-persistent..."
apt update && apt install -y iptables-persistent

# Guardar reglas de iptables
netfilter-persistent save

# Finalización
echo "Configuración completada. El equipo ahora funciona como un router."