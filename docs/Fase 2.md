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

### 1.1 Verificar que el servidor DNS está corriendo

```bash
# Conectarse al servidor DNS
gcloud compute ssh dns --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap

# Una vez dentro de la VM:
# Verificar que BIND9 está activo
systemctl status named

# Verificar que está escuchando en el puerto 53
ss -lptn | grep ':53' | grep -v '127.0.0'
# Debería mostrar: 10.0.0.134:53 (o la IP de tu servidor DNS)
```

**Resultado esperado:**
- `named` service debe estar `active (running)`
- Debe estar escuchando en `10.0.0.134:53` (o la IP de tu servidor)

### 1.2 Verificar configuración DNS

```bash
# Desde el servidor DNS
gcloud compute ssh dns --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="cat /etc/bind/named.conf.local"

# Verificar archivos de zona
gcloud compute ssh dns --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="cat /etc/bind/db.x.local"
```

**Resultado esperado:**
- Debe mostrar las zonas `x.local` y `3.0.10.in-addr.arpa`
- Debe mostrar los registros: `dns.x.local`, `rrhh.x.local`, `ldap.x.local`

### 1.3 Probar resolución DNS desde el servidor

```bash
# Probar resolución local
gcloud compute ssh dns --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="nslookup rrhh.x.local 127.0.0.1"

# Probar otros dominios
gcloud compute ssh dns --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="nslookup dns.x.local 127.0.0.1"
gcloud compute ssh dns --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="nslookup ldap.x.local 127.0.0.1"
```

**Resultado esperado:**
```
Name: rrhh.x.local
Address: 10.0.3.20

Name: dns.x.local
Address: 10.0.3.10

Name: ldap.x.local
Address: 10.0.3.30
```

### 1.4 Probar resolución DNS desde otras subredes (Ventas)

```bash
# Instalar herramientas DNS si no están instaladas
gcloud compute ssh test-ventas-vm --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="sudo apt-get update -qq && sudo apt-get install -y dnsutils -qq"

# Probar resolución desde Ventas
DNS_IP=$(terraform output -raw dns_server_ip)
gcloud compute ssh test-ventas-vm --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="nslookup rrhh.x.local $DNS_IP"
```

**Resultado esperado:**
- Debe resolver `rrhh.x.local` a `10.0.3.20`
- Debe usar el servidor DNS correcto

### 1.5 Probar resolución DNS desde TI

```bash
# Instalar herramientas DNS
gcloud compute ssh test-ti-vm --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="sudo apt-get update -qq && sudo apt-get install -y dnsutils -qq"

# Probar resolución desde TI
DNS_IP=$(terraform output -raw dns_server_ip)
gcloud compute ssh test-ti-vm --zone=us-central1-a --project=still-smithy-475313-s3 --tunnel-through-iap --command="nslookup rrhh.x.local $DNS_IP"
```

**Resultado esperado:**
- Debe resolver correctamente los dominios

### 1.6 Verificar reglas de firewall para DNS

```bash
# Verificar regla que permite DNS desde subredes internas
gcloud compute firewall-rules describe allow-dns-internal --project=still-smithy-475313-s3 --format="get(name,sourceRanges.list(),targetTags.list())"

# Verificar regla que bloquea DNS desde Visitas
gcloud compute firewall-rules describe deny-dns-from-visitas --project=still-smithy-475313-s3 --format="get(name,sourceRanges.list(),targetTags.list())"
```

**Resultado esperado:**
- `allow-dns-internal`: debe permitir desde Ventas (10.0.0.64/27), TI (10.0.0.96/27), Data Center (10.0.0.128/28)
- `deny-dns-from-visitas`: debe bloquear desde Visitas (10.0.0.0/26)

### 1.7 Verificar que la VM DNS tiene el tag correcto

```bash
# Verificar tags de la instancia DNS
gcloud compute instances describe dns --zone=us-central1-a --project=still-smithy-475313-s3 --format="value(tags.items)" | tr ';' '\n'
```

**Resultado esperado:**
- Debe incluir el tag `dns-server`

---

## Checklist de Pruebas DNS

- [ ] Servicio BIND9 está corriendo
- [ ] Escucha en puerto 53 (TCP y UDP)
- [ ] Configuración de zonas correcta
- [ ] Resuelve `rrhh.x.local` → `10.0.3.20`
- [ ] Resuelve `dns.x.local` → `10.0.3.10`
- [ ] Resuelve `ldap.x.local` → `10.0.3.30`
- [ ] Resolución funciona desde Ventas
- [ ] Resolución funciona desde TI
- [ ] Reglas de firewall correctas
- [ ] Tag `dns-server` aplicado

---

## Próximas Secciones

- [ ] 2. Pruebas de LDAP
- [ ] 3. Pruebas del Servidor Web Interno (RRHH)
- [ ] 4. Pruebas de Firewall y ACL
- [ ] 5. Pruebas de NAT

