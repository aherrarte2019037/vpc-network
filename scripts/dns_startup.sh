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

zone "3.0.10.in-addr.arpa" {
        type master;
        file "/etc/bind/db.10.0.3";
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

dns     IN      A       10.0.3.10
rrhh    IN      A       10.0.3.20
ldap    IN      A       10.0.3.30
ZONE_EOF

# Configurar zona reverse db.10.0.3
cat > /etc/bind/db.10.0.3 <<'REVERSE_EOF'
$TTL    604800
@       IN      SOA     dns.x.local. admin.x.local. (
                        2
                        604800
                        86400
                        2419200
                        604800 )

@       IN      NS      dns.x.local.

10      IN      PTR     dns.x.local.
20      IN      PTR     rrhh.x.local.
30      IN      PTR     ldap.x.local.
REVERSE_EOF

# Verificar configuración
named-checkconf
named-checkzone x.local /etc/bind/db.x.local
named-checkzone 3.0.10.in-addr.arpa /etc/bind/db.10.0.3

# Habilitar y reiniciar BIND9
systemctl enable named
systemctl restart named

# Verificar que está corriendo
systemctl status named --no-pager

