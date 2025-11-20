## Script de pruebas paso a paso 

> ⚠️ Esto NO instala nada, solo verifica lo que ya configuraste.
> Incluye: dónde ejecutar, comandos, evidencia y resultado esperado.

---

### PRUEBA 1 – Estado del servidor OpenVPN y logs básicos

**Objetivo:** comprobar que el servicio VPN está arriba y escribiendo logs.

**1.1. Ver estado del servicio**

* 📍 **Dónde ejecutar:** `vpn-server` (VM TI) – sesión SSH

* 🧾 **Comando:**

  ```bash
  sudo -i
  systemctl status openvpn-server@server --no-pager | head -15
  ```

* ✅ **Resultado esperado:**

  * `Active: active (running)`
  * Línea con `Initialization Sequence Completed`.

* 📸 **Evidencia:** captura de la salida del `systemctl`.

---

**1.2. Ver que está escuchando en el puerto 1194/UDP**

* 📍 **Dónde:** `vpn-server`

* 🧾 **Comando:**

  ```bash
  ss -lunpt | grep 1194
  ```

* ✅ **Resultado esperado:**
  Línea similar a:

  ```text
  udp   UNCONN 0 0 0.0.0.0:1194  0.0.0.0:* users:(("openvpn",pid=...,fd=...))
  ```

* 📸 **Evidencia:** captura del comando con el puerto escuchando.

---

### PRUEBA 2 – Autenticación directa contra LDAP via script

**Objetivo:** demostrar que el script `/etc/openvpn/auth/ldap-auth.sh` valida usuario/clave contra OpenLDAP.

**2.1. Ejecutar el script con usuario válido**

* 📍 **Dónde:** `vpn-server` (root)

* 🧾 **Comandos:**

  ```bash
  sudo -i
  export username=user1
  export password='User123'   # contraseña real de user1
  /etc/openvpn/auth/ldap-auth.sh
  echo "Código de salida: $?"
  ```

* ✅ **Resultado esperado:**

  * `Código de salida: 0`

**2.2. Revisar log de autenticación LDAP**

* 📍 **Dónde:** `vpn-server` (root)

* 🧾 **Comando:**

  ```bash
  tail -n 10 /var/log/openvpn/auth-ldap.log
  ```

* ✅ **Resultado esperado:**
  Últimas líneas algo como:

  ```text
  ... - Intento de login: usuario=user1 desde OpenVPN
  Autenticación EXITOSA para user1 (DN=uid=user1,ou=rrhh,dc=x,dc=local)
  ```

* 📸 **Evidencia:**

  * Salida del comando con `Código de salida: 0`.
  * Log mostrando la autenticación EXITOSA y el DN.

---

### PRUEBA 3 – Login EXITOSO desde un cliente OpenVPN (Windows)

**Objetivo:** comprobar que un cliente externo puede conectarse usando credenciales LDAP.

**3.1. Conexión desde OpenVPN GUI**

* 📍 **Dónde ejecutar:** **Cliente Windows** (tu laptop)

1. Abrir **OpenVPN GUI**.
2. Click derecho en el ícono → seleccionar perfil `client1`.
3. Click en **Connect**.
4. En el prompt:

   * Usuario: `user1`
   * Contraseña: `User123`.

* ✅ **Resultado esperado:**
  Ventana de OpenVPN GUI muestra:

  * `Estado actual: Conectado.`
  * `IP asignada: 10.8.0.2`
  * Mensaje `Initialization Sequence Completed`.

* 📸 **Evidencia:** captura de la ventana de OpenVPN GUI conectada.

---

**3.2. Confirmar autenticación LDAP en los logs**

* 📍 **Dónde:** `vpn-server` (root)

* 🧾 **Comandos:**

  ```bash
  tail -n 10 /var/log/openvpn/auth-ldap.log
  tail -n 20 /var/log/openvpn/openvpn.log
  ```

* ✅ **Resultado esperado:**

  * En `auth-ldap.log`:

    ```text
    ... Intento de login: usuario=user1 desde OpenVPN
    Autenticación EXITOSA para user1 (DN=uid=user1,ou=rrhh,dc=x,dc=local)
    ```

  * En `openvpn.log`:

    ```text
    TLS: Username/Password authentication succeeded for username 'user1'
    [user1] Peer Connection Initiated ...
    ... pool returned IPv4=10.8.0.2 ...
    ```

* 📸 **Evidencia:** capturas de ambos `tail`.

---

### PRUEBA 4 – Login FALLIDO (credenciales incorrectas)

**Objetivo:** demostrar que la VPN **rechaza** credenciales inválidas (requisito del enunciado).

**4.1. Intentar conexión con contraseña incorrecta**

* 📍 **Dónde:** Cliente Windows

1. Desconéctate si estás conectado (botón **Desconectar**).
2. Click derecho en OpenVPN GUI → **Connect**.
3. Usuario: `user1`
4. Contraseña: algo incorrecto, por ejemplo `User1234`.

* ✅ **Resultado esperado:**
  OpenVPN GUI muestra error de autenticación (`AUTH_FAILED` / “wrong credentials”).

* 📸 **Evidencia:** captura de la ventana con el error.

---

**4.2. Ver logs de intento fallido**

* 📍 **Dónde:** `vpn-server` (root)

* 🧾 **Comandos:**

  ```bash
  tail -n 10 /var/log/openvpn/auth-ldap.log
  tail -n 20 /var/log/openvpn/openvpn.log
  ```

* ✅ **Resultado esperado:**

  * En `auth-ldap.log`:

    ```text
    ... Intento de login: usuario=user1 desde OpenVPN
    Autenticación FALLIDA para user1
    ```

  * En `openvpn.log`:

    ```text
    ... SENT CONTROL [UNDEF]: 'AUTH_FAILED' (status=1)
    ```

* 📸 **Evidencia:** capturas de los dos logs mostrando el fallo.

---

### PRUEBA 5 – Conectividad desde el cliente a la red interna

**Objetivo:** verificar que, una vez autenticado, el cliente accede a la red 10.0.0.0/16.

> Antes de esta prueba, vuelve a conectarte con credenciales correctas (`user1` / `User123`).

---

**5.1. Ver IP de la VPN en el cliente**

* 📍 **Dónde:** Cliente Windows – `PowerShell` o `cmd` en el proyecto

* 🧾 **Comando:**

  ```bat
  ipconfig
  ```

* ✅ **Resultado esperado:**
  Adaptador `OpenVPN Data Channel Offload` con:

  ```text
  Dirección IPv4. . . . . . : 10.8.0.2
  Máscara de subred . . . . : 255.255.255.0
  ```

* 📸 **Evidencia:** captura de ese bloque de `ipconfig`.

---

**5.2. Ping al gateway de la VPN**

* 📍 **Dónde:** Cliente Windows

* 🧾 **Comando:**

  ```bat
  ping 10.8.0.1
  ```

* ✅ **Resultado esperado:**

  ```text
  Respuesta desde 10.8.0.1: bytes=32 tiempo=XXXms TTL=64
  (0% perdidos)
  ```

* 📸 **Evidencia:** captura del ping.

---

**5.3. Ping a la IP interna del `vpn-server`**

* 📍 **Dónde:** Cliente Windows

* 🧾 **Comando:**

  ```bat
  ping 10.0.0.107
  ```

* ✅ **Resultado esperado:** respuestas con 0% pérdida.

* 📸 **Evidencia:** captura del ping.

---

**5.4. Ping al `ldap-server` en la subred DC**

* 📍 **Dónde:** Cliente Windows

* 🧾 **Comando:**

  ```bat
  ping 10.0.0.131
  ```

* ✅ **Resultado esperado:** respuestas correctas desde 10.0.0.131.

* 📸 **Evidencia:** captura del ping.

---

**5.5. Ver tabla de rutas (opcional pero recomendado para el informe)**

* 📍 **Dónde:** Cliente Windows

* 🧾 **Comando:**

  ```bat
  route print
  ```

* ✅ **Resultado esperado:**
  Rutas activas que incluyan:

  ```text
  10.0.0.0   255.255.255.192   10.8.0.1   10.8.0.2  ...
  10.0.0.64  255.255.255.224   10.8.0.1   10.8.0.2  ...
  ...
  ```

* 📸 **Evidencia:** captura parcial donde se vean las rutas 10.0.0.x usando la interfaz 10.8.0.2.


