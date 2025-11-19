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
*(Por agregar)*

## 4. Pruebas de Firewall y ACL
*(Por agregar)*

## 5. Pruebas de NAT
*(Por agregar)*

