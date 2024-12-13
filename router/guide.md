# Guía para Configurar un Router en Ubuntu

Sigue estos pasos para configurar un equipo Ubuntu como un router.

---

## 1. Configurar Netplan

1. Navega al directorio de configuración de Netplan:

   ```bash
   cd /etc/netplan
   ```

2. Identifica el archivo de configuración `.yaml`. Normalmente, tiene un nombre como `00-installer-config.yaml`. Ábrelo con:

   ```bash
   sudo nano 00-installer-config.yaml
   ```

3. Edita el archivo para reflejar la siguiente configuración, reemplazando los valores entre corchetes:

   ```yaml
   network:
     version: 2
     ethernets:
       [wan-interface]:
         dhcp4: true
       [lan-interface]:
         addresses: [[lan-network]]
         nameservers:
           addresses: [[dns-server1], [dns-server2]]
     renderer: networkd
   ```

   - `[wan-interface]`: Interfaz conectada a la red WAN (ej. `enp0s3`).
   - `[lan-interface]`: Interfaz conectada a la red LAN (ej. `enp0s8`).
   - `[lan-network]`: Segmento de red LAN (ej. `192.168.10.1/24`).
   - `[dns-server#]`: Direcciones de los servidores DNS (ej. `8.8.8.8`).

   > **Nota**: Asegúrate de que la red LAN sea diferente de la WAN.

4. Aplica los cambios:
   ```bash
   sudo netplan apply
   ```

---

## 2. Habilitar el Reenvío de Paquetes

1. Edita el archivo `sysctl.conf`:

   ```bash
   sudo nano /etc/sysctl.conf
   ```

2. Busca y descomenta la línea:

   ```bash
   net.ipv4.ip_forward=1
   ```

3. Guarda y cierra el archivo.

---

## 3. Configurar Reglas de iptables

1. Verifica que la política `FORWARD` esté configurada como `ACCEPT`:

   ```bash
   sudo iptables -L
   ```

   Si no lo está, configúralo con:

   ```bash
   sudo iptables -P FORWARD ACCEPT
   ```

2. Configura una regla de `POSTROUTING` para NAT (reemplaza `[wan-interface]`):

   ```bash
   sudo iptables -t nat -A POSTROUTING -o [wan-interface] -j MASQUERADE
   ```

3. Opcionalmente, verifica la tabla NAT:

   ```bash
   sudo iptables -L -nv -t nat
   ```

4. Para eliminar temporalmente la regla:
   ```bash
   sudo iptables -t nat -F
   ```
   Y vuelve a agregarla si es necesario:
   ```bash
   sudo iptables -t nat -A POSTROUTING -o [wan-interface] -j MASQUERADE
   ```

---

## 4. Persistir la Configuración de iptables

1. Instala el paquete necesario:

   ```bash
   sudo apt install iptables-persistent -y
   ```

2. Guarda la configuración de iptables:
   ```bash
   sudo netfilter-persistent save
   ```

---

Con esto, los equipos conectados a la red LAN deberían tener acceso a la red WAN. ¡Tu router en Ubuntu está configurado correctamente!
