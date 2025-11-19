#!/bin/bash
# Script para medir latencia y métricas de red
# Ejecutar desde el directorio raíz del proyecto: ./scripts/test_latency.sh

set -e

echo "=========================================="
echo "MEDICIÓN DE LATENCIA Y MÉTRICAS DE RED"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuración
ZONE="us-central1-a"

# Obtener IPs
echo "Obteniendo IPs de las instancias..."
DNS_IP=$(terraform output -raw dns_server_ip 2>/dev/null || echo "")
LDAP_IP=$(terraform output -raw ldap_server_ip 2>/dev/null || echo "")
RRHH_IP=$(terraform output -raw rrhh_server_ip 2>/dev/null || echo "")

if [ -z "$DNS_IP" ] || [ -z "$LDAP_IP" ] || [ -z "$RRHH_IP" ]; then
    echo "Error: No se pudieron obtener las IPs. Ejecuta 'terraform output' para verificar."
    exit 1
fi

echo -e "${GREEN}✓ IPs obtenidas:${NC}"
echo "  DNS:  $DNS_IP"
echo "  LDAP: $LDAP_IP"
echo "  RRHH: $RRHH_IP"
echo ""

# Credenciales SNMP
SNMP_USER="snmpuser"
SNMP_AUTH="snmpauth123"
SNMP_PRIV="snmppriv123"

echo "=========================================="
echo "1. MEDICIÓN DE LATENCIA (PING)"
echo "=========================================="
echo ""

# Latencia hacia DNS
echo -e "${YELLOW}[1.1] Latencia hacia DNS ($DNS_IP)...${NC}"
gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="ping -c 5 $DNS_IP" 2>&1 | grep -E "(PING|packets|min/avg/max|rtt)" || echo "Error en ping"
echo ""

# Latencia hacia LDAP
echo -e "${YELLOW}[1.2] Latencia hacia LDAP ($LDAP_IP)...${NC}"
gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="ping -c 5 $LDAP_IP" 2>&1 | grep -E "(PING|packets|min/avg/max|rtt)" || echo "Error en ping"
echo ""

# Latencia hacia RRHH
echo -e "${YELLOW}[1.3] Latencia hacia RRHH ($RRHH_IP)...${NC}"
gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="ping -c 5 $RRHH_IP" 2>&1 | grep -E "(PING|packets|min/avg/max|rtt)" || echo "Error en ping"
echo ""

echo "=========================================="
echo "2. MÉTRICAS DE RED CON SNMP"
echo "=========================================="
echo ""

# Estadísticas de interfaz DNS
echo -e "${YELLOW}[2.1] Estadísticas de interfaz de red - DNS...${NC}"
echo "Interfaces disponibles:"
gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpwalk -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $DNS_IP 1.3.6.1.2.1.2.2.1.2 2>&1" | head -5 || echo "No se pudo obtener"
echo ""

# Bytes recibidos DNS (interfaz eth0, índice 2)
echo -e "${YELLOW}[2.2] Bytes recibidos (ifInOctets) - DNS interfaz eth0...${NC}"
gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $DNS_IP 1.3.6.1.2.1.2.2.1.10.2 2>&1" || echo "Error (puede requerir índice diferente)"
echo ""

# Bytes enviados DNS (interfaz eth0, índice 2)
echo -e "${YELLOW}[2.3] Bytes enviados (ifOutOctets) - DNS interfaz eth0...${NC}"
gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $DNS_IP 1.3.6.1.2.1.2.2.1.16.2 2>&1" || echo "Error (puede requerir índice diferente)"
echo ""

echo "=========================================="
echo "3. RESUMEN"
echo "=========================================="
echo ""
echo "IPs monitoreadas:"
echo "  DNS:  $DNS_IP"
echo "  LDAP: $LDAP_IP"
echo "  RRHH: $RRHH_IP"
echo ""
echo -e "${GREEN}Mediciones completadas. Revisa los resultados arriba para tomar capturas.${NC}"
echo ""

