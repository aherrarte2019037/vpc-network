#!/bin/bash
# test-connectivity.sh
# Script para probar la conectividad entre instancias

echo "======================================"
echo "Pruebas de Conectividad de Red"
echo "======================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Obtener IPs de las instancias desde Terraform
echo "Obteniendo IPs de las instancias..."
VENTAS_IP=$(terraform output -raw ventas_vm_internal_ip 2>/dev/null)
TI_IP=$(terraform output -raw ti_vm_internal_ip 2>/dev/null)
DC_IP=$(terraform output -raw datacenter_vm_internal_ip 2>/dev/null)

if [ -z "$VENTAS_IP" ] || [ -z "$TI_IP" ] || [ -z "$DC_IP" ]; then
    echo -e "${RED}Error: No se pudieron obtener las IPs de las instancias.${NC}"
    echo "Asegúrate de haber habilitado el archivo instances.tf"
    echo "Renombra instances.tf.disabled a instances.tf y ejecuta 'terraform apply'"
    exit 1
fi

echo -e "${GREEN}IPs encontradas:${NC}"
echo "  Ventas: $VENTAS_IP"
echo "  TI: $TI_IP"
echo "  Data Center: $DC_IP"
echo ""

# Función para conectarse y hacer ping
test_ping() {
    local SOURCE=$1
    local SOURCE_NAME=$2
    local TARGET_IP=$3
    local TARGET_NAME=$4
    
    echo -e "${YELLOW}Probando: $SOURCE_NAME -> $TARGET_NAME${NC}"
    
    # Comando para ejecutar ping dentro de la instancia
    gcloud compute ssh $SOURCE \
        --zone=us-central1-a \
        --command="ping -c 4 $TARGET_IP" \
        --tunnel-through-iap \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Conectividad exitosa${NC}"
    else
        echo -e "${RED}✗ Fallo en la conectividad${NC}"
    fi
    echo ""
}

echo "======================================"
echo "Iniciando pruebas de conectividad..."
echo "======================================"
echo ""

# Prueba 1: Ventas -> TI
test_ping "test-ventas-vm" "Ventas" "$TI_IP" "TI"

# Prueba 2: Ventas -> Data Center
test_ping "test-ventas-vm" "Ventas" "$DC_IP" "Data Center"

# Prueba 3: TI -> Ventas
test_ping "test-ti-vm" "TI" "$VENTAS_IP" "Ventas"

# Prueba 4: TI -> Data Center
test_ping "test-ti-vm" "TI" "$DC_IP" "Data Center"

# Prueba 5: Data Center -> Ventas
test_ping "test-datacenter-vm" "Data Center" "$VENTAS_IP" "Ventas"

# Prueba 6: Data Center -> TI
test_ping "test-datacenter-vm" "Data Center" "$TI_IP" "TI"

echo "======================================"
echo "Pruebas completadas"
echo "======================================"
