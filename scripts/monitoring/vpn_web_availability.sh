#!/bin/bash
# Script para monitorear disponibilidad de servicios críticos (Web y VPN)
# Ejecutar desde el directorio raíz del proyecto: ./scripts/monitoring/vpn_web_availability.sh

set -e

echo "=========================================="
echo "MONITOREO DE DISPONIBILIDAD - SERVICIOS CRÍTICOS"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
ZONE="us-central1-a"

# Obtener IP del servidor web
echo "Obteniendo IP del servidor web..."
WEB_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format="get(networkInterfaces[0].networkIP)" 2>/dev/null || echo "")
WEB_EXT_IP=$(gcloud compute instances describe web-server --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null || echo "")

if [ -z "$WEB_IP" ]; then
    echo -e "${RED}Error: No se pudo obtener la IP del servidor web.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ IPs obtenidas:${NC}"
echo "  IP Interna:  $WEB_IP"
if [ -n "$WEB_EXT_IP" ]; then
    echo "  IP Externa:  $WEB_EXT_IP"
else
    echo "  IP Externa:  No asignada"
fi
echo ""

echo "=========================================="
echo "1. ESTADO DEL SERVICIO NGINX"
echo "=========================================="
echo ""

# Verificar estado de NGINX
echo -e "${YELLOW}[1.1] Estado del servicio NGINX...${NC}"
NGINX_STATUS=$(gcloud compute ssh web-server --zone=$ZONE --tunnel-through-iap --command="sudo systemctl is-active nginx" 2>/dev/null | tail -1 || echo "unknown")
if [ "$NGINX_STATUS" = "active" ]; then
    echo -e "${GREEN}✓ NGINX está activo${NC}"
    gcloud compute ssh web-server --zone=$ZONE --tunnel-through-iap --command="sudo systemctl status nginx --no-pager | head -10" 2>/dev/null | grep -v "WARNING:" | grep -v "setlocale" || true
else
    echo -e "${RED}✗ NGINX no está activo (estado: $NGINX_STATUS)${NC}"
fi
echo ""

# Verificar que NGINX escucha en puertos
echo -e "${YELLOW}[1.2] Puertos en los que escucha NGINX...${NC}"
gcloud compute ssh web-server --zone=$ZONE --tunnel-through-iap --command="sudo ss -lptn | grep nginx || sudo netstat -tlnp | grep nginx" 2>/dev/null | grep -v "WARNING:" | grep -v "setlocale" || echo "No se pudo obtener información de puertos"
echo ""

echo "=========================================="
echo "2. PRUEBAS DE CONECTIVIDAD"
echo "=========================================="
echo ""

# Latencia hacia el servidor web
echo -e "${YELLOW}[2.1] Latencia hacia servidor web (IP interna: $WEB_IP)...${NC}"
TI_IP=$(terraform output -raw ti_vm_internal_ip 2>/dev/null || echo "")
if [ -n "$TI_IP" ]; then
    gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="ping -c 5 $WEB_IP 2>&1" | grep -E "(PING|packets|min/avg/max|rtt)" || echo "Error en ping"
else
    echo "No se pudo obtener IP de TI para prueba de latencia"
fi
echo ""

# Prueba HTTP desde TI (puerto 80)
echo -e "${YELLOW}[2.2] Prueba HTTP (puerto 80) desde TI...${NC}"
HTTP_TEST=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 http://$WEB_IP 2>&1" 2>/dev/null | tail -1 || echo "ERROR")
if [ "$HTTP_TEST" = "200" ]; then
    echo -e "${GREEN}✓ HTTP responde correctamente (Código: $HTTP_TEST)${NC}"
    # Obtener título de la página
    PAGE_TITLE=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="curl -s --connect-timeout 5 http://$WEB_IP 2>&1 | grep -o '<title>.*</title>' || echo 'No title'" 2>/dev/null | tail -1)
    echo "  Título de la página: $PAGE_TITLE"
else
    echo -e "${RED}✗ HTTP no responde correctamente (Código: $HTTP_TEST)${NC}"
fi
echo ""

# Prueba HTTPS desde TI (puerto 443) - si está configurado
echo -e "${YELLOW}[2.3] Prueba HTTPS (puerto 443) desde TI...${NC}"
HTTPS_TEST=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 -k https://$WEB_IP 2>&1" 2>/dev/null | tail -1 || echo "ERROR")
if [ "$HTTPS_TEST" = "200" ] || [ "$HTTPS_TEST" = "301" ] || [ "$HTTPS_TEST" = "302" ]; then
    echo -e "${GREEN}✓ HTTPS responde correctamente (Código: $HTTPS_TEST)${NC}"
else
    echo -e "${YELLOW}⚠ HTTPS no está configurado o no responde (Código: $HTTPS_TEST)${NC}"
    echo "  Nota: Esto es normal si HTTPS aún no está configurado con Certbot"
fi
echo ""

# Verificar acceso desde Internet (si hay IP externa)
if [ -n "$WEB_EXT_IP" ]; then
    echo -e "${YELLOW}[2.4] Verificación de IP externa...${NC}"
    echo "  IP Externa: $WEB_EXT_IP"
    echo "  Nota: Para probar desde Internet, usar: curl http://$WEB_EXT_IP"
    echo ""
fi

echo "=========================================="
echo "3. MÉTRICAS DE RENDIMIENTO"
echo "=========================================="
echo ""

# Uptime del servidor
echo -e "${YELLOW}[3.1] Uptime del servidor web...${NC}"
UPTIME=$(gcloud compute ssh web-server --zone=$ZONE --tunnel-through-iap --command="uptime" 2>/dev/null | tail -1 || echo "N/A")
echo "$UPTIME"
echo ""

# Uso de CPU (si SNMP está disponible)
echo -e "${YELLOW}[3.2] Uso de CPU (vía SNMP si está disponible)...${NC}"
SNMP_USER="snmpuser"
SNMP_AUTH="snmpauth123"
SNMP_PRIV="snmppriv123"

CPU_USER=$(gcloud compute ssh test-ti-vm --zone=$ZONE --tunnel-through-iap --command="snmpget -v3 -u $SNMP_USER -l authPriv -a SHA -A $SNMP_AUTH -x AES -X $SNMP_PRIV $WEB_IP 1.3.6.1.4.1.2021.11.11.0 2>&1" 2>/dev/null | grep -E 'INTEGER|Gauge32' | awk -F': ' '{print $2}' | head -1 | tr -d ' ' || echo "")
if [ -n "$CPU_USER" ] && [ "$CPU_USER" != "" ]; then
    CPU_PERCENT=$(echo "scale=2; $CPU_USER/100" | bc 2>/dev/null || echo "$CPU_USER")
    echo "  CPU Usuario: ${CPU_PERCENT}%"
else
    echo "  SNMP no disponible o no configurado en servidor web"
fi
echo ""

# Verificar logs de NGINX (últimas líneas)
echo -e "${YELLOW}[3.3] Últimas líneas de log de acceso de NGINX...${NC}"
gcloud compute ssh web-server --zone=$ZONE --tunnel-through-iap --command="sudo tail -5 /var/log/nginx/access.log 2>/dev/null || echo 'Log no disponible'" 2>/dev/null | grep -v "WARNING:" | grep -v "setlocale" || echo "No se pudo acceder a los logs"
echo ""

echo "=========================================="
echo "4. RESUMEN DE DISPONIBILIDAD"
echo "=========================================="
echo ""

# Resumen
echo "Servidor Web: web-server"
echo "  IP Interna:  $WEB_IP"
if [ -n "$WEB_EXT_IP" ]; then
    echo "  IP Externa:  $WEB_EXT_IP"
fi
echo "  Estado NGINX: $NGINX_STATUS"
echo "  HTTP (80):   $([ "$HTTP_TEST" = "200" ] && echo "✓ Disponible" || echo "✗ No disponible")"
echo "  HTTPS (443): $([ "$HTTPS_TEST" = "200" ] || [ "$HTTPS_TEST" = "301" ] || [ "$HTTPS_TEST" = "302" ] && echo "✓ Disponible" || echo "⚠ No configurado")"
echo ""

if [ "$NGINX_STATUS" = "active" ] && [ "$HTTP_TEST" = "200" ]; then
    echo -e "${GREEN}✓ Servidor web está disponible y funcionando correctamente${NC}"
else
    echo -e "${RED}✗ Servidor web tiene problemas de disponibilidad${NC}"
fi
echo ""

echo "=========================================="
echo "5. MONITOREO DE VPN (CUANDO ESTÉ DISPONIBLE)"
echo "=========================================="
echo ""

# TODO: Agregar monitoreo de VPN cuando esté implementada
# Ejemplo de estructura para cuando la VPN esté lista:
#
# VPN_SERVER="vpn-server"  # Nombre de la instancia VPN
# VPN_IP=$(gcloud compute instances describe $VPN_SERVER --zone=$ZONE --format="get(networkInterfaces[0].networkIP)" 2>/dev/null || echo "")
# 
# if [ -n "$VPN_IP" ]; then
#     echo -e "${YELLOW}[5.1] Estado del servicio VPN...${NC}"
#     # Verificar estado del servicio VPN (OpenVPN/WireGuard/etc)
#     # VPN_STATUS=$(gcloud compute ssh $VPN_SERVER --zone=$ZONE --tunnel-through-iap --command="sudo systemctl is-active openvpn@server" 2>/dev/null || echo "unknown")
#     
#     echo -e "${YELLOW}[5.2] Prueba de conectividad VPN...${NC}"
#     # Probar conexión al puerto VPN
#     
#     echo -e "${YELLOW}[5.3] Verificar autenticación LDAP...${NC}"
#     # Verificar que la integración con LDAP funcione
# else
#     echo -e "${YELLOW}⚠ VPN no está implementada aún${NC}"
#     echo "  Este script se actualizará cuando la VPN esté disponible"
# fi
# echo ""

echo -e "${YELLOW}⚠ VPN no está implementada aún${NC}"
echo "  Este script se actualizará cuando la VPN esté disponible"
echo ""

echo "=========================================="
echo "6. RESUMEN GENERAL"
echo "=========================================="
echo ""

echo "SERVICIOS MONITOREADOS:"
echo ""
echo "Servidor Web: web-server"
echo "  IP Interna:  $WEB_IP"
if [ -n "$WEB_EXT_IP" ]; then
    echo "  IP Externa:  $WEB_EXT_IP"
fi
echo "  Estado NGINX: $NGINX_STATUS"
echo "  HTTP (80):   $([ "$HTTP_TEST" = "200" ] && echo "✓ Disponible" || echo "✗ No disponible")"
echo "  HTTPS (443): $([ "$HTTPS_TEST" = "200" ] || [ "$HTTPS_TEST" = "301" ] || [ "$HTTPS_TEST" = "302" ] && echo "✓ Disponible" || echo "⚠ No configurado")"
echo ""
echo "VPN:"
echo "  Estado: ⚠ No implementada aún"
echo ""

# Resumen final
WEB_OK=$([ "$NGINX_STATUS" = "active" ] && [ "$HTTP_TEST" = "200" ] && echo "1" || echo "0")

if [ "$WEB_OK" = "1" ]; then
    echo -e "${GREEN}✓ Servicios disponibles: Web${NC}"
else
    echo -e "${RED}✗ Servicios con problemas: Web${NC}"
fi
echo ""

