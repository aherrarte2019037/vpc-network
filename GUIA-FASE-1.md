# GUÍA RÁPIDA DE IMPLEMENTACIÓN

## Paso 1: Preparación (5 minutos)

### Instalar Terraform
```bash
# macOS
brew install terraform

# Linux (Ubuntu/Debian)
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Instalar Google Cloud SDK
```bash
# Instalar
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Autenticarse
gcloud auth application-default login
gcloud config set project TU-PROJECT-ID
```

## Paso 2: Configuración (2 minutos)

1. Crear proyecto en [Google Cloud Console](https://console.cloud.google.com)
2. Copiar el Project ID
3. Habilitar APIs:
```bash
gcloud services enable compute.googleapis.com
```

4. Crear archivo de variables:
```bash
cp terraform.tfvars.example terraform.tfvars
```

5. Editar `terraform.tfvars` con tu Project ID:
```hcl
project_id  = "tu-proyecto-gcp-id"
region      = "us-central1"
vpc_name    = "vpc-network"
environment = "dev"
```

## Paso 3: Despliegue (3 minutos)

```bash
# Inicializar Terraform
terraform init

# Ver el plan
terraform plan

# Aplicar (crear recursos)
terraform apply
# Escribir 'yes' cuando se solicite

# Ver información de los recursos creados
terraform output
```

## Paso 4: Verificación en GCP Console

1. Ir a: https://console.cloud.google.com/networking/networks/list
2. Verificar que existe `vpc-network`
3. Ver las 4 subredes en la VPC
4. Verificar reglas de firewall

## Paso 5: Crear Instancias de Prueba (OPCIONAL)

Para las pruebas de conectividad:

```bash
# Habilitar el archivo de instancias
mv instances.tf.disabled instances.tf

# Aplicar cambios
terraform apply
# Escribir 'yes'

# Esperar ~2 minutos para que se creen las VMs
```

## Paso 6: Pruebas de Conectividad

### Opción A: Script automatizado
```bash
./test-connectivity.sh
```

### Opción B: Manual
```bash
# Conectarse a la VM de Ventas
gcloud compute ssh test-ventas-vm --zone=us-central1-a --tunnel-through-iap

# Dentro de la VM, hacer ping a TI
ping <IP_INTERNA_TI>

# Salir
exit
```

## Paso 7: Capturar Screenshots

Para el reporte:
1. Captura de la lista de subredes en GCP Console
2. Captura de las reglas de firewall
3. Captura del resultado del ping exitoso
4. Captura de los outputs de Terraform

## Limpieza (cuando termines)

```bash
# Destruir todos los recursos
terraform destroy
# Escribir 'yes'
```

## Solución de Problemas Comunes

### Error: "API not enabled"
```bash
gcloud services enable compute.googleapis.com
gcloud services enable servicenetworking.googleapis.com
```

### Error: "Permission denied"
Asegúrate de tener los permisos correctos:
```bash
gcloud projects add-iam-policy-binding TU-PROJECT-ID \
  --member="user:tu-email@gmail.com" \
  --role="roles/compute.networkAdmin"
```

### No puedo conectarme a las VMs
Usa IAP tunneling:
```bash
gcloud compute ssh NOMBRE-VM --zone=ZONA --tunnel-through-iap
```

## Comandos Útiles

```bash
# Ver estado de Terraform
terraform show

# Ver lista de recursos
terraform state list

# Ver detalles de un recurso específico
terraform state show google_compute_network.main_vpc

# Formatear código Terraform
terraform fmt

# Validar configuración
terraform validate
```

## Estimación de Costos

### Sin instancias (solo red):
- VPC y subredes: **Gratis**
- Cloud Router: **~$36/mes** ($0.05/hora)
- Cloud NAT: **~$32/mes** ($0.045/hora) + tráfico

### Con instancias e2-micro (3 VMs):
- e2-micro (3x): **~$21/mes** (~$7 cada una)
- **Total aproximado: ~$89/mes**

💡 **Tip**: Para minimizar costos durante el desarrollo, destruye los recursos cuando no los uses:
```bash
terraform destroy
```

## Créditos Gratuitos para Estudiantes

- **Google Cloud**: $300 de crédito para nuevos usuarios
- **GitHub Student Pack**: Créditos adicionales de GCP
- **Google for Education**: Créditos académicos

Registra tus créditos en: https://cloud.google.com/edu

---

**¿Necesitas ayuda?** Consulta el README.md completo o la documentación oficial de Terraform y GCP.
