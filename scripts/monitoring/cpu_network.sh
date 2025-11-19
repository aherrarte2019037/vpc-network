#!/bin/bash
# Script para medir uso de CPU y red con SNMP
# Ejecutar desde el directorio raíz del proyecto: ./scripts/test_cpu_network.sh

set -e

echo "=========================================="
echo "MONITOREO DE CPU Y RED - SNMP"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Función para obtener métricas de CPU
get_cpu_metrics() {
    local IP=$1
    local NAME=$2
    
    echo -e "${BLUE}=== CPU - $NAME ($IP) ===${NC}"
    
    # CPU usado por usuario
    echo -n "CPU Usuario: "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.4.1.2021.11.11.0 2>&1" 2>/dev/null | grep -E 'INTEGER|Gauge32|Counter32' | awk -F': ' '{print $2}' | head -1 | tr -d ' ')
    if [ -n "$RESULT" ] && [ "$RESULT" != "" ]; then
        PERCENT=$(echo "scale=2; $RESULT/100" | bc 2>/dev/null || echo "$RESULT")
        echo "$PERCENT% ($RESULT centésimas)"
    else
        echo "N/A"
    fi
    
    # CPU usado por sistema
    echo -n "CPU Sistema: "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.4.1.2021.11.9.0 2>&1" | grep -E 'INTEGER|Gauge32|Counter32' | awk -F': ' '{print $2}' | head -1)
    if [ -n "$RESULT" ]; then
        PERCENT=$(echo "scale=2; $RESULT/100" | bc 2>/dev/null || echo "$RESULT")
        echo "$PERCENT% ($RESULT centésimas)"
    else
        echo "N/A"
    fi
    
    # CPU idle
    echo -n "CPU Idle: "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.4.1.2021.11.10.0 2>&1" | grep -E 'INTEGER|Gauge32|Counter32' | awk -F': ' '{print $2}' | head -1)
    if [ -n "$RESULT" ]; then
        PERCENT=$(echo "scale=2; $RESULT/100" | bc 2>/dev/null || echo "$RESULT")
        echo "$PERCENT% ($RESULT centésimas)"
    else
        echo "N/A"
    fi
    
    # Carga del sistema (1 minuto)
    echo -n "Carga sistema (1 min): "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.4.1.2021.10.1.3.1 2>&1" | grep -E 'INTEGER|Gauge32|Counter32|STRING' | awk -F': ' '{print $2}' | head -1)
    if [ -n "$RESULT" ]; then
        echo "$RESULT"
    else
        echo "N/A"
    fi
    
    echo ""
}

# Función para obtener métricas de red
get_network_metrics() {
    local IP=$1
    local NAME=$2
    
    echo -e "${BLUE}=== RED - $NAME ($IP) ===${NC}"
    
    # Listar interfaces disponibles
    echo "Interfaces de red disponibles:"
    gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpwalk -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.2.1.2.2.1.2 2>&1" | head -5 || echo "No disponible"
    echo ""
    
    # Intentar obtener métricas de la interfaz principal (índice 2 = eth0)
    echo "Métricas de interfaz eth0 (índice 2):"
    
    # Bytes recibidos
    echo -n "  Bytes recibidos (ifInOctets): "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.2.1.2.2.1.10.2 2>&1" || echo "ERROR")
    if echo "$RESULT" | grep -qE "Counter32|Counter64"; then
        BYTES=$(echo "$RESULT" | grep -E 'Counter32|Counter64' | awk -F': ' '{print $2}' | head -1)
        if [ -n "$BYTES" ]; then
            MB=$(echo "scale=2; $BYTES/1024/1024" | bc 2>/dev/null || echo "N/A")
            echo "$MB MB ($BYTES bytes)"
        else
            echo "N/A"
        fi
    else
        echo "N/A (puede requerir índice diferente)"
    fi
    
    # Bytes enviados
    echo -n "  Bytes enviados (ifOutOctets): "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.2.1.2.2.1.16.2 2>&1" || echo "ERROR")
    if echo "$RESULT" | grep -qE "Counter32|Counter64"; then
        BYTES=$(echo "$RESULT" | grep -E 'Counter32|Counter64' | awk -F': ' '{print $2}' | head -1)
        if [ -n "$BYTES" ]; then
            MB=$(echo "scale=2; $BYTES/1024/1024" | bc 2>/dev/null || echo "N/A")
            echo "$MB MB ($BYTES bytes)"
        else
            echo "N/A"
        fi
    else
        echo "N/A (puede requerir índice diferente)"
    fi
    
    # Errores de entrada
    echo -n "  Errores de entrada (ifInErrors): "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.2.1.2.2.1.14.2 2>&1" | grep -E 'INTEGER|Counter32' | awk -F': ' '{print $2}' | head -1)
    if [ -n "$RESULT" ]; then
        echo "$RESULT"
    else
        echo "N/A"
    fi
    
    # Errores de salida
    echo -n "  Errores de salida (ifOutErrors): "
    RESULT=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $IP 1.3.6.1.2.1.2.2.1.20.2 2>&1" | grep -E 'INTEGER|Counter32' | awk -F': ' '{print $2}' | head -1)
    if [ -n "$RESULT" ]; then
        echo "$RESULT"
    else
        echo "N/A"
    fi
    
    echo ""
}

echo "=========================================="
echo "1. MÉTRICAS DE CPU"
echo "=========================================="
echo ""

get_cpu_metrics "$DNS_IP" "DNS"
get_cpu_metrics "$LDAP_IP" "LDAP"
get_cpu_metrics "$RRHH_IP" "RRHH"

echo "=========================================="
echo "2. MÉTRICAS DE RED"
echo "=========================================="
echo ""

get_network_metrics "$DNS_IP" "DNS"
get_network_metrics "$LDAP_IP" "LDAP"
get_network_metrics "$RRHH_IP" "RRHH"

echo "=========================================="
echo "3. RESUMEN"
echo "=========================================="
echo ""
echo "IPs monitoreadas:"
echo "  DNS:  $DNS_IP"
echo "  LDAP: $LDAP_IP"
echo "  RRHH: $RRHH_IP"
echo ""
echo -e "${GREEN}Monitoreo completado. Revisa los resultados arriba para tomar capturas.${NC}"
echo ""

