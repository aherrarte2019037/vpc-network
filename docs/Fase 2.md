# Guía de Pruebas - Fase 2

Este documento contiene las instrucciones y comandos para probar cada componente implementado en la Fase 2 del proyecto.

## Prerequisitos

1. **Autenticación en GCP:**
   ```bash
   gcloud auth application-default login
   gcloud config set project still-smithy-475313-s3
   ```

2. **Obtener IPs de las instancias:**
   ```bash
   # Obtener IP del servidor DNS
   DNS_IP=$(terraform output -raw dns_server_ip)
   echo "DNS Server IP: $DNS_IP"
   
   # Obtener IP del servidor LDAP
   LDAP_IP=$(terraform output -raw ldap_server_ip)
   echo "LDAP Server IP: $LDAP_IP"
   
   # Obtener IP del servidor web RRHH
   RRHH_IP=$(terraform output -raw rrhh_server_ip)
   echo "RRHH Server IP: $RRHH_IP"
   
   # Obtener IPs de VMs de prueba
   VENTAS_IP=$(terraform output -raw ventas_vm_internal_ip)
   TI_IP=$(terraform output -raw ti_vm_internal_ip)
   echo "Ventas VM IP: $VENTAS_IP"
   echo "TI VM IP: $TI_IP"
   ```

---

## 1. Pruebas de DNS

### 1.1 Verificar servicio DNS

```bash
# Verificar que BIND9 está corriendo
gcloud compute ssh dns --zone=us-central1-a --tunnel-through-iap --command="systemctl status named | head -5"
```

### 1.2 Probar resolución DNS

```bash
# Obtener IP del servidor DNS
DNS_IP=$(terraform output -raw dns_server_ip)

# Probar resolución desde el servidor DNS
gcloud compute ssh dns --zone=us-central1-a --tunnel-through-iap --command="nslookup rrhh.x.local 127.0.0.1"

# Probar resolución desde Ventas (instalar dnsutils si es necesario)
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="sudo apt-get install -y dnsutils -qq 2>/dev/null; nslookup rrhh.x.local $DNS_IP"
```

**Resultado esperado:** `rrhh.x.local` → `10.0.0.133`

### 1.3 Verificar firewall

```bash
# Verificar reglas de firewall
gcloud compute firewall-rules list --filter="name~dns" --format="table(name,sourceRanges.list(),targetTags.list())"
```

**Resultado esperado:** 
- `allow-dns-internal` permite desde Ventas, TI, Data Center
- `deny-dns-from-visitas` bloquea desde Visitas

---

## 2. Pruebas de LDAP

### 2.1 Verificar servicio LDAP

```bash
# Verificar que slapd está corriendo
gcloud compute ssh ldap-server --zone=us-central1-a --tunnel-through-iap --command="systemctl status slapd | head -5"

# Verificar que escucha en puerto 389
gcloud compute ssh ldap-server --zone=us-central1-a --tunnel-through-iap --command="ss -lptn | grep ':389'"
```

### 2.2 Verificar estructura LDAP

```bash
# Obtener IP del servidor LDAP
LDAP_IP=$(terraform output -raw ldap_server_ip)

# Verificar namingContext
gcloud compute ssh ldap-server --zone=us-central1-a --tunnel-through-iap --command="ldapsearch -x -s base -b '' namingContexts"

# Verificar OUs y grupos
gcloud compute ssh ldap-server --zone=us-central1-a --tunnel-through-iap --command="ldapsearch -x -b 'dc=x,dc=local' '(objectclass=organizationalUnit)' dn"

# Verificar usuarios
gcloud compute ssh ldap-server --zone=us-central1-a --tunnel-through-iap --command="ldapsearch -x -b 'dc=x,dc=local' '(uid=*)' dn uidNumber gidNumber"
```

**Resultado esperado:**
- namingContext: `dc=x,dc=local`
- OUs: `ou=rrhh`, `ou=ventas`
- Grupos: `cn=rrhh`, `cn=ventas`, `cn=ti-admins`
- Usuarios: `user1`, `user2`, `user3`, `user4`

### 2.3 Verificar firewall

```bash
# Verificar reglas de firewall para LDAP
gcloud compute firewall-rules list --filter="name~ldap" --format="table(name,sourceRanges.list(),targetTags.list())"
```

**Resultado esperado:**
- `allow-ldap-internal` permite desde Ventas, TI, Data Center
- `deny-ldap-from-visitas` bloquea desde Visitas

### 2.4 Probar autenticación con usuarios LDAP

```bash
# Obtener IP del servidor LDAP
LDAP_IP=$(terraform output -raw ldap_server_ip)

# Verificar que el cliente puede conectarse al servidor LDAP
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="ldapsearch -x -H ldap://$LDAP_IP -b 'dc=x,dc=local' '(uid=user1)' dn"

# Verificar autenticación de usuario (si SSSD está configurado)
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="getent passwd user1 || id user1 2>&1 || echo 'SSSD no configurado aún'"
```

**Resultado esperado:**
- Conexión LDAP exitosa desde el cliente
- Si SSSD está configurado: debe resolver `user1` con uidNumber y gidNumber

## 3. Pruebas del Servidor Web Interno (RRHH)

### 3.1 Verificar servicio web

```bash
# Verificar que Apache está corriendo
gcloud compute ssh rrhh-server --zone=us-central1-a --tunnel-through-iap --command="systemctl status apache2 | head -5"

# Verificar que escucha en puerto 80
gcloud compute ssh rrhh-server --zone=us-central1-a --tunnel-through-iap --command="ss -lptn | grep ':80'"
```

### 3.2 Probar acceso por nombre de dominio

```bash
# Obtener IP del servidor DNS
DNS_IP=$(terraform output -raw dns_server_ip)

# Obtener IP del servidor RRHH
RRHH_IP=$(terraform output -raw rrhh_server_ip)

# Verificar resolución DNS
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="sudo apt-get install -y dnsutils curl -qq 2>/dev/null; nslookup rrhh.x.local $DNS_IP"

# Probar acceso HTTP por nombre de dominio desde Ventas
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="curl -s http://rrhh.x.local | head -10"
```

**Resultado esperado:**
- Resolución DNS: `rrhh.x.local` → `10.0.0.133`
- Acceso HTTP exitoso con contenido HTML del servidor RRHH

### 3.3 Verificar firewall

```bash
# Verificar reglas de firewall para el servidor web
gcloud compute firewall-rules list --filter="name~web" --format="table(name,sourceRanges.list(),targetTags.list())"
```

**Resultado esperado:**
- `allow-web-internal` permite desde Ventas, TI, Data Center
- `deny-web-from-visitas` bloquea desde Visitas
- `deny-web-from-internet` bloquea desde Internet

## 4. Pruebas de Firewall y ACL

### 4.1 Verificar reglas de firewall

```bash
# Listar todas las reglas de firewall
gcloud compute firewall-rules list --filter="network:vpc-network" --format="table(name,priority,sourceRanges.list(),targetTags.list(),direction)"

# Verificar reglas específicas
gcloud compute firewall-rules list --filter="name~visitas OR name~ti" --format="table(name,priority,sourceRanges.list(),destinationRanges.list())"
```

**Resultado esperado:**
- `deny-visitas-to-internal`: bloquea Visitas → subredes internas (prioridad 1000)
- `allow-ti-to-all-subnets`: permite TI → todas las subredes (prioridad 500)
- `deny-others-to-ti`: bloquea otras subredes → TI (prioridad 1000)

### 4.2 Probar aislamiento de Visitas

```bash
# Verificar que Visitas está bloqueada de acceder a subredes internas
gcloud compute firewall-rules describe deny-visitas-to-internal --format="value(sourceRanges,destinationRanges)"
```

**Resultado esperado:**
- Source: `10.0.0.0/26` (Visitas)
- Destination: `10.0.0.64/27`, `10.0.0.96/27`, `10.0.0.128/28` (Ventas, TI, Data Center)

### 4.3 Probar acceso de TI a todas las subredes

```bash
# Obtener IPs
VENTAS_IP=$(terraform output -raw ventas_vm_internal_ip)
RRHH_IP=$(terraform output -raw rrhh_server_ip)
DNS_IP=$(terraform output -raw dns_server_ip)

# Probar ping desde TI a Ventas (debe funcionar)
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="ping -c 2 $VENTAS_IP"

# Probar ping desde TI a Data Center (debe funcionar)
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="ping -c 2 $RRHH_IP"
```

**Resultado esperado:**
- TI puede hacer ping a Ventas y Data Center

### 4.4 Probar bloqueo de acceso a TI desde otras subredes

```bash
# Obtener IP de TI
TI_IP=$(terraform output -raw ti_vm_internal_ip)

# Intentar ping desde Ventas a TI (debe fallar)
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="ping -c 2 -W 2 $TI_IP || echo 'Bloqueado correctamente'"
```

**Resultado esperado:**
- Ventas NO puede hacer ping a TI (100% packet loss - bloqueado correctamente)

### 4.5 Verificar reglas de servicios específicos

```bash
# Verificar reglas de servicios (DNS, LDAP, Web)
gcloud compute firewall-rules list --filter="name~dns OR name~ldap OR name~web" --format="table(name,sourceRanges.list(),targetTags.list(),priority)"
```

**Resultado esperado:**
- Servicios permiten acceso desde Ventas, TI, Data Center (prioridad 500)
- Servicios bloquean acceso desde Visitas (prioridad 1000)

## 5. Pruebas de NAT

### 5.1 Verificar configuración de NAT

```bash
# Verificar que Cloud NAT está configurado
gcloud compute routers nats describe main-nat --router=main-router --region=us-central1 --format="yaml"

# Verificar IPs NAT asignadas
gcloud compute routers nats describe main-nat --router=main-router --region=us-central1 --format="value(natIps)"
```

**Resultado esperado:**
- NAT configurado para todas las subredes (`ALL_SUBNETWORKS_ALL_IP_RANGES`)
- Al menos una IP NAT asignada automáticamente

### 5.2 Verificar que las instancias no tienen IP externa

```bash
# Verificar que las instancias no tienen IP externa (usan NAT)
gcloud compute instances list --filter="networkInterfaces.network:$(terraform output -raw vpc_name)" --format="table(name,zone,networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP)"
```

**Resultado esperado:**
- Las instancias tienen IP interna pero NO tienen IP externa (natIP vacío)
- Todas las instancias usan NAT para salida a Internet

### 5.3 Probar acceso a Internet desde Ventas

```bash
# Probar resolución DNS externa desde Ventas
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="nslookup google.com 8.8.8.8"

# Probar acceso HTTP a Internet desde Ventas
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="curl -s -o /dev/null -w '%{http_code}' http://www.google.com --max-time 5"
```

**Resultado esperado:**
- Resolución DNS externa exitosa
- Acceso HTTP a Internet exitoso (código 200 o 301/302)

### 5.4 Probar acceso a Internet desde TI

```bash
# Probar acceso HTTP a Internet desde TI
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="curl -s -o /dev/null -w '%{http_code}' http://www.google.com --max-time 5"

# Verificar IP pública saliente (debe ser la IP del NAT)
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="curl -s ifconfig.me"
```

**Resultado esperado:**
- Acceso HTTP exitoso
- IP pública saliente corresponde a una IP NAT asignada

### 5.5 Probar acceso a Internet desde Data Center

```bash
# Probar acceso HTTP desde servidor DNS (Data Center)
gcloud compute ssh dns --zone=us-central1-a --tunnel-through-iap --command="curl -s -o /dev/null -w '%{http_code}' http://www.google.com --max-time 5"

# Verificar que puede actualizar paquetes (requiere NAT)
gcloud compute ssh dns --zone=us-central1-a --tunnel-through-iap --command="sudo apt-get update -qq 2>&1 | head -3"
```

**Resultado esperado:**
- Acceso HTTP exitoso desde Data Center
- Actualización de paquetes exitosa (requiere NAT para descargar paquetes)

### 5.6 Verificar logs de NAT

```bash
# Verificar que los logs de NAT están habilitados
gcloud compute routers nats describe main-nat --router=main-router --region=us-central1 --format="value(logConfig)"
```

**Resultado esperado:**
- Logs de NAT habilitados (`enable: true`)

