# Universidad del Valle de Guatemala
## Facultad de Ingeniería
## Departamento de Ciencias de la Computación
## CC3067 Redes

# Proyecto Final: Fase 3
## Implementación de una Red y sus servicios en la nube

## 1. Antecedentes

Los retos que conlleva construir una red que se adapte a las necesidades del negocio y que funcione correctamente solo pueden ser sobrepasados en la práctica.

## 2. Objetivos

- Conocer el funcionamiento de una DMZ, la exposición de servicios al público y las consideraciones de seguridad y administración que conlleva.
- Aplicar los protocolos aprendidos durante el curso y de forma autodidacta en su infraestructura de red en la nube.

## 3. Desarrollo

La empresa "X" está satisfecha con los servicios implementados para el manejo interno de su gestión y ahora necesita la implementación de servicios que le permitan tener presencia en el Internet, así como la administración de su red interna.

### Administración de la red

- El equipo de telecomunicaciones requiere la implementación del protocolo SNMP para monitorear la salud de la red. (Opcional/Extra: implementar alguna herramienta gráfica/GUI para monitorear y graficar/visualizar la información SNMP, como Nautilus, Grafana, etc., accesible solamente por IT [10% extra])

### Lógica del negocio

- El departamento de ventas requiere que haya un servidor web público donde los clientes puedan realizar sus compras, al cual se debe acceder mediante un dominio público (El dominio público y el diseño de la página quedan a criterio propio, puede ser una página estática, recuerden que no es curso de Web).

### Seguridad

- Debido a que algunos trabajadores de la empresa necesitan conectarse desde sus hogares a sus instancias de trabajo, el equipo de seguridad le solicita la implementación de una VPN que le permita a dichos trabajadores conectarse de una forma segura. La VPN debe utilizar la autenticación del LDAP implementado en la fase anterior.
- Se debe implementar una Zona Desmilitarizada o DMZ. En este segmento de red se colocarán los servicios que deben estar accesibles al público.
- El servidor web público debe contar con certificados SSL/TLS y se debe acceder solamente mediante "https" (sugerencia, leer sobre Certbot de Let's Encrypt). Cualquier intento de acceso mediante "http" debe redirigirse hacia "https".
- Se deben realizar las modificaciones necesarias al Firewall para que soporte los nuevos requerimientos de la empresa.

### **Nota:**

1. Algunas plataformas ofrecen servicios para los protocolos solicitados. Puede optar por utilizar dichos servicios, o configurarlos manualmente en una instancia.

2. La página Web pública puede no tener funcionalidad alguna (i.e., estática). Debe ser accesible mediante un nombre de dominio que se debe adquirir. Dominios baratos existen varios. Por ejemplo, redesuvg.cloud se compró en (https://www.namecheap.com) y tuvo un costo de $2 (dura un año). Si lo adquieren en namecheap se sugieren dos cosas:
   1. Buscar un TLD barato, como lo es .lol, .xyz, etc. Dominios más populares como .com y .net suelen tener un costo más elevado.
   2. Desactivar la opción de "auto renewal", para evitar que en un año les cobren la renovación. La renovación suele ser mucho más cara que la compra; esto lo hacen las empresas para generar un "lock-in" (por ejemplo, renovar redesuvg.cloud cuesta aproximadamente $23).
   3. Si no lo adquieren en namecheap, procurar tomar las precauciones necesarias para evitar auto cobros y renovación

3. El día de la entrega se realizarán preguntas a todos los integrantes, sobre **cualquiera** de los servicios/protocolos implementados en el **proyecto y vistos en el curso**. Estas preguntas conforman la nota individual (15%) y pueden ser teóricas/prácticas.

4. **Esta fase incluirá evaluación anónima entre los integrantes de cada equipo. La distribución de trabajo y responsabilidades queda a discreción de cada equipo.**

## 4. Entregables

- Diagrama de red actualizado con los nuevos componentes y servicios.
- Se puede añadir los nuevos componentes al reporte que han manejado y entregado antes, pero es opcional (mejor si se enfocan en una buena implementación y luego documentan).
- Fecha de entrega: **20 de Noviembre**
  - **Ese día se realizarán las pruebas de los servicios en vivo**

## 5. Presentación y valoración del Proyecto

### Rúbrica

El proyecto consistirá en 3 fases.

| Fase    | Evaluación                              | Porcentaje |
|---------|-----------------------------------------|------------|
| Fase 1  | Nota grupal                             | 25%        |
| Fase 2  | Nota grupal                             | 35%        |
| Fase 3  | Nota grupal (25%) e individual (15%)    | 40%        |
