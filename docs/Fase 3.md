# Guía de Pruebas - Fase 3

Este documento contiene las instrucciones y comandos para probar cada componente implementado en la Fase 3 del proyecto.

## Prerequisitos

1. **Autenticación en GCP:**
   ```bash
   gcloud auth application-default login
   gcloud config set project still-smithy-475313-s3
   ```

2. **Obtener IPs de las instancias:**
   ```bash
   DNS_IP=$(terraform output -raw dns_server_ip)
   LDAP_IP=$(terraform output -raw ldap_server_ip)
   RRHH_IP=$(terraform output -raw rrhh_server_ip)
   ```

---

## 1. Pruebas de SNMP

### 1.1 Verificar servicio SNMP

```bash
# Verificar que snmpd está corriendo
gcloud compute ssh dns --zone=us-central1-a --tunnel-through-iap --command="sudo systemctl status snmpd --no-pager | head -3"
```

**Resultado esperado:** `snmpd.service` activo y corriendo

### 1.2 Probar consultas SNMP desde TI

```bash
# Obtener IPs
DNS_IP=$(terraform output -raw dns_server_ip)
LDAP_IP=$(terraform output -raw ldap_server_ip)
RRHH_IP=$(terraform output -raw rrhh_server_ip)

# Consultar DNS
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="snmpget -v3 -u snmpuser -l authPriv -a SHA -A snmpauth123 -x AES -X snmppriv123 $DNS_IP 1.3.6.1.2.1.1.5.0"

# Consultar LDAP
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="snmpget -v3 -u snmpuser -l authPriv -a SHA -A snmpauth123 -x AES -X snmppriv123 $LDAP_IP 1.3.6.1.2.1.1.5.0"

# Consultar RRHH
gcloud compute ssh test-ti-vm --zone=us-central1-a --tunnel-through-iap --command="snmpget -v3 -u snmpuser -l authNoPriv -a SHA -A snmpauth123 $RRHH_IP 1.3.6.1.2.1.1.5.0"
```

**Resultado esperado:**
- DNS: `STRING: "dns.x.local"`
- LDAP: `STRING: "ldap.x.local"`
- RRHH: `STRING: "rrhh.x.local"`

### 1.3 Verificar bloqueo desde otras subredes

```bash
# Intentar consulta SNMP desde Ventas (debe fallar)
DNS_IP=$(terraform output -raw dns_server_ip)
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap --command="sudo apt-get install -y snmp -qq 2>/dev/null; timeout 3 snmpget -v3 -u snmpuser -l authPriv -a SHA -A snmpauth123 -x AES -X snmppriv123 $DNS_IP 1.3.6.1.2.1.1.5.0 2>&1 | head -1"
```

**Resultado esperado:** Timeout o error (bloqueado correctamente por firewall)

