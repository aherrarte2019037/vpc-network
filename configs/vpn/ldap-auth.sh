#!/bin/bash
#
# Script de autenticación LDAP para OpenVPN
# Se usa con: auth-user-pass-verify /etc/openvpn/auth/ldap-auth.sh via-env
# OpenVPN envía las variables de entorno: "username" y "password".

LOG_FILE="/var/log/openvpn/auth-ldap.log"
LDAP_URI="ldap://10.0.0.131"
BASE_DN="dc=x,dc=local"

# Variables que entrega OpenVPN
USER_NAME="${username}"
USER_PASS="${password}"

# Asegurar que el archivo de log existe y es escribible
touch "${LOG_FILE}"
chmod 666 "${LOG_FILE}" 2>/dev/null || true

echo "$(date -u) - Intento de login: usuario=${USER_NAME} desde OpenVPN" >> "${LOG_FILE}"

# Validación básica de entrada
if [ -z "${USER_NAME}" ] || [ -z "${USER_PASS}" ]; then
  echo "Credenciales vacías para usuario=${USER_NAME}" >> "${LOG_FILE}"
  echo "Autenticación FALLIDA para ${USER_NAME}" >> "${LOG_FILE}"
  exit 1
fi

# Intentar autenticar en las OUs habilitadas (RRHH y Ventas)
for OU in rrhh ventas; do
  USER_DN="uid=${USER_NAME},ou=${OU},${BASE_DN}"

  # ldapwhoami devuelve 0 si el bind (usuario/clave) es válido
  ldapwhoami -x -H "${LDAP_URI}" -D "${USER_DN}" -w "${USER_PASS}" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Autenticación EXITOSA para ${USER_NAME} (DN=${USER_DN})" >> "${LOG_FILE}"
    exit 0
  fi
done

# Si ningún bind fue exitoso, se rechaza la conexión
echo "Autenticación FALLIDA para ${USER_NAME}" >> "${LOG_FILE}"
exit 1
