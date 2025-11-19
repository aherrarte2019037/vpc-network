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

output "subred_dmz" {
  description = "Información de la subred DMZ"
  value = {
    name    = google_compute_subnetwork.dmz_subnet.name
    cidr    = google_compute_subnetwork.dmz_subnet.ip_cidr_range
    gateway = google_compute_subnetwork.dmz_subnet.gateway_address
    region  = google_compute_subnetwork.dmz_subnet.region
  }
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
  description = "Reglas de firewall creadas (Fase 2)"
  value = [
    # Reglas de aislamiento
    google_compute_firewall.deny_visitas_to_internal.name,
    # Reglas de TI
    google_compute_firewall.deny_others_to_ti.name,
    # Reglas de Web
    google_compute_firewall.allow_internal_traffic.name,
    google_compute_firewall.deny_web_from_internet.name,
    google_compute_firewall.deny_web_from_visitas.name,
    # Reglas de LDAP
    google_compute_firewall.allow_ldap_internal.name,
    google_compute_firewall.deny_ldap_from_visitas.name,
    # Reglas de DNS
    google_compute_firewall.allow_dns_internal.name,
    google_compute_firewall.deny_dns_from_visitas.name,
    # Reglas de SSH
    google_compute_firewall.allow_ssh_from_ventas.name,
    google_compute_firewall.allow_ssh_from_ti.name,
    google_compute_firewall.deny_ssh_from_visitas.name,
    google_compute_firewall.deny_ssh_from_internet.name,
    # Hardening
    google_compute_firewall.deny_non_essential_ports_from_internet.name,
    # Tráfico interno
    # SNMP - Fase 3
    google_compute_firewall.allow_snmp_from_ti.name,
    google_compute_firewall.deny_snmp_from_others.name
  ]
}


# =============================================================================
# OUTPUTS DE INSTANCIAS - FASE 2
# =============================================================================

# Servidores de la Fase 2
output "dns_server_ip" {
  description = "IP interna del servidor DNS"
  value       = google_compute_instance.dns.network_interface[0].network_ip
}

output "ldap_server_ip" {
  description = "IP interna del servidor LDAP"
  value       = google_compute_instance.ldap_server.network_interface[0].network_ip
}

output "rrhh_server_ip" {
  description = "IP interna del servidor web de RRHH"
  value       = google_compute_instance.rrhh_server.network_interface[0].network_ip
}

# VMs de prueba
output "ventas_vm_internal_ip" {
  description = "IP interna de la VM de Ventas"
  value       = google_compute_instance.ventas_test.network_interface[0].network_ip
}

output "ti_vm_internal_ip" {
  description = "IP interna de la VM de TI"
  value       = google_compute_instance.ti_test.network_interface[0].network_ip
}

# Instancias de prueba opcionales
# output "datacenter_vm_internal_ip" {
#   description = "IP interna de la VM de Data Center"
#   value       = google_compute_instance.datacenter_test.network_interface[0].network_ip
# }
# 
# output "rrhh_vm_internal_ip" {
#   description = "IP interna de la VM de prueba de RRHH"
#   value       = google_compute_instance.rrhh_test.network_interface[0].network_ip
# }
