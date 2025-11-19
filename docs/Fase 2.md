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

**Resultado esperado:** `rrhh.x.local` → `10.0.3.20`

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
*(Por agregar)*

## 3. Pruebas del Servidor Web Interno (RRHH)
*(Por agregar)*

## 4. Pruebas de Firewall y ACL
*(Por agregar)*

## 5. Pruebas de NAT
*(Por agregar)*

