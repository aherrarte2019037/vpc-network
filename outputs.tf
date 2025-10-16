# outputs.tf
# Outputs que muestran información relevante después del despliegue

output "vpc_name" {
  description = "Nombre de la VPC creada"
  value       = google_compute_network.main_vpc.name
}

output "vpc_id" {
  description = "ID de la VPC creada"
  value       = google_compute_network.main_vpc.id
}

output "subred_ventas" {
  description = "Información de la subred de Ventas"
  value = {
    name       = google_compute_subnetwork.ventas_subnet.name
    cidr       = google_compute_subnetwork.ventas_subnet.ip_cidr_range
    gateway    = google_compute_subnetwork.ventas_subnet.gateway_address
    region     = google_compute_subnetwork.ventas_subnet.region
  }
}

output "subred_ti" {
  description = "Información de la subred de TI"
  value = {
    name       = google_compute_subnetwork.ti_subnet.name
    cidr       = google_compute_subnetwork.ti_subnet.ip_cidr_range
    gateway    = google_compute_subnetwork.ti_subnet.gateway_address
    region     = google_compute_subnetwork.ti_subnet.region
  }
}

output "subred_datacenter" {
  description = "Información de la subred de Data Center"
  value = {
    name       = google_compute_subnetwork.datacenter_subnet.name
    cidr       = google_compute_subnetwork.datacenter_subnet.ip_cidr_range
    gateway    = google_compute_subnetwork.datacenter_subnet.gateway_address
    region     = google_compute_subnetwork.datacenter_subnet.region
  }
}

output "subred_visitas" {
  description = "Información de la subred de Visitas"
  value = {
    name       = google_compute_subnetwork.visitas_subnet.name
    cidr       = google_compute_subnetwork.visitas_subnet.ip_cidr_range
    gateway    = google_compute_subnetwork.visitas_subnet.gateway_address
    region     = google_compute_subnetwork.visitas_subnet.region
  }
}

output "router_name" {
  description = "Nombre del Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Nombre del Cloud NAT"
  value       = google_compute_router_nat.nat.name
}

output "firewall_rules" {
  description = "Reglas de firewall creadas"
  value = [
    google_compute_firewall.allow_internal.name,
    google_compute_firewall.allow_ssh.name,
    google_compute_firewall.allow_icmp.name,
    google_compute_firewall.allow_http_https.name,
    google_compute_firewall.restrict_visitas.name
  ]
}
