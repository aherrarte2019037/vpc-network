# Configuración de Seguridad - Fase 2

**Implementado por:** Angel Herrarte  
**Fecha:** Noviembre 2025  
**Proyecto:** Red Empresarial en GCP - Fase 2

## Resumen

Este documento describe todas las reglas de firewall implementadas para cumplir con los requisitos de seguridad de la Fase 2 del proyecto. Las reglas están organizadas en el archivo `firewall-rules.tf` y reemplazan las reglas básicas de la Fase 1.

## Arquitectura de Subredes

| Subred | CIDR | Descripción |
|--------|------|-------------|
| Ventas | 10.0.0.64/27 | Equipo de ventas (25 hosts) |
| TI | 10.0.0.96/27 | Equipo de TI (15 hosts) |
| Data Center | 10.0.0.128/28 | Servidores (5 hosts) |
| Visitas | 10.0.0.0/26 | Red para visitantes |

## Reglas de Firewall Implementadas

### 1. Aislamiento de Visitas

#### `deny-visitas-to-internal`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 10.0.0.0/26 (Visitas)
- **Destino:** Ventas, TI, Data Center
- **Protocolos:** TCP, UDP, ICMP
- **Propósito:** Bloquea completamente el acceso de la subred de Visitas a todas las subredes internas. Visitas solo puede acceder a Internet vía NAT.
- **Requisito:** "La subred de visitantes debe tener acceso a Internet, pero no a ninguna de las demás subredes."

### 2. Políticas de Acceso para TI

#### `allow-ti-to-all-subnets`
- **Prioridad:** 500 (media)
- **Acción:** ALLOW
- **Origen:** 10.0.0.96/27 (TI)
- **Destino:** Todas las subredes (Ventas, TI, Data Center, Visitas)
- **Protocolos:** TCP, UDP, ICMP
- **Propósito:** Permite que TI acceda a todas las subredes para soporte y administración.
- **Requisito:** "TI tiene conectividad a cualquiera de las otras subredes."

#### `deny-others-to-ti`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** Ventas, Data Center, Visitas
- **Destino:** 10.0.0.96/27 (TI)
- **Protocolos:** TCP, UDP, ICMP
- **Propósito:** Bloquea el acceso a TI desde otras subredes. Solo TI puede acceder a sí mismo.
- **Requisito:** "Las demás subredes no tienen conectividad hacia TI."

### 3. Servidor Web Interno

#### `allow-web-internal`
- **Prioridad:** 500 (media)
- **Acción:** ALLOW
- **Origen:** Ventas, TI, Data Center
- **Destino:** Instancias con tag `web-server-internal`
- **Protocolos:** TCP (puertos 80, 443)
- **Propósito:** Permite acceso HTTP/HTTPS al servidor web interno desde subredes autorizadas.
- **Requisito:** "El servidor Web de la Intranet debe poder ser accesible desde las demás subredes, excepto la subred de visitas."

#### `deny-web-from-internet`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 0.0.0.0/0 (Internet)
- **Destino:** Instancias con tag `web-server-internal`
- **Protocolos:** TCP (puertos 80, 443)
- **Propósito:** Bloquea el acceso al servidor web desde Internet.
- **Requisito:** "No debe ser accesible desde el Internet."

#### `deny-web-from-visitas`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 10.0.0.0/26 (Visitas)
- **Destino:** Instancias con tag `web-server-internal`
- **Protocolos:** TCP (puertos 80, 443)
- **Propósito:** Bloquea el acceso al servidor web desde la subred de Visitas.
- **Requisito:** "No accesible desde la subred de visitas."

### 4. Servidor LDAP

#### `allow-ldap-internal`
- **Prioridad:** 500 (media)
- **Acción:** ALLOW
- **Origen:** Ventas, TI, Data Center
- **Destino:** 10.0.0.128/28 (Data Center), instancias con tag `ldap-server`
- **Protocolos:** TCP (puertos 389, 636), UDP (puerto 389)
- **Propósito:** Permite acceso LDAP/LDAPS desde subredes autorizadas hacia el Data Center.
- **Requisito:** "El servidor LDAP debe estar en el datacenter y ser accesible para autenticación."

#### `deny-ldap-from-visitas`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 10.0.0.0/26 (Visitas)
- **Destino:** 10.0.0.128/28 (Data Center), instancias con tag `ldap-server`
- **Protocolos:** TCP (puertos 389, 636), UDP (puerto 389)
- **Propósito:** Bloquea el acceso LDAP desde la subred de Visitas.
- **Requisito:** Consistente con el aislamiento de Visitas.

### 5. Servidor DNS

#### `allow-dns-internal`
- **Prioridad:** 500 (media)
- **Acción:** ALLOW
- **Origen:** Ventas, TI, Data Center
- **Destino:** 10.0.0.128/28 (Data Center), instancias con tag `dns-server`
- **Protocolos:** TCP (puerto 53), UDP (puerto 53)
- **Propósito:** Permite acceso DNS desde todas las subredes internas.
- **Requisito:** DNS debe ser accesible desde subredes internas para resolución de nombres.

#### `deny-dns-from-visitas`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 10.0.0.0/26 (Visitas)
- **Destino:** 10.0.0.128/28 (Data Center), instancias con tag `dns-server`
- **Protocolos:** TCP (puerto 53), UDP (puerto 53)
- **Propósito:** Bloquea el acceso DNS desde la subred de Visitas.
- **Requisito:** Consistente con el aislamiento de Visitas.

### 6. Control de Acceso SSH

#### `allow-ssh-from-ventas`
- **Prioridad:** 500 (media)
- **Acción:** ALLOW
- **Origen:** 10.0.0.64/27 (Ventas)
- **Destino:** Todas las instancias
- **Protocolos:** TCP (puerto 22)
- **Propósito:** Permite SSH desde Ventas. La validación LDAP se realiza en las instancias (PAM).
- **Requisito:** "Los usuarios de RRHH y ventas deben poder conectarse mediante SSH a sus instancias, únicamente si están autorizados en el servidor LDAP."

#### `allow-ssh-from-ti`
- **Prioridad:** 500 (media)
- **Acción:** ALLOW
- **Origen:** 10.0.0.96/27 (TI)
- **Destino:** Todas las instancias
- **Protocolos:** TCP (puerto 22)
- **Propósito:** Permite SSH desde TI (acceso completo para administración).
- **Requisito:** TI necesita acceso completo para administración.

#### `deny-ssh-from-visitas`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 10.0.0.0/26 (Visitas)
- **Destino:** Todas las instancias
- **Protocolos:** TCP (puerto 22)
- **Propósito:** Bloquea SSH desde la subred de Visitas.
- **Requisito:** Consistente con el aislamiento de Visitas.

#### `deny-ssh-from-internet`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 0.0.0.0/0 (Internet)
- **Destino:** Todas las instancias
- **Protocolos:** TCP (puerto 22)
- **Propósito:** Bloquea SSH desde Internet. Solo permite acceso desde subredes internas autorizadas.
- **Requisito:** Hardening de seguridad - no exponer SSH a Internet.

### 7. Hardening

#### `deny-non-essential-ports`
- **Prioridad:** 1000 (alta)
- **Acción:** DENY
- **Origen:** 0.0.0.0/0 (Internet)
- **Destino:** Todas las instancias
- **Protocolos:** TCP y UDP (todos los puertos excepto: 22, 53, 80, 443, 389, 636)
- **Propósito:** Bloquea puertos no esenciales desde Internet. Solo permite servicios necesarios.
- **Requisito:** "Debe cerrar/bloquear puertos que no estén en uso (hardening)."

### 8. Tráfico Interno Autorizado

#### `allow-internal-authorized`
- **Prioridad:** 400 (media-baja)
- **Acción:** ALLOW
- **Origen:** Ventas, TI, Data Center
- **Destino:** Ventas, TI, Data Center
- **Protocolos:** TCP, UDP, ICMP
- **Propósito:** Permite tráfico interno entre subredes autorizadas, excluyendo Visitas.
- **Requisito:** Comunicación interna entre subredes autorizadas.

## NAT (Network Address Translation)

### Configuración Actual

El Cloud NAT está configurado para todas las subredes (`ALL_SUBNETWORKS_ALL_IP_RANGES`), lo que permite que:

1. **Visitas** pueda acceder a Internet (cumpliendo el requisito de acceso a Internet pero no a subredes internas)
2. Otras subredes puedan usar NAT si no tienen IPs públicas

**Archivo:** `main.tf` - `google_compute_router_nat.nat`

## Tags Requeridos

Para que las reglas de firewall funcionen correctamente, las instancias deben tener los siguientes tags:

- **`web-server-internal`**: Instancias del servidor web interno (RRHH)
- **`ldap-server`**: Instancias del servidor LDAP
- **`dns-server`**: Instancias del servidor DNS

## Notas Importantes

### Limitaciones de Firewall en GCP

1. **Validación LDAP para SSH:** El firewall de GCP no puede validar directamente la autenticación LDAP. El firewall solo controla qué IPs pueden intentar conectarse por SSH. La validación LDAP debe implementarse en las instancias usando PAM (Pluggable Authentication Modules) y un cliente LDAP.

2. **Orden de Prioridad:** Las reglas con prioridad más alta (1000) tienen precedencia sobre las de prioridad más baja (400-500). Las reglas DENY con prioridad alta bloquean el tráfico antes de que las reglas ALLOW de menor prioridad puedan permitirlo.

3. **Reglas por Defecto:** GCP tiene una regla implícita que permite todo el tráfico saliente. Las reglas de firewall solo controlan el tráfico entrante.

### Coordinación con Otros Miembros del Equipo

- **Persona 1 (DNS):** Asegurar que las instancias DNS tengan el tag `dns-server`
- **Persona 2 (LDAP):** Asegurar que las instancias LDAP tengan el tag `ldap-server` y estén en el Data Center
- **Persona 3 (Web):** Asegurar que las instancias del servidor web tengan el tag `web-server-internal` y estén en el Data Center

## Pruebas de Conectividad

Ver el archivo `test-security.sh` para un script completo de pruebas de conectividad.

### Pruebas Clave

1. ✅ Visitas → Internet: Debe funcionar (vía NAT)
2. ❌ Visitas → Ventas/TI/Data Center: Debe bloquearse
3. ✅ TI → Todas las subredes: Debe funcionar
4. ❌ Ventas/Data Center → TI: Debe bloquearse
5. ✅ Ventas/TI/RRHH → Web Interno: Debe funcionar
6. ❌ Internet/Visitas → Web Interno: Debe bloquearse
7. ✅ Ventas/TI/RRHH → LDAP: Debe funcionar
8. ❌ Visitas → LDAP: Debe bloquearse
9. ✅ Ventas/TI/RRHH → DNS: Debe funcionar
10. ❌ Visitas → DNS: Debe bloquearse
11. ✅ Ventas (con usuario LDAP autorizado) → SSH: Debe funcionar
12. ❌ Visitas/Internet → SSH: Debe bloquearse

## Archivos Relacionados

- `firewall-rules.tf`: Todas las reglas de firewall implementadas
- `main.tf`: Configuración de VPC, subredes y NAT
- `test-security.sh`: Script de pruebas de conectividad
- `variables.tf`: Variables de configuración

## Referencias

- [Google Cloud Firewall Rules Documentation](https://cloud.google.com/vpc/docs/firewalls)
- [GCP Firewall Rule Priority](https://cloud.google.com/vpc/docs/firewalls#priority)
- [Cloud NAT Documentation](https://cloud.google.com/nat/docs/overview)
