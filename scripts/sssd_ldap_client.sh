#!/bin/bash
set -eux

# Obtener IP del servidor LDAP
# Intentar desde metadata de GCP, luego DNS, luego valor por defecto
LDAP_SERVER_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/compute/metadata/v1/instance/attributes/ldap-server-ip 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || echo "")
if [ -z "$LDAP_SERVER_IP" ]; then
  # Instalar dnsutils primero
  apt-get install -y dnsutils -qq 2>/dev/null || true
  # Intentar resolver desde DNS
  LDAP_SERVER_IP=$(nslookup ldap.x.local 2>/dev/null | grep -A 1 "Name:" | grep "Address:" | awk '{print $2}' | head -1 | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || echo "")
fi
if [ -z "$LDAP_SERVER_IP" ]; then
  # Valor por defecto
  LDAP_SERVER_IP="10.0.0.138"
fi

echo "Usando servidor LDAP en: $LDAP_SERVER_IP"

LDAP_BASE_DN="dc=x,dc=local"

# Instalar SSSD y dependencias
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y sssd sssd-ldap ldap-utils libnss-sss libpam-sss

# Configurar SSSD
cat > /etc/sssd/sssd.conf <<SSSD_EOF
[sssd]
config_file_version = 2
services = nss, pam
domains = x.local

[nss]
filter_users = root,sssd
filter_groups = root

[pam]

[domain/x.local]
id_provider = ldap
auth_provider = ldap
ldap_uri = ldap://${LDAP_SERVER_IP}
ldap_search_base = ${LDAP_BASE_DN}
ldap_id_use_start_tls = False
ldap_tls_reqcert = never
cache_credentials = True
enumerate = True
ldap_user_search_base = ${LDAP_BASE_DN}
ldap_group_search_base = ${LDAP_BASE_DN}
ldap_user_object_class = posixAccount
ldap_group_object_class = posixGroup
ldap_user_name = uid
ldap_group_name = cn
ldap_user_home_directory = homeDirectory
ldap_user_shell = loginShell
ldap_user_uid = uidNumber
ldap_user_gid = gidNumber
ldap_group_gid = gidNumber
SSSD_EOF

# Configurar permisos de SSSD
chmod 600 /etc/sssd/sssd.conf

# Configurar NSS para usar SSSD
sed -i '/^passwd:/ s/$/ sss/' /etc/nsswitch.conf
sed -i '/^group:/ s/$/ sss/' /etc/nsswitch.conf
sed -i '/^shadow:/ s/$/ sss/' /etc/nsswitch.conf

# Configurar PAM para usar SSSD
pam-auth-update --package --force

# Configurar SSH para restringir acceso a grupos LDAP
# Permitir solo usuarios de grupos: rrhh, ventas, ti-admins
# Nota: OS Login (IAP) funciona a través de AuthorizedKeysCommand, así que no se bloquea
# AllowGroups solo aplica para autenticación con contraseña/clave local
# Excluir usuarios del sistema (root, OS Login users) de la restricción
cat >> /etc/ssh/sshd_config <<SSH_EOF

# Configuración LDAP - Fase 2
# Permitir SSH solo a usuarios de grupos autorizados en LDAP
# OS Login users (que empiezan con números) no se ven afectados
Match User !root,!*[0-9]*
  AllowGroups rrhh ventas ti-admins
PubkeyAuthentication yes
PasswordAuthentication yes
SSH_EOF

# Habilitar y reiniciar SSSD
systemctl enable sssd
systemctl restart sssd

# Reiniciar SSH para aplicar cambios
systemctl restart sshd

# Verificar que SSSD está corriendo
systemctl status sssd --no-pager | head -5

# Probar resolución de usuario LDAP
echo "Probando resolución de usuario LDAP..."
getent passwd user1 || echo "Usuario user1 aún no resuelto (puede tardar unos segundos)"

