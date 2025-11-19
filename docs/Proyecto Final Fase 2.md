# Universidad del Valle de Guatemala
## Facultad de Ingeniería
## Departamento de Ciencias de la Computación
## CC3067 Redes

# Proyecto Final: Fase 2
## Implementación de una Red en la nube

## 1. Antecedentes

Los retos que conlleva construir una red que se adapte a las necesidades del negocio y que funcione correctamente solo pueden ser sobrepasados en la práctica.

## 2. Objetivos

- Conocer el funcionamiento de cada uno de los distintos componentes que pueden encontrarse en una red.
- Aplicar los protocolos aprendidos durante el curso en su infraestructura de red en la nube.

## 3. Desarrollo

Con el fin de comenzar a darle servicio mediante la red a las necesidades de la empresa "X," se le solicita a su equipo de trabajo la implementación de los siguientes protocolos en la infraestructura implementada en la fase 1:

**Administración de la red:** El equipo de telecomunicaciones requiere la implementación de los protocolos DNS y LDAP (Lightweight Directory Access Protocol) para manejar la administración de direcciones IP y dominios internos y acceso basado en autenticación.

**Lógica del negocio:** Recursos humanos requiere que su sistema de administración Web (una página web interna) esté disponible para todos los empleados. Este servidor debe ser únicamente accesible desde dentro de la red, no desde el Internet. Debe darsele un nombre de dominio en su DNS para acceder a la pagina por nombre y no por IP.

**Seguridad:** El equipo de seguridad de la información requiere la implementación de un Firewall y ACL, en adición al servidor LDAP para que manejen el siguiente comportamiento:

- Los usuarios de RRHH y ventas deben poder conectarse mediante SSH a sus instancias de la red, únicamente si están autorizados en el servidor LDAP.
- Toda la administración de usuarios de RRHH y ventas se debe realizar en el LDAP.
- El servidor LDAP y la web de la Intranet deben estar en el datacenter.
- La subred de visitantes debe tener acceso a Internet, pero no a ninguna de las demás subredes.
- TI tiene conectividad a cualquiera de las otras subredes, pero las demás subredes no tienen conectividad hacia TI.
- El servidor Web de la Intranet debe poder ser accesible desde las demás subredes, excepto la subred de visitas. No debe ser accesible desde el Internet.
- El firewall puede incluir funciones de NAT.
- En general: debe cerrar/bloquear puertos que no estén en uso en sus equipos/instancias/VMs/droplets (hardening)

### **Observaciones:**

- Algunas plataformas ofrecen servicios para los protocolos solicitados. Puede optar por utilizar dichos servicios, o configurarlos manualmente en una instancia.
- Puede utilizar una misma instancia para levantar algunos servicios, por ejemplo, LDAP y DNS. No es necesario una instancia dedicada para cada protocolo.
- El servidor Web Interno debe mostrar una página estática de HTML con un nombre a su elección para el sistema de RRHH. La página no necesita tener ninguna funcionalidad. Debe ser accesible únicamente mediante un nombre de dominio (i.e.: rrhh.x.com)
- **Esta es la última fase donde es posible cambiar de proveedor.**
- **Esta fase incluirá evaluación anónima entre los integrantes de cada equipo. La distribución de trabajo y responsabilidades queda a discreción de cada equipo.**

## 4. Entregables

- Diagrama de red actualizado con los nuevos servicios y componentes.
- Reporte que indique cómo se implementan los distintos servicios y requerimientos. Algunas consideraciones:
  - El reporte debe trabajarse sobre el documento entregado en la Fase 1
  - Aspectos puntuales de la implementación en su proveedor en la nube, así como la documentación consultada.
  - Screenshots evidenciando el correcto funcionamiento de los servicios levantados. Etc.
- Archivos de configuración y cualquier otra documentación que se haya utilizado
- Fecha de entrega: **6 de Noviembre**

**Ese día se realizarán las pruebas de los servicios en vivo**

## 5. Presentación y valoración del Proyecto

### 1. Rúbrica

El proyecto consistirá en 3 fases.

| Fase        | Evaluación                     | Porcentaje |
|-------------|--------------------------------|------------|
| Fase 1      | Nota grupal                    | 25%        |
| Fase 2      | Nota grupal                    | 35%        |
| Fase final  | Nota grupal e individual       | 40%        |
