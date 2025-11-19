#########################################
# VPC PRINCIPAL
#########################################
resource "google_compute_network" "main_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "VPC principal para el proyecto empresarial"
}

#########################################
# SUBRED DMZ
#########################################
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

#########################################
# SUBRED VENTAS (10.0.0.64/27)
#########################################
resource "google_compute_subnetwork" "ventas_subnet" {
  name          = "subnet-ventas-uscentral1-v2"
  ip_cidr_range = "10.0.0.64/27"
  region        = var.region
  network       = google_compute_network.main_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

#########################################
# SUBRED TI (10.0.0.96/27)
#########################################
resource "google_compute_subnetwork" "ti_subnet" {
  name          = "subnet-ti-uscentral1-v2"
  ip_cidr_range = "10.0.0.96/27"
  region        = var.region
  network       = google_compute_network.main_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

#########################################
# SUBRED DATA CENTER (10.0.0.128/28)
#########################################
resource "google_compute_subnetwork" "datacenter_subnet" {
  name          = "subnet-dc-uscentral1-v2"
  ip_cidr_range = "10.0.0.128/28"
  region        = var.region
  network       = google_compute_network.main_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

#########################################
# SUBRED VISITAS (10.0.0.0/26)
#########################################
resource "google_compute_subnetwork" "visitas_subnet" {
  name          = "subnet-visitas-uscentral1-v2"
  ip_cidr_range = "10.0.0.0/26"
  region        = var.region
  network       = google_compute_network.main_vpc.id

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

#########################################
# CLOUD ROUTER (PARA NAT)
#########################################
resource "google_compute_router" "router" {
  name    = "main-router"
  region  = var.region
  network = google_compute_network.main_vpc.id

  bgp {
    asn = 64514
  }
}

#########################################
# CLOUD NAT (PERMITE SALIDA A INTERNET)
#########################################
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
