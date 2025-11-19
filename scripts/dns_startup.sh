#!/bin/bash
set -eux

# Instalar BIND9
apt-get update
apt-get install -y bind9 bind9utils bind9-doc

# Configurar named.conf.options
cat > /etc/bind/named.conf.options <<'OPTIONS_EOF'
options {
        directory "/var/cache/bind";

        recursion yes;
        allow-recursion { 10.0.0.0/16; };

        forwarders {
                8.8.8.8;
                1.1.1.1;
        };

        dnssec-validation auto;

        listen-on { any; };
        listen-on-v6 { none; };
};
OPTIONS_EOF

# Configurar named.conf.local
cat > /etc/bind/named.conf.local <<'LOCAL_EOF'
zone "x.local" {
        type master;
        file "/etc/bind/db.x.local";
};

zone "0.0.10.in-addr.arpa" {
        type master;
        file "/etc/bind/db.10.0.0";
};
LOCAL_EOF

# Configurar zona forward db.x.local
cat > /etc/bind/db.x.local <<'ZONE_EOF'
$TTL    604800
@       IN      SOA     dns.x.local. admin.x.local. (
                        2         ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

@       IN      NS      dns.x.local.

dns     IN      A       10.0.0.139
rrhh    IN      A       10.0.0.133
ldap    IN      A       10.0.0.138
ZONE_EOF

# Configurar zona reverse db.10.0.0
cat > /etc/bind/db.10.0.0 <<'REVERSE_EOF'
$TTL    604800
@       IN      SOA     dns.x.local. admin.x.local. (
                        2
                        604800
                        86400
                        2419200
                        604800 )

@       IN      NS      dns.x.local.

139     IN      PTR     dns.x.local.
133     IN      PTR     rrhh.x.local.
138     IN      PTR     ldap.x.local.
REVERSE_EOF

# Verificar configuración
named-checkconf
named-checkzone x.local /etc/bind/db.x.local
named-checkzone 0.0.10.in-addr.arpa /etc/bind/db.10.0.0

# Habilitar y reiniciar BIND9
systemctl enable named
systemctl restart named

# Verificar que está corriendo
systemctl status named --no-pager

# =============================================================================
# Configuración SNMP (Fase 3)
# =============================================================================
# Instalar y configurar SNMPv3
export DEBIAN_FRONTEND=noninteractive
apt-get install -y snmp snmpd libsnmp-dev -qq 2>/dev/null || true

# Detener SNMP antes de configurar
systemctl stop snmpd 2>/dev/null || true

# Crear usuario SNMPv3 (usar SHA en lugar de SHA-256 para compatibilidad)
net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA -x AES snmpuser 2>/dev/null || true

# Configurar snmpd.conf
cat > /etc/snmp/snmpd.conf <<SNMP_EOF
# SNMPv3 Configuration - Fase 3
agentAddress udp:161
sysLocation "Data Center - DNS Server"
sysContact "admin@x.local"
sysName dns.x.local

view systemview included .1.3.6.1.2.1.1
view systemview included .1.3.6.1.2.1.25.1
view systemview included .1.3.6.1.4.1

rouser snmpuser auth
SNMP_EOF

# Habilitar y reiniciar SNMP
systemctl enable snmpd
systemctl start snmpd

# Verificar que está corriendo
sleep 2
systemctl status snmpd --no-pager | head -5

# =============================================================================
# Configuración SNMPv3 - Fase 3
# =============================================================================

# Instalar SNMP
apt-get install -y snmp snmpd libsnmp-dev

# Detener SNMP antes de configurar
systemctl stop snmpd

# Crear usuario SNMPv3 de forma no interactiva
echo "snmpuser" | net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA -x AES snmpuser 2>/dev/null || {
  # Si falla, intentar crear manualmente
  service snmpd stop
  net-snmp-create-v3-user -ro -A snmpauth123 -X snmppriv123 -a SHA -x AES snmpuser <<EOF
snmpuser
EOF
}

# Configurar snmpd.conf
cat > /etc/snmp/snmpd.conf <<SNMP_EOF
agentAddress udp:161,udp6:[::1]:161
view all included .1
rouser snmpuser auth priv
sysLocation "Data Center, GCP"
sysContact "admin@x.local"
sysName $(hostname)
SNMP_EOF

# Habilitar y reiniciar SNMP
systemctl enable snmpd
systemctl restart snmpd

