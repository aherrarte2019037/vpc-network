#!/bin/bash
set -eux

# Instalar Apache
apt-get update
apt-get install -y apache2

# Crear página HTML básica para RRHH
mkdir -p /var/www/html
cat > /var/www/html/index.html <<'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistema de Administración de RRHH</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        p {
            color: #555;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Sistema de Administración de RRHH</h1>
        <p>Bienvenido al sistema interno de Recursos Humanos</p>
        <p>Este servidor es accesible únicamente desde dentro de la red interna.</p>
    </div>
</body>
</html>
HTML_EOF

# Configurar Apache para escuchar en todas las interfaces
sed -i 's/Listen 80/Listen 0.0.0.0:80/' /etc/apache2/ports.conf

# Habilitar y reiniciar Apache
systemctl enable apache2
systemctl restart apache2

# Verificar que está corriendo
systemctl status apache2 --no-pager | head -5

# =============================================================================
# Configuración SNMPv3 - Fase 3
# =============================================================================
# Instalar y configurar SNMPv3
apt-get install -y snmp snmpd libsnmp-dev -qq 2>/dev/null || true
systemctl stop snmpd 2>/dev/null || true
net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA -x AES snmpuser 2>/dev/null || true

cat > /etc/snmp/snmpd.conf <<SNMP_EOF
agentAddress udp:161
sysLocation "Data Center - RRHH Web Server"
sysContact "admin@x.local"
sysName rrhh.x.local
view systemview included .1.3.6.1.2.1.1
view systemview included .1.3.6.1.2.1.25.1
view systemview included .1.3.6.1.4.1
rouser snmpuser auth
SNMP_EOF

systemctl enable snmpd
systemctl start snmpd

# =============================================================================
# Configuración SNMPv3 - Fase 3
# =============================================================================

# Instalar SNMP
apt-get install -y snmp snmpd libsnmp-dev

# Detener SNMP antes de configurar
systemctl stop snmpd

# Crear usuario SNMPv3 de forma no interactiva
echo "snmpuser" | net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA -x AES snmpuser 2>/dev/null || {
  service snmpd stop
  net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA -x AES snmpuser <<EOF
snmpuser
EOF
}

# Configurar snmpd.conf
cat > /etc/snmp/snmpd.conf <<SNMP_EOF
# SNMPv3 Configuration - Fase 3
agentAddress udp:161
sysLocation "Data Center - RRHH Server"
sysContact "admin@x.local"
sysName rrhh.x.local

view systemview included .1.3.6.1.2.1.1
view systemview included .1.3.6.1.2.1.25.1
view systemview included .1.3.6.1.4.1

rouser snmpuser auth
SNMP_EOF

# Habilitar y reiniciar SNMP
systemctl enable snmpd
systemctl restart snmpd

