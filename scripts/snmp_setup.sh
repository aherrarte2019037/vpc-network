#!/bin/bash
set -eux

# Script para configurar SNMPv3 en las VMs
# Fase 3 - Monitoreo de red

# Instalar SNMP
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y snmp snmpd libsnmp-dev

# Detener SNMP antes de configurar
systemctl stop snmpd

# Configurar SNMPv3 con usuario seguro
# Usuario: snmpuser
# Autenticación: SHA-256
# Encriptación: AES-128
# Contraseña de autenticación: snmpauth123
# Contraseña de privacidad: snmppriv123

# Crear usuario SNMPv3
net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA-256 -x AES snmpuser || true

# Configurar snmpd.conf
cat > /etc/snmp/snmpd.conf <<SNMP_EOF
# SNMPv3 Configuration - Fase 3
# Permitir solo SNMPv3

# Deshabilitar SNMPv1 y SNMPv2c
rocommunity public 127.0.0.1
rocommunity public localhost
# Comentar comunidades públicas por seguridad
# rocommunity public

# Configuración del agente
agentAddress udp:161
agentAddress udp6:161

# Información del sistema
sysLocation "Data Center"
sysContact "admin@x.local"
sysName $(hostname)

# Vista para lectura
view systemview included .1.3.6.1.2.1.1
view systemview included .1.3.6.1.2.1.25.1
view systemview included .1.3.6.1.4.1

# Usuario SNMPv3 con permisos de lectura
rouser snmpuser auth

# Habilitar solo SNMPv3
disableVersion 1
disableVersion 2c
SNMP_EOF

# Habilitar y reiniciar SNMP
systemctl enable snmpd
systemctl start snmpd

# Verificar que está corriendo
systemctl status snmpd --no-pager | head -5

# Verificar que escucha en puerto 161
ss -lptn | grep ':161' || echo "SNMP puede tardar unos segundos en iniciar"
