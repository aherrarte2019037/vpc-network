# main.tf
# Configuración principal de la red empresarial en GCP

# VPC Network Principal
resource "google_compute_network" "main_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC principal para la empresa - Proyecto Redes"
}

# Subred DMZ
resource "google_compute_subnetwork" "dmz_subnet" {
  name          = "subnet-dmz-uscentral1"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.main_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Subred de Ventas - 10.0.0.64/27
resource "google_compute_subnetwork" "ventas_subnet" {
  name          = "subnet-ventas-uscentral1-v2"
  ip_cidr_range = "10.0.0.64/27"
  region        = var.region
  network       = google_compute_network.main_vpc.id
  # description comentado para evitar reemplazo forzado (hay instancias usando esta subred)
  # description   = "Subred para el equipo de Ventas (25 hosts)"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Subred de TI - 10.0.0.96/27
resource "google_compute_subnetwork" "ti_subnet" {
  name          = "subnet-ti-uscentral1-v2"
  ip_cidr_range = "10.0.0.96/27"
  region        = var.region
  network       = google_compute_network.main_vpc.id
  # description comentado para evitar reemplazo forzado (hay instancias usando esta subred)
  # description   = "Subred para el equipo de TI (15 hosts)"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Subred de Data Center - 10.0.0.128/28
resource "google_compute_subnetwork" "datacenter_subnet" {
  name          = "subnet-dc-uscentral1-v2"
  ip_cidr_range = "10.0.0.128/28"
  region        = var.region
  network       = google_compute_network.main_vpc.id
  # description comentado para evitar reemplazo forzado (hay instancias usando esta subred)
  # description   = "Subred para Data Center (5 servidores)"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Subred de Visitas - 10.0.0.0/26
resource "google_compute_subnetwork" "visitas_subnet" {
  name          = "subnet-visitas-uscentral1-v2"
  ip_cidr_range = "10.0.0.0/26"
  region        = var.region
  network       = google_compute_network.main_vpc.id
  # description comentado para evitar reemplazo forzado
  # description   = "Subred para visitantes (acceso limitado)"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}



# =============================================================================
# REGLAS DE FIREWALL - FASE 1 (DEPRECADAS)
# =============================================================================
# Las reglas de firewall de la Fase 1 han sido reemplazadas por reglas más
# específicas en firewall-rules.tf para cumplir con los requisitos de la Fase 2.
# Estas reglas antiguas se mantienen comentadas por referencia histórica.

# # Regla de Firewall: Permitir tráfico interno entre todas las subredes
# # DEPRECADA: Reemplazada por allow-internal-authorized en firewall-rules.tf
# resource "google_compute_firewall" "allow_internal" {
#   name    = "allow-internal-traffic"
#   network = google_compute_network.main_vpc.name
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["0-65535"]
#   }
# 
#   allow {
#     protocol = "udp"
#     ports    = ["0-65535"]
#   }
# 
#   allow {
#     protocol = "icmp"
#   }
# 
#   source_ranges = [
#     "10.0.0.64/27", # Ventas
#     "10.0.0.96/27", # TI
#     "10.0.0.128/28", # Data Center
#     "10.0.0.0/26"  # Visitas
#   ]
# 
#   description = "Permite todo el tráfico interno entre subredes"
# }

# # Regla de Firewall: Permitir SSH desde cualquier lugar (para pruebas)
# # DEPRECADA: Reemplazada por reglas específicas de SSH en firewall-rules.tf
# resource "google_compute_firewall" "allow_ssh" {
#   name    = "allow-ssh"
#   network = google_compute_network.main_vpc.name
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
# 
#   source_ranges = ["0.0.0.0/0"]
#   description   = "Permite SSH desde cualquier ubicación"
# }

# # Regla de Firewall: Permitir ICMP (ping) desde cualquier lugar
# # NOTA: Se mantiene ICMP permitido en reglas internas, pero restringido desde Internet
# resource "google_compute_firewall" "allow_icmp" {
#   name    = "allow-icmp"
#   network = google_compute_network.main_vpc.name
# 
#   allow {
#     protocol = "icmp"
#   }
# 
#   source_ranges = ["0.0.0.0/0"]
#   description   = "Permite ping desde cualquier ubicación"
# }

# # Regla de Firewall: Permitir HTTP/HTTPS desde Internet
# # DEPRECADA: Reemplazada por reglas específicas para web interno en firewall-rules.tf
# resource "google_compute_firewall" "allow_http_https" {
#   name    = "allow-http-https"
#   network = google_compute_network.main_vpc.name
# 
#   allow {
#     protocol = "tcp"
#     ports    = ["80", "443"]
#   }
# 
#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["web-server"]
#   description   = "Permite tráfico HTTP/HTTPS desde Internet"
# }

# # Regla de Firewall: Restringir acceso de Visitas
# # DEPRECADA: Reemplazada por reglas más restrictivas en firewall-rules.tf
# resource "google_compute_firewall" "restrict_visitas" {
#   name     = "restrict-visitas-to-internal"
#   network  = google_compute_network.main_vpc.name
#   priority = 1000
# 
#   deny {
#     protocol = "tcp"
#   }
# 
#   deny {
#     protocol = "udp"
#   }
# 
#   source_ranges = ["10.0.0.0/26"] # Subred de Visitas
#   destination_ranges = [
#     "10.0.0.96/27", # TI
#     "10.0.0.128/28"  # Data Center
#   ]
# 
#   description = "Niega acceso de la red de Visitas a TI y Data Center"
# }

# Cloud Router para NAT (necesario para que las instancias sin IP pública accedan a Internet)
resource "google_compute_router" "router" {
  name    = "main-router"
  region  = var.region
  network = google_compute_network.main_vpc.id

  bgp {
    asn = 64514
  }
}

# Cloud NAT para permitir salida a Internet
# Fase 2: Configurado para todas las subredes, incluyendo Visitas
# Esto permite que Visitas acceda a Internet pero no a subredes internas
resource "google_compute_router_nat" "nat" {
  name                               = "main-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

  # Nota: description no está soportado en google_compute_router_nat
  # Fase 2: NAT para todas las subredes - permite que Visitas acceda a Internet
}
