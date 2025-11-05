#!/bin/bash
# test-security.sh
# Script para probar las políticas de seguridad implementadas en la Fase 2
# Implementado por: Angel Herrarte

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables - Ajustar según las IPs reales de las instancias
# Estas deben ser obtenidas después de crear las instancias
VENTAS_VM_IP=""
TI_VM_IP=""
DC_VM_IP=""
VISITAS_VM_IP=""
WEB_SERVER_IP=""
LDAP_SERVER_IP=""
DNS_SERVER_IP=""

echo "=========================================="
echo "Pruebas de Seguridad - Fase 2"
echo "=========================================="
echo ""

# Función para hacer ping y verificar resultado
test_ping() {
    local source=$1
    local dest=$2
    local expected=$3  # "allow" o "deny"
    local description=$4
    
    echo -n "Testing: $description ... "
    
    if [ "$expected" == "allow" ]; then
        if ping -c 2 -W 2 "$dest" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        else
            echo -e "${RED}✗ FAIL (expected allow but blocked)${NC}"
            return 1
        fi
    else
        if ping -c 2 -W 2 "$dest" > /dev/null 2>&1; then
            echo -e "${RED}✗ FAIL (expected deny but allowed)${NC}"
            return 1
        else
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        fi
    fi
}

# Función para probar conectividad TCP
test_tcp() {
    local source=$1
    local dest=$2
    local port=$3
    local expected=$4  # "allow" o "deny"
    local description=$5
    
    echo -n "Testing: $description ... "
    
    if [ "$expected" == "allow" ]; then
        if nc -z -w 2 "$dest" "$port" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        else
            echo -e "${RED}✗ FAIL (expected allow but blocked)${NC}"
            return 1
        fi
    else
        if nc -z -w 2 "$dest" "$port" > /dev/null 2>&1; then
            echo -e "${RED}✗ FAIL (expected deny but allowed)${NC}"
            return 1
        else
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        fi
    fi
}

# Función para probar HTTP
test_http() {
    local source=$1
    local dest=$2
    local expected=$3
    local description=$4
    
    echo -n "Testing: $description ... "
    
    if [ "$expected" == "allow" ]; then
        if curl -s --connect-timeout 2 "http://$dest" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        else
            echo -e "${RED}✗ FAIL (expected allow but blocked)${NC}"
            return 1
        fi
    else
        if curl -s --connect-timeout 2 "http://$dest" > /dev/null 2>&1; then
            echo -e "${RED}✗ FAIL (expected deny but allowed)${NC}"
            return 1
        else
            echo -e "${GREEN}✓ PASS${NC}"
            return 0
        fi
    fi
}

# Verificar que las variables están configuradas
if [ -z "$VENTAS_VM_IP" ] || [ -z "$TI_VM_IP" ] || [ -z "$DC_VM_IP" ]; then
    echo -e "${YELLOW}ADVERTENCIA: Las IPs de las instancias no están configuradas.${NC}"
    echo "Por favor, edita este script y configura las variables de IP al inicio."
    echo ""
    echo "Para obtener las IPs, ejecuta:"
    echo "  terraform output"
    echo ""
    exit 1
fi

echo "=========================================="
echo "1. PRUEBAS DE AISLAMIENTO DE VISITAS"
echo "=========================================="
echo ""

# Visitas NO debe poder acceder a subredes internas
# Nota: Estas pruebas deben ejecutarse desde una instancia en Visitas
echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde una instancia en la subred de Visitas${NC}"
echo ""

echo "=========================================="
echo "2. PRUEBAS DE ACCESO DE TI"
echo "=========================================="
echo ""

# TI debe poder acceder a todas las subredes
# Estas pruebas deben ejecutarse desde una instancia en TI
echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde una instancia en la subred de TI${NC}"
echo ""

echo "=========================================="
echo "3. PRUEBAS DE ACCESO AL SERVIDOR WEB"
echo "=========================================="
echo ""

if [ -n "$WEB_SERVER_IP" ]; then
    # Estas pruebas deben ejecutarse desde diferentes subredes
    echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde instancias en diferentes subredes${NC}"
    echo ""
    echo "Desde Ventas/TI/RRHH:"
    echo "  curl http://$WEB_SERVER_IP (debe funcionar)"
    echo ""
    echo "Desde Visitas:"
    echo "  curl http://$WEB_SERVER_IP (debe bloquearse)"
    echo ""
    echo "Desde Internet (fuera de la VPC):"
    echo "  curl http://$WEB_SERVER_IP (debe bloquearse)"
    echo ""
else
    echo -e "${YELLOW}IP del servidor web no configurada${NC}"
fi

echo "=========================================="
echo "4. PRUEBAS DE ACCESO A LDAP"
echo "=========================================="
echo ""

if [ -n "$LDAP_SERVER_IP" ]; then
    echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde instancias en diferentes subredes${NC}"
    echo ""
    echo "Desde Ventas/TI/RRHH:"
    echo "  ldapsearch -x -H ldap://$LDAP_SERVER_IP (debe funcionar)"
    echo ""
    echo "Desde Visitas:"
    echo "  ldapsearch -x -H ldap://$LDAP_SERVER_IP (debe bloquearse)"
    echo ""
else
    echo -e "${YELLOW}IP del servidor LDAP no configurada${NC}"
fi

echo "=========================================="
echo "5. PRUEBAS DE ACCESO A DNS"
echo "=========================================="
echo ""

if [ -n "$DNS_SERVER_IP" ]; then
    echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde instancias en diferentes subredes${NC}"
    echo ""
    echo "Desde subredes internas:"
    echo "  dig @$DNS_SERVER_IP rrhh.x.local (debe funcionar)"
    echo ""
    echo "Desde Visitas:"
    echo "  dig @$DNS_SERVER_IP rrhh.x.local (debe bloquearse)"
    echo ""
else
    echo -e "${YELLOW}IP del servidor DNS no configurada${NC}"
fi

echo "=========================================="
echo "6. PRUEBAS DE SSH"
echo "=========================================="
echo ""

echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde instancias en diferentes subredes${NC}"
echo ""
echo "Desde Ventas (con usuario autorizado en LDAP):"
echo "  ssh usuario@$VENTAS_VM_IP (debe funcionar después de configurar LDAP)"
echo ""
echo "Desde Visitas:"
echo "  ssh usuario@$VENTAS_VM_IP (debe bloquearse)"
echo ""
echo "Desde Internet:"
echo "  ssh usuario@$VENTAS_VM_IP (debe bloquearse)"
echo ""

echo "=========================================="
echo "7. PRUEBAS DE ACCESO A INTERNET (NAT)"
echo "=========================================="
echo ""

echo -e "${YELLOW}Nota: Estas pruebas requieren ejecutarse desde una instancia en Visitas${NC}"
echo ""
echo "Desde Visitas:"
echo "  curl https://www.google.com (debe funcionar - prueba de NAT)"
echo ""

echo "=========================================="
echo "RESUMEN DE PRUEBAS"
echo "=========================================="
echo ""
echo "Para ejecutar pruebas completas, necesitas:"
echo "1. Instancias en cada subred (Ventas, TI, Data Center, Visitas)"
echo "2. Configurar las IPs en este script"
echo "3. Ejecutar las pruebas desde cada instancia correspondiente"
echo ""
echo "Comandos útiles para obtener IPs:"
echo "  terraform output"
echo "  gcloud compute instances list"
echo ""

echo "=========================================="
echo "Pruebas completadas"
echo "=========================================="
