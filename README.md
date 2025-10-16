# Proyecto de Red Empresarial en Google Cloud Platform

## Descripción
Este proyecto implementa una red empresarial segmentada en Google Cloud Platform utilizando Terraform como Infrastructure as Code (IaC).

## Arquitectura de Red

### Segmentación
| Subred | CIDR | Gateway | Hosts Disponibles | Propósito |
|--------|------|---------|-------------------|-----------|
| Ventas | 10.0.1.0/24 | 10.0.1.1 | 254 | Equipo de ventas (25 personas) |
| TI | 10.0.2.0/24 | 10.0.2.1 | 254 | Equipo de TI (15 personas) |
| Data Center | 10.0.3.0/24 | 10.0.3.1 | 254 | Servidores (5 máquinas) |
| Visitas | 10.0.4.0/24 | 10.0.4.1 | 254 | Red para visitantes |

### Componentes
- **VPC**: Red privada virtual principal
- **4 Subredes**: Segmentadas por función
- **Cloud Router**: Enrutamiento regional
- **Cloud NAT**: Acceso a Internet para instancias privadas
- **Reglas de Firewall**: Control de tráfico y seguridad

## Prerequisitos

### 1. Instalar Terraform
```bash
# En Linux/macOS con Homebrew
brew install terraform

# En Linux con gestor de paquetes
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verificar instalación
terraform --version
```

### 2. Instalar Google Cloud SDK
```bash
# En Linux
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Inicializar gcloud
gcloud init

# Autenticarse
gcloud auth application-default login
```

### 3. Crear un Proyecto en GCP
1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Crear un nuevo proyecto o seleccionar uno existente
3. Anotar el `Project ID` (lo necesitarás más adelante)

### 4. Habilitar APIs necesarias
```bash
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

## Configuración

### 1. Clonar o descargar este repositorio
```bash
cd terraform-gcp-network
```

### 2. Configurar variables
```bash
# Copiar el archivo de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tu Project ID
nano terraform.tfvars
```

Contenido de `terraform.tfvars`:
```hcl
project_id  = "tu-proyecto-gcp-id"    # Reemplazar con tu Project ID
region      = "us-central1"            # Cambiar si deseas otra región
vpc_name    = "vpc-network"
environment = "dev"
```

## Despliegue

### 1. Inicializar Terraform
```bash
terraform init
```
Este comando descarga los providers necesarios (Google Cloud).

### 2. Validar la configuración
```bash
terraform validate
```

### 3. Ver el plan de ejecución
```bash
terraform plan
```
Este comando muestra todos los recursos que se crearán sin aplicar cambios.

### 4. Aplicar la configuración
```bash
terraform apply
```
- Revisar los cambios que se realizarán
- Escribir `yes` cuando se solicite confirmación
- Esperar a que se creen todos los recursos (aproximadamente 2-3 minutos)

### 5. Ver los outputs
```bash
terraform output
```
Esto mostrará información importante como:
- Nombre de la VPC
- Información de cada subred
- Reglas de firewall creadas

## Verificación

### Desde Google Cloud Console
1. Ir a [VPC Networks](https://console.cloud.google.com/networking/networks/list)
2. Verificar que existe la VPC `vpc-network`
3. Ver las 4 subredes creadas
4. Revisar las reglas de firewall en la sección de Firewall

### Desde la línea de comandos
```bash
# Listar VPCs
gcloud compute networks list

# Listar subredes
gcloud compute networks subnets list --network=vpc-network

# Listar reglas de firewall
gcloud compute firewall-rules list --filter="network:vpc-network"
```

## Estructura del Proyecto

```
terraform-gcp-network/
├── main.tf                    # Recursos principales (VPC, subredes, firewall)
├── variables.tf               # Definición de variables
├── outputs.tf                 # Outputs después del despliegue
├── provider.tf                # Configuración del provider de GCP
├── terraform.tfvars.example   # Ejemplo de variables
├── .gitignore                 # Archivos a ignorar en git
└── README.md                  # Este archivo
```

## Reglas de Firewall Implementadas

1. **allow-internal-traffic**: Permite todo el tráfico entre subredes
2. **allow-ssh**: Permite SSH (puerto 22) desde cualquier lugar
3. **allow-icmp**: Permite ping desde cualquier lugar
4. **allow-http-https**: Permite HTTP/HTTPS para servidores web
5. **restrict-visitas-to-internal**: Restringe acceso de visitas a TI y Data Center

## Costos Estimados

La configuración base (sin instancias) tiene costos mínimos:
- VPC y subredes: Gratis
- Cloud Router: ~$0.05/hora (~$36/mes)
- Cloud NAT: ~$0.045/hora + $0.045/GB procesado

**Recomendación**: Destruir la infraestructura cuando no se esté usando para evitar costos.

## Limpieza

Para destruir todos los recursos creados:

```bash
terraform destroy
```
- Confirmar escribiendo `yes`
- Esto eliminará todos los recursos creados por Terraform

## Troubleshooting

### Error: API no habilitada
```bash
gcloud services enable compute.googleapis.com
```

### Error: Permisos insuficientes
Asegúrate de que tu cuenta tiene los siguientes roles:
- Compute Network Admin
- Compute Security Admin

```bash
gcloud projects add-iam-policy-binding TU-PROJECT-ID \
  --member="user:tu-email@example.com" \
  --role="roles/compute.networkAdmin"
```

### Error: Región no válida
Listar regiones disponibles:
```bash
gcloud compute regions list
```