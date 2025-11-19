# UNIVERSIDAD DEL VALLE DE GUATEMALA
## CC3067 - REDES
## Sección 11
## MIGUEL NOVELLA LINARES

# Proyecto Grupal
## Fase 2 – Implementación de una Red en la nube

**Integrantes:**
- Ruth de León, 22428
- Isabella Miralles, 22293
- José Gramajo, 22907
- Angel Herrarte, 22873

**GUATEMALA, 6 de noviembre del 2025**

---

## Contenido

- Fase 1 – Diseño y Segmentación en la Nube
  - Proveedor en la nube
  - Diagrama de red
  - Segmentación de Red
  - Implementación de la segmentación
  - Pruebas y archivos de configuración
- Fase 2 – Implementación de una Red en la nube
  - DNS + apoyo en integración con Web Interno
  - Directorio OpenLDAP
  - Servidor Web Interno (Lógica del negocio)
  - Seguridad y Control de Acceso (Firewall, ACL y NAT)
- Fase 3 - Implementación de Servicios Públicos, Seguridad y Monitoreo en la Nube
  - Infraestructura pública, DMZ y Web público (Isa)
  - Seguridad y Firewall (Ruth)
  - VPN con autenticación LDAP
  - SNMP + Monitoreo + Documentación final

---

## Fase 1 – Diseño y Segmentación en la Nube

### Proveedor en la nube

Para el desarrollo de la infraestructura de red de la empresa, se eligió Google Cloud Platform (GCP) como proveedor de servicios en la nube.

Esta elección se justifica por su equilibrio entre rendimiento, seguridad, sostenibilidad y facilidad de administración, características esenciales para una startup que busca escalar sus servicios y mantener costos controlados.

Google Cloud ofrece una red global con baja latencia y alta disponibilidad, lo que garantiza una comunicación eficiente entre las diferentes subredes del proyecto (ventas, TI, data center y visitas). Además, su infraestructura está optimizada para la virtualización y segmentación de redes mediante Virtual Private Cloud (VPC), lo que facilita la configuración de entornos seguros y aislados según las necesidades de cada área (Google Cloud, 2024a).

Otro motivo importante es su compromiso con la sostenibilidad: Google Cloud opera con energía 100 % renovable, reduciendo la huella de carbono de la empresa y apoyando la responsabilidad ambiental (Devoteam, 2024). Asimismo, su integración con herramientas de análisis, inteligencia artificial y automatización puede servir como base para futuras fases del proyecto y la expansión tecnológica del negocio (Immune Institute, 2023).

En cuanto a las ventajas principales, destacan su flexibilidad, seguridad avanzada, facilidad de escalado y modelo de costos por uso. Como desventaja, algunos servicios pueden requerir mayor conocimiento técnico y un proceso de configuración más detallado en comparación con otras plataformas (Google Cloud, 2024b).

Google Cloud fue seleccionado por su infraestructura confiable, su capacidad de crecimiento y su orientación hacia la innovación y sostenibilidad, factores que la convierten en la mejor opción para soportar la red empresarial propuesta.

### Diagrama de red

*(Diagrama de red mostrando:)*
- Subred de Ventas: 10.0.1.0/24, 25 hosts
- Subred de TI: 10.0.2.0/24, 15 hosts
- Subred de Data Center: 10.0.3.0/24, 5 hosts
- Subred de Visitas: 10.0.4.0/24, limited access
- Router central conectando todas las subredes
- Firewall and NAT conectado a Internet

### Segmentación de Red

#### 3.1 Red base y criterio de diseño

Se utiliza la VPC con red base 10.0.0.0/16 en Google Cloud Platform (GCP). Para simplificar administración y asegurar escalabilidad, cada segmento se define como /24 (254 hosts útiles) según el esquema propuesto del equipo.

**Segmentos requeridos por el proyecto:** Ventas (25), TI (15), Data Center (5 servidores) y Visitas (aforo variable).

**Justificación de /24:** simplicidad, amplio espacio de crecimiento, facilidad de documentación y aislamiento por función.

#### 3.2 Cálculos de subneteo

Fórmula: 2^h - 2 ≥ n (hosts). Para /24: h=8 ⇒ 2^8-2=254 hosts útiles.

| Segmento    | Necesidad | Cálculo      | Prefijo elegido | Hosts útiles |
|-------------|-----------|--------------|-----------------|--------------|
| Ventas      | 25        | 2^8-2=254    | /24             | 254          |
| TI          | 15        | 2^8-2=254    | /24             | 254          |
| Data Center | 5         | 2^8-2=254    | /24             | 254          |
| Visitas     | Variable  | 2^8-2=254    | /24             | 254          |

#### 3.3 Tabla de segmentación final

Se definen CIDR, máscara, red, primer/último host, broadcast y gateway para cada subred. (Gateways en .1 para consistencia).

| Segmento    | CIDR         | Máscara         | Red      | 1er host | Último host | Broadcast  | Gateway  |
|-------------|--------------|-----------------|----------|----------|-------------|------------|----------|
| Ventas      | 10.0.1.0/24  | 255.255.255.0   | 10.0.1.0 | 10.0.1.1 | 10.0.1.254  | 10.0.1.255 | 10.0.1.1 |
| TI          | 10.0.2.0/24  | 255.255.255.0   | 10.0.2.0 | 10.0.2.1 | 10.0.2.254  | 10.0.2.255 | 10.0.2.1 |
| Data Center | 10.0.3.0/24  | 255.255.255.0   | 10.0.3.0 | 10.0.3.1 | 10.0.3.254  | 10.0.3.255 | 10.0.3.1 |
| Visitas     | 10.0.4.0/24  | 255.255.255.0   | 10.0.4.0 | 10.0.4.1 | 10.0.4.254  | 10.0.4.255 | 10.0.4.1 |

#### 3.4 Nomenclatura y etiquetas

**VPC:** vpc-startup-x

- **Región:** us-central1 (o la que usaron en Terraform)
- **Subredes (name):**
  - subnet-ventas-uscentral1 (10.0.1.0/24)
  - subnet-ti-uscentral1 (10.0.2.0/24)
  - subnet-dc-uscentral1 (10.0.3.0/24)
  - subnet-visitas-uscentral1 (10.0.4.0/24)
- **Labels/Tags:** role=ventas|ti|dc|visitas

#### 3.5 Plan de asignación de direcciones

- **DHCP:** GCP asigna IPs privadas automáticamente; no se configura servidor propio en Fase 1.
- **Estáticos (Data Center):** reservar rangos para servidores/servicios críticos (p.ej., 10.0.3.10–10.0.3.50).
- **Dinámicos:** usuarios de Ventas/TI y clientes de Visitas (vía DHCP de GCP).
- **Ejemplos de reservas:** impresoras en Ventas (10.0.1.210–219) y TI (10.0.2.210–219).

#### 3.6 Política de comunicación entre subredes

| Desde / Hacia | Ventas | TI | Data Center | Visitas |
|---------------|--------|-------|-------------|---------|
| **Ventas**    | ✅     | ✅    | 🚫          | 🚫      |
| **TI**        | ✅     | ✅    | ✅          | 🚫      |
| **Data Center**| 🚫    | ✅    | ✅          | 🚫      |
| **Visitas**   | 🚫     | 🚫    | 🚫          | ✅      |

**Criterio:**
- TI da soporte a todos los segmentos (acceso a Ventas y DC).
- Ventas solo requiere soporte de TI; no accede directo a DC.
- Visitas totalmente aisladas de redes internas (solo salida a Internet).

**Pruebas mínimas asociadas:**
- Ping intra-Ventas (debe responder).
- Ping TI → DC (debe responder).
- Ping Ventas → DC (debe bloquearse).
- Ping Visitas → (cualquier interno) (debe bloquearse).

### Implementación de la segmentación

**Paso 1:** Crear proyecto en Google Cloud y copiar Project ID para reemplazarlo en el archivo terraform.tfvars

**Paso 2:** Ejecutar comando `terraform init` para iniciar proyecto

**Paso 3:** Ejecutar comando `terraform plan` para visualizar los cambios y la infraestructura que se creara en GCP.

**Paso 4:** Ejecutar comando `terraform apply` para crear la infraestructura

**Paso 5:** Este mensaje indica que los recursos se crearon correctamente

**Paso 6:** Verificar en GCP que la VPC con subredes se creó correctamente

### Pruebas y archivos de configuración

Realizar pruebas de conectividad básica (ejemplo: ping entre dos instancias).
Guardar screenshots de los pings exitosos.
Organizar los archivos de configuración y cualquier documentación adicional.
Escribir la sección de "Resultados" en el documento.

**Paso 1:** Crear archivo de configuracion en terraform para crear instancia de prueba y ejecutar el comando terraform apply

**Paso 2:** Ejecutar comando `terraform show` para verificar que las instancias se crearon correctamente

**Paso 3:** Ejecutar comando con script automatizado de pruebas: `./test-connectivity.sh`

**Paso 4:** Verificar que el resultado de las pruebas fue exitoso

---

## Fase 2 – Implementación de una Red en la nube

### DNS + apoyo en integración con Web Interno

1. Implementar el servidor DNS interno.

### Directorio OpenLDAP

Implementamos un directorio OpenLDAP para centralizar usuarios de RRHH y Ventas, integramos las VMs cliente con SSSD/NSS/PAM y controlamos el acceso SSH únicamente a los grupos autorizados mediante AllowGroups. Validamos el servicio LDAP activo, la base de datos (dc=x,dc=local), la existencia de OUs/usuarios, la resolución de identidades desde cliente y el bloqueo de inicios de sesión no autorizados.

#### Lo realizado:

1. Instalamos y configuramos OpenLDAP en la VM de DC, definiendo el dominio base dc=x,dc=local y credenciales de administración. Evidenciamos el servicio slapd activo y el namingContext correcto.

2. Construimos la estructura LDAP con OU de rrhh y ventas y usuarios (atributos POSIX) cargados vía LDIF. Verificamos los DN y atributos con ldapsearch.

3. Integramos clientes con SSSD/NSS/PAM, dejando sssd habilitado y en ejecución y confirmando que las identidades se resuelven desde LDAP con id/getent.

4. Restringimos SSH por grupos en sshd_config con AllowGroups para permitir solo rrhh/ventas/ti-admins y probamos un intento de acceso no autorizado que resultó en denegación.

#### Evidencia:

- **LDAP operativo (VM LDAP)** — systemctl status slapd active (running)

- **Base y namingContexts + puerto 389 (VM LDAP)** — ss -lptn | grep 389 y ldapsearch -s base -b '' namingContexts (dc=x,dc=local).

- **Estructura creada (OUs y grupos) (VM LDAP)** — ldapadd -f /root/ou.ldif con adding new entry "ou=rrhh"/"ou=ventas" (y cn de grupos).

- **Usuarios cargados y visibles (VM LDAP)** — ldapsearch -x -b "dc=x,dc=local" "(uid=*)" dn uidNumber gidNumber (user1–user4)

- **Cliente integrado (VM cliente)** — systemctl status sssd active (running).

- **SSH permitido (usuario autorizado) (desde PC/cliente)** — sesión OK para user1 mostrando whoami, id, groups (rrhh, ti-admins).

### Servidor Web Interno (Lógica del negocio)

1. **Instalar y configurar el servidor web interno.**
   - Puede usar Apache o Nginx.

2. **Asignar el dominio interno:**

### Seguridad y Control de Acceso (Firewall, ACL y NAT)

*(Detalles de implementación de reglas de firewall)*

---

## Fase 3 - Implementación de Servicios Públicos, Seguridad y Monitoreo en la Nube

### Infraestructura pública, DMZ y Web público (Isa)

#### Responsabilidades principales

1. **Diseñar y crear la DMZ en GCP**
   - Nueva subred (subnet-dmz-uscentral1).
   - Configuración de rutas, tags y firewalls base.
   - Aislamiento de la DMZ respecto a la red interna.

2. **Implementar el servidor web público**
   - Crear VM en la DMZ.
   - Instalar Apache o Nginx.
   - Deploy de la página estática del negocio.

3. **Configurar el dominio público**
   - Compra del dominio (si aplica).
   - Crear registros A / CNAME apuntando al servidor web público.

4. **Configurar HTTPS**
   - Instalar Certbot (Let's Encrypt).
   - Obtener certificados SSL/TLS.
   - Configurar redirección de HTTP → HTTPS.
   - Probar accesibilidad desde Internet.

#### Entregables

- VM funcional en DMZ.
- Página accesible vía dominio propio.
- HTTPS funcionando con certificados válidos.
- Documentación y evidencia con screenshots.

### Seguridad y Firewall (Ruth)

#### Responsabilidades principales

1. **Reglas de firewall para la DMZ**
   - Permitir solo 80/443 desde Internet.
   - Aísla la DMZ de las redes internas (excepto TI).
   - Bloquear acceso directo de Ventas/Visitas al servidor público.

2. **Reglas para la VPN**
   - Abrir puertos necesarios según el software (OpenVPN, WireGuard, etc.).
   - Permitir tráfico de clientes VPN hacia redes internas permitidas.

3. **Reglas de seguridad internas**
   - Ajustar ACLs / NAT para soportar la DMZ y la VPN.
   - Revisar conectividad del web público al LDAP si se requiere (solo autenticación administrativa).

4. **Hardening general**
   - Deshabilitar servicios innecesarios.
   - Configurar rate limiting para evitar ataques.

#### Entregables

- Tabla de reglas de firewall antes/después.
- Evidencias de pruebas: accesos permitidos/bloqueados.
- Documentación actualizada del diagrama de comunicación.

### VPN con autenticación LDAP

#### Responsabilidades principales

1. **Seleccionar tecnología de VPN**
   - OpenVPN / WireGuard / StrongSwan.
   - Debe ser compatible con LDAP.

2. **Implementar el servidor VPN**
   - Instalar software en una VM (recomendado: subnet TI o DMZ interna).
   - Configurar puertos y servicio.

3. **Integración de la VPN con el OpenLDAP de la Fase 2**
   - Autenticación mediante usuarios de rrhh/ventas.
   - Pruebas: autenticación exitosa y fallida.

4. **Configurar rutas y acceso**
   - Que los usuarios conectados puedan acceder solo a sus redes.
   - Lograr acceso seguro desde fuera a sus instancias internas.

#### Entregables

- Evidencias del login vía LDAP.
- Clientes VPN funcionando desde la red externa.
- Diagramas de flujo de autenticación.

### SNMP + Monitoreo + Documentación final (Angel)

#### Responsabilidades principales

1. **Implementar SNMP en la infraestructura**
   - Habilitar SNMPv3 (recomendado) en VMs clave.
   - Configurar usuarios, encriptación y permisos.
   - Probar consultas SNMP desde TI.

2. **(Opcional, +10%) Implementación de interfaz gráfica**
   - Zabbix, Grafana + SNMP exporter, o Nautilus.
   - Accesible solo desde TI.

3. **Monitoreo básico**
   - Uptime.
   - Latencia.
   - Uso de red y CPU.
   - Disponibilidad de servicios críticos (VPN / Web).

4. **Documentación del proyecto**
   - Diagrama final actualizado (Fase 3).
   - Resumen técnico de cada servicio.
   - Preparar evidencia para defensa del proyecto.

#### Entregables

- SNMP funcionando.
- Panel básico si hacen la parte opcional.
- Documentación final para el PDF entregable.
- Diagrama actualizado.

---

**GITHUB:** https://github.com/aherrarte2019037/vpc-network
