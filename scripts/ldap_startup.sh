#!/bin/bash
set -eux

# Instalar OpenLDAP
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y slapd ldap-utils debconf-utils

# Configurar slapd con dominio dc=x,dc=local
debconf-set-selections <<DEBCONF_EOF
slapd slapd/internal/generated_adminpw password admin123
slapd slapd/internal/adminpw password admin123
slapd slapd/password1 password admin123
slapd slapd/password2 password admin123
slapd slapd/domain string x.local
slapd shared/organization string x
slapd slapd/backend string MDB
slapd slapd/purge_database boolean false
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
DEBCONF_EOF

dpkg-reconfigure -f noninteractive slapd

# Esperar a que slapd esté listo
sleep 5
systemctl restart slapd
sleep 3

# Crear archivo LDIF con estructura base
cat > /tmp/base.ldif <<'BASE_EOF'
dn: dc=x,dc=local
objectClass: top
objectClass: dcObject
objectClass: organization
o: x
dc: x

dn: cn=admin,dc=x,dc=local
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword: {SSHA}admin123
BASE_EOF

# Crear OUs y grupos
cat > /tmp/ou.ldif <<'OU_EOF'
dn: ou=rrhh,dc=x,dc=local
objectClass: organizationalUnit
ou: rrhh
description: Recursos Humanos

dn: ou=ventas,dc=x,dc=local
objectClass: organizationalUnit
ou: ventas
description: Equipo de Ventas

dn: cn=rrhh,ou=rrhh,dc=x,dc=local
objectClass: posixGroup
cn: rrhh
gidNumber: 1001
description: Grupo de Recursos Humanos

dn: cn=ventas,ou=ventas,dc=x,dc=local
objectClass: posixGroup
cn: ventas
gidNumber: 1002
description: Grupo de Ventas

dn: cn=ti-admins,dc=x,dc=local
objectClass: posixGroup
cn: ti-admins
gidNumber: 1003
description: Administradores de TI
OU_EOF

# Crear usuarios
cat > /tmp/users.ldif <<'USERS_EOF'
dn: uid=user1,ou=rrhh,dc=x,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: user1
sn: User1
givenName: Test
cn: Test User1
displayName: Test User1
uidNumber: 2001
gidNumber: 1001
userPassword: {SSHA}user1pass
gecos: Test User1
loginShell: /bin/bash
homeDirectory: /home/user1

dn: uid=user2,ou=rrhh,dc=x,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: user2
sn: User2
givenName: Test
cn: Test User2
displayName: Test User2
uidNumber: 2002
gidNumber: 1001
userPassword: {SSHA}user2pass
gecos: Test User2
loginShell: /bin/bash
homeDirectory: /home/user2

dn: uid=user3,ou=ventas,dc=x,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: user3
sn: User3
givenName: Test
cn: Test User3
displayName: Test User3
uidNumber: 2003
gidNumber: 1002
userPassword: {SSHA}user3pass
gecos: Test User3
loginShell: /bin/bash
homeDirectory: /home/user3

dn: uid=user4,ou=ventas,dc=x,dc=local
objectClass: inetOrgPerson
objectClass: posixAccount
objectClass: shadowAccount
uid: user4
sn: User4
givenName: Test
cn: Test User4
displayName: Test User4
uidNumber: 2004
gidNumber: 1002
userPassword: {SSHA}user4pass
gecos: Test User4
loginShell: /bin/bash
homeDirectory: /home/user4
USERS_EOF

# Agregar user1 al grupo ti-admins
cat > /tmp/user1-ti.ldif <<'TI_EOF'
dn: cn=ti-admins,dc=x,dc=local
changetype: modify
add: memberUid
memberUid: user1
TI_EOF

# Cargar estructura LDAP
ldapadd -x -D "cn=admin,dc=x,dc=local" -w admin123 -f /tmp/base.ldif || true
ldapadd -x -D "cn=admin,dc=x,dc=local" -w admin123 -f /tmp/ou.ldif
ldapadd -x -D "cn=admin,dc=x,dc=local" -w admin123 -f /tmp/users.ldif
ldapmodify -x -D "cn=admin,dc=x,dc=local" -w admin123 -f /tmp/user1-ti.ldif || true

# Habilitar y reiniciar slapd
systemctl enable slapd
systemctl restart slapd

# Verificar que está corriendo
systemctl status slapd --no-pager | head -5

