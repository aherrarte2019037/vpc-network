#!/bin/bash
set -eux

# =============================================================================
# SERVIDOR WEB PÚBLICO (DMZ)
# =============================================================================

# Actualizar repositorios e instalar NGINX
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx

# Habilitar NGINX para que inicie al arrancar
systemctl enable nginx

# Iniciar servicio NGINX
systemctl start nginx

# Verificar que NGINX esté corriendo
systemctl status nginx --no-pager | head -5

# Crear página de prueba
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Servidor Web DMZ</title>
</head>
<body>
    <h1>¡Servidor Web en DMZ funcionando!</h1>
</body>
</html>
EOF

# =============================================================================
# FIN DEL SCRIPT
# =============================================================================
