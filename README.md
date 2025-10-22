# Proyecto de Red Empresarial en Google Cloud Platform

Este proyecto implementa una red empresarial segmentada en Google Cloud Platform utilizando Terraform como Infrastructure as Code (IaC).

## Arquitectura de Red

| Subred      | CIDR        | Gateway  | Hosts Disponibles | Propósito                      |
| ----------- | ----------- | -------- | ----------------- | ------------------------------ |
| Ventas      | 10.0.1.0/24 | 10.0.1.1 | 254               | Equipo de ventas (25 personas) |
| TI          | 10.0.2.0/24 | 10.0.2.1 | 254               | Equipo de TI (15 personas)     |
| Data Center | 10.0.3.0/24 | 10.0.3.1 | 254               | Servidores (5 máquinas)        |
| Visitas     | 10.0.4.0/24 | 10.0.4.1 | 254               | Red para visitantes            |

## Componentes

* **VPC**: Red privada virtual principal
* **4 Subredes**: Segmentadas por función
* **Cloud Router**: Enrutamiento regional
* **Cloud NAT**: Acceso a Internet para instancias privadas
* **Reglas de Firewall**: Control de tráfico y seguridad

## Prerequisitos (Windows)

### 1. Instalar Terraform

1. Descargar Terraform desde [Terraform Downloads](https://developer.hashicorp.com/terraform/downloads)
2. Descomprimir y agregar la ruta al PATH del sistema
3. Verificar instalación:

```powershell
terraform --version
```

### 2. Instalar Google Cloud SDK

1. Descargar instalador para Windows: [GCP SDK](https://cloud.google.com/sdk/docs/install)
2. Ejecutar instalador y seleccionar "Agregar a PATH"
3. Inicializar gcloud:

```powershell
gcloud init
```

4. Autenticarse:

```powershell
gcloud auth application-default login
```

### 3. Crear un Proyecto en GCP

1. Ir a Google Cloud Console
2. Crear un nuevo proyecto o seleccionar uno existente
3. Anotar el Project ID

### 4. Habilitar APIs necesarias

```powershell
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

## Configuración del Proyecto

1. Clonar o descargar el repositorio:

```powershell
git clone <URL_DEL_REPOSITORIO>
cd terraform-gcp-network
```

2. Configurar variables:

```powershell
copy terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

Editar `terraform.tfvars`:

```hcl
project_id  = "tu-proyecto-gcp-id"
region      = "us-central1"
vpc_name    = "vpc-network"
environment = "dev"
```

## Despliegue con Terraform

1. Inicializar Terraform:

```powershell
terraform init
```

2. Validar configuración:

```powershell
terraform validate
```

3. Ver plan de ejecución:

```powershell
terraform plan
```

4. Aplicar configuración:

```powershell
terraform apply
```

Escribir `yes` cuando se solicite confirmación. Esperar 2-3 minutos.

5. Ver outputs:

```powershell
terraform output
```

## Verificación

### Desde Google Cloud Console

* VPC Networks → Verificar VPC `vpc-network`
* Subredes → Verificar las 4 subredes
* Firewall → Revisar reglas creadas

### Desde línea de comandos

```powershell
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

* `allow-internal-traffic`: Permite tráfico entre subredes
* `allow-ssh`: Permite SSH (puerto 22) desde cualquier lugar
* `allow-icmp`: Permite ping desde cualquier lugar
* `allow-http-https`: Permite HTTP/HTTPS para servidores web
* `restrict-visitas-to-internal`: Restringe acceso de visitas a TI y Data Center

## Costos Estimados

* VPC y subredes: Gratis
* Cloud Router: $0.05/hora ($36/mes)
* Cloud NAT: ~$0.045/hora + $0.045/GB procesado

**Recomendación:** Destruir infraestructura cuando no se use.

## Limpieza

```powershell
terraform destroy
```

Confirmar escribiendo `yes`.

## Troubleshooting

* **API no habilitada:**

```powershell
gcloud services enable compute.googleapis.com
```

* **Permisos insuficientes:**

```powershell
gcloud projects add-iam-policy-binding TU-PROJECT-ID `
  --member="user:tu-email@example.com" `
  --role="roles/compute.networkAdmin"
```

* **Región no válida:**

```powershell
gcloud compute regions list
```
