# main.tf
# Configuración principal de la red empresarial en GCP

# VPC Network Principal
resource "google_compute_network" "main_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC principal para la empresa - Proyecto Redes"
}

# Subred de Ventas - 10.0.0.64/27
resource "google_compute_subnetwork" "ventas_subnet" {
  name          = "subnet-ventas-uscentral1-v2"
  ip_cidr_range = "10.0.0.64/27"
  region        = var.region
  network       = google_compute_network.main_vpc.id
  description   = "Subred para el equipo de Ventas (25 hosts)"

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
  description   = "Subred para el equipo de TI (15 hosts)"

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
  description   = "Subred para Data Center (5 servidores)"

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
  description   = "Subred para visitantes (acceso limitado)"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Regla de Firewall: Permitir tráfico interno entre todas las subredes
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal-traffic"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "10.0.0.64/27", # Ventas
    "10.0.0.96/27", # TI
    "10.0.0.128/28", # Data Center
    "10.0.0.0/26"  # Visitas
  ]

  description = "Permite todo el tráfico interno entre subredes"
}

# Regla de Firewall: Permitir SSH desde cualquier lugar (para pruebas)
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Permite SSH desde cualquier ubicación"
}

# Regla de Firewall: Permitir ICMP (ping) desde cualquier lugar
resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Permite ping desde cualquier ubicación"
}

# Regla de Firewall: Permitir HTTP/HTTPS desde Internet
resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  description   = "Permite tráfico HTTP/HTTPS desde Internet"
}

# Regla de Firewall: Restringir acceso de Visitas
resource "google_compute_firewall" "restrict_visitas" {
  name     = "restrict-visitas-to-internal"
  network  = google_compute_network.main_vpc.name
  priority = 1000

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }

  source_ranges = ["10.0.0.0/26"] # Subred de Visitas
  destination_ranges = [
    "10.0.0.96/27", # TI
    "10.0.0.128/28"  # Data Center
  ]

  description = "Niega acceso de la red de Visitas a TI y Data Center"
}

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
}
