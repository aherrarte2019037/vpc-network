#!/bin/bash
set -eux

# Instalar Apache
apt-get update
apt-get install -y apache2

# Crear página HTML básica para RRHH
mkdir -p /var/www/html
cat > /var/www/html/index.html <<'HTML_EOF'
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sistema de Administración de RRHH</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        p {
            color: #555;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Sistema de Administración de RRHH</h1>
        <p>Bienvenido al sistema interno de Recursos Humanos</p>
        <p>Este servidor es accesible únicamente desde dentro de la red interna.</p>
    </div>
</body>
</html>
HTML_EOF

# Configurar Apache para escuchar en todas las interfaces
sed -i 's/Listen 80/Listen 0.0.0.0:80/' /etc/apache2/ports.conf

# Habilitar y reiniciar Apache
systemctl enable apache2
systemctl restart apache2

# Verificar que está corriendo
systemctl status apache2 --no-pager | head -5

