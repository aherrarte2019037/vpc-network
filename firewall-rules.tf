# firewall-rules.tf
# Reglas de firewall completas para la VPC "vpc-network"
# Implementado por: Angel Herrarte

# Variables locales para rangos de subredes
locals {
  visitas_cidr    = "10.0.0.0/26"
  ventas_cidr     = "10.0.0.64/27"
  ti_cidr         = "10.0.0.96/27"
  datacenter_cidr = "10.0.0.128/28"

  internal_subnets = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr
  ]

  authorized_subnets = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr
  ]
}

# =============================================================================
# 1. DNS
# =============================================================================
resource "google_compute_firewall" "allow_dns_internal" {
  name         = "allow-dns-internal"
  network      = google_compute_network.main_vpc.name
  priority     = 500

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges      = local.internal_subnets
  destination_ranges = [local.datacenter_cidr]
  target_tags        = ["dns-server"]
  description        = "Permite acceso DNS interno"
}

resource "google_compute_firewall" "deny_dns_from_visitas" {
  name         = "deny-dns-from-visitas"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
    ports    = ["53"]
  }

  deny {
    protocol = "udp"
    ports    = ["53"]
  }

  source_ranges      = [local.visitas_cidr]
  destination_ranges = [local.datacenter_cidr]
  target_tags        = ["dns-server"]
  description        = "Bloquea DNS desde visitas"
}

# =============================================================================
# 2. HTTP/HTTPS DMZ
# =============================================================================
resource "google_compute_firewall" "allow_http_dmz" {
  name         = "allow-http-dmz"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dmz-web"]
  description   = "Permite HTTP desde Internet hacia DMZ"
}

resource "google_compute_firewall" "allow_https_dmz" {
  name         = "allow-https-dmz"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dmz-web"]
  description   = "Permite HTTPS desde Internet hacia DMZ"
}

resource "google_compute_firewall" "allow_http_https" {
  name         = "allow-http-https"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  description   = "Permite HTTP/HTTPS público"
}

resource "google_compute_firewall" "allow_http_internal" {
  name         = "allow-http-internal"
  network      = google_compute_network.main_vpc.name
  priority     = 900

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = local.internal_subnets
  description   = "Permite HTTP interno"
}

resource "google_compute_firewall" "allow_https_dmz2" {
  name         = "allow-https-dmz"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dmz-web"]
  description   = "Permite HTTPS DMZ"
}

resource "google_compute_firewall" "allow_http_https_dmz_server" {
  name    = "allow-http-https-dmz-server"
  network = google_compute_network.main_vpc.name
  priority = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dmz-server", "http-server", "https-server"]
  description   = "Permite HTTP/HTTPS desde Internet hacia DMZ Server"
}

# =============================================================================
# 3. SSH/IAP
# =============================================================================
resource "google_compute_firewall" "allow_iap_ssh" {
  name         = "allow-iap-ssh"
  network      = google_compute_network.main_vpc.name
  priority     = 50

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  description   = "SSH desde IAP"
}

resource "google_compute_firewall" "allow_iap_ssh_vpc_network" {
  name         = "allow-iap-ssh-vpc-network"
  network      = google_compute_network.main_vpc.name
  priority     = 50

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  description   = "SSH IAP dentro de la VPC"
}

resource "google_compute_firewall" "allow_ssh" {
  name         = "allow-ssh"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0", "35.235.240.0/20"]
  description   = "SSH global"
}

resource "google_compute_firewall" "allow_ssh_admin" {
  name         = "allow-ssh-admin"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = local.internal_subnets
  description   = "SSH admin"
}

resource "google_compute_firewall" "allow_ssh_from_iap" {
  name         = "allow-ssh-from-iap"
  network      = google_compute_network.main_vpc.name
  priority     = 800

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  description   = "SSH desde IAP"
}

resource "google_compute_firewall" "allow_ssh_from_me_no_tag_temp" {
  name         = "allow-ssh-from-me-no-tag-temp"
  network      = google_compute_network.main_vpc.name
  priority     = 50

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["181.209.195.17/32"]
  description   = "SSH desde IP temporal"
}

resource "google_compute_firewall" "allow_ssh_from_me_v2" {
  name         = "allow-ssh-from-me-v2"
  network      = google_compute_network.main_vpc.name
  priority     = 80

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["190.56.194.12/32"]
  description   = "SSH desde IP personal v2"
}

resource "google_compute_firewall" "allow_ssh_from_ti" {
  name         = "allow-ssh-from-ti"
  network      = google_compute_network.main_vpc.name
  priority     = 500

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.ti_cidr]
  description   = "SSH desde TI"
}

resource "google_compute_firewall" "allow_ssh_from_ventas" {
  name         = "allow-ssh-from-ventas"
  network      = google_compute_network.main_vpc.name
  priority     = 500

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.ventas_cidr]
  description   = "SSH desde Ventas"
}

resource "google_compute_firewall" "allow-ssh-my-ip" {
  name         = "allow-ssh-my-ip"
  network      = google_compute_network.main_vpc.name
  priority     = 1000
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["2803:d100:9910:1bbc:2c78:457e:9:10c3/32"] #cambiar segun la IP PUBLICA IPV6
  target_tags   = ["dmz-server"]
  description   = "Permitir SSH desde IP específica"
}

# =============================================================================
# 4. ICMP / Tráfico interno
# =============================================================================
resource "google_compute_firewall" "allow_icmp" {
  name         = "allow-icmp"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Permite ICMP desde cualquier origen"
}

resource "google_compute_firewall" "allow_internal_traffic" {
  name         = "allow-internal-traffic"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

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

  source_ranges      = local.internal_subnets
  destination_ranges = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr,
    local.visitas_cidr
  ]

  description = "Permite todo el tráfico interno"
}

# =============================================================================
# 5. LDAP / SNMP / Otros
# =============================================================================
resource "google_compute_firewall" "allow_ldap_ingress" {
  name         = "allow-ldap-ingress"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["389"]
  }

  source_ranges = [
    local.visitas_cidr,
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr
  ]

  target_tags = ["ldap-server"]
  description = "Permite LDAP desde todas las subredes"
}

resource "google_compute_firewall" "allow_ldap_internal" {
  name         = "allow-ldap-internal"
  network      = google_compute_network.main_vpc.name
  priority     = 500

  allow {
    protocol = "tcp"
    ports    = ["389", "636"]
  }

  allow {
    protocol = "udp"
    ports    = ["389"]
  }

  source_ranges      = local.authorized_subnets
  destination_ranges = [local.datacenter_cidr]
  target_tags        = ["ldap-server"]
  description        = "LDAP interno autorizado"
}

# =============================================================================
# 9. REGLAS PARA SNMP (FASE 3)
# =============================================================================

# Permitir SNMP desde TI hacia todas las VMs monitoreadas
resource "google_compute_firewall" "allow_snmp_from_ti" {
  name    = "allow-snmp-from-ti"
  network = google_compute_network.main_vpc.name
  priority = 500

  allow {
    protocol = "udp"
    ports    = ["161"]  # SNMP
  }

  source_ranges = [local.ti_cidr]
  target_tags   = ["snmp-enabled"]

  description = "Fase 3: Permite SNMP desde TI hacia VMs monitoreadas"
}

# Bloquear SNMP desde otras subredes (solo TI puede monitorear)
# Prioridad 300 para que tenga mayor precedencia que allow-internal-authorized (400)
resource "google_compute_firewall" "deny_snmp_from_others" {
  name     = "deny-snmp-from-others"
  network  = google_compute_network.main_vpc.name
  priority = 300

  deny {
    protocol = "udp"
    ports    = ["161"]
  }

  source_ranges = [
    local.ventas_cidr,
    local.datacenter_cidr,
    local.visitas_cidr
  ]
  target_tags = ["snmp-enabled"]

  description = "Fase 3: Bloquea SNMP desde otras subredes (solo TI puede monitorear)"
}

resource "google_compute_firewall" "deny_all_dmz" {
  name         = "deny-all-dmz"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dmz-web"]
  description   = "Bloquea todo el tráfico no permitido hacia DMZ"
}

resource "google_compute_firewall" "deny_http_external" {
  name         = "deny-http-external"
  network      = google_compute_network.main_vpc.name
  priority     = 910

  deny {
    protocol = "tcp"
    ports    = ["90"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Bloquea HTTP externo no autorizado"
}

resource "google_compute_firewall" "deny_ldap_from_visitas" {
  name         = "deny-ldap-from-visitas"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
    ports    = ["389", "636"]
  }

  deny {
    protocol = "udp"
    ports    = ["389"]
  }

  source_ranges      = [local.visitas_cidr]
  destination_ranges = [local.datacenter_cidr]
  target_tags        = ["ldap-server"]
  description        = "Bloquea LDAP desde visitas"
}

resource "google_compute_firewall" "deny_non_essential_ports_from_internet" {
  name         = "deny-non-essential-ports-from-internet"
  network      = google_compute_network.main_vpc.name
  priority     = 900

  deny {
    protocol = "tcp"
    ports    = ["0-21","23-51","54-79","81-442","444-636","637-65535"]
  }

  deny {
    protocol = "udp"
    ports    = ["0-52","54-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Bloquea puertos no esenciales desde Internet"
}

resource "google_compute_firewall" "deny_others_to_ti" {
  name         = "deny-others-to-ti"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }

  deny {
    protocol = "icmp"
  }

  source_ranges      = [
    local.visitas_cidr,
    local.ventas_cidr,
    local.datacenter_cidr
  ]
  destination_ranges = [local.ti_cidr]
  description        = "Bloquea acceso a TI desde otras subredes"
}

resource "google_compute_firewall" "deny_ssh_from_internet" {
  name         = "deny-ssh-from-internet"
  network      = google_compute_network.main_vpc.name
  priority     = 900

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Bloquea SSH desde Internet"
}

resource "google_compute_firewall" "deny_ssh_from_visitas" {
  name         = "deny-ssh-from-visitas"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.visitas_cidr]
  description   = "Bloquea SSH desde visitas"
}

resource "google_compute_firewall" "deny_visitas_to_internal" {
  name         = "deny-visitas-to-internal"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
  }

  deny {
    protocol = "udp"
  }

  deny {
    protocol = "icmp"
  }

  source_ranges      = [local.visitas_cidr]
  destination_ranges = local.internal_subnets
  description        = "Bloquea visitas a subredes internas"
}

resource "google_compute_firewall" "deny_web_from_internet" {
  name         = "deny-web-from-internet"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
    ports    = ["80","443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server-internal"]
  description   = "Bloquea web desde Internet"
}

resource "google_compute_firewall" "deny_web_from_visitas" {
  name         = "deny-web-from-visitas"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  deny {
    protocol = "tcp"
    ports    = ["80","443"]
  }

  source_ranges = [local.visitas_cidr]
  target_tags   = ["web-server-internal"]
  description   = "Bloquea web desde visitas"
}

resource "google_compute_firewall" "restrict_visitas_to_internal" {
  name         = "restrict-visitas-to-internal"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

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

  source_ranges      = [local.visitas_cidr]
  destination_ranges = local.internal_subnets
  description        = "Restricción de visitas"
}

resource "google_compute_firewall" "vpc_network_allow_http" {
  name         = "vpc-network-allow-http"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Permite HTTP VPC por defecto"
}

resource "google_compute_firewall" "vpc_network_allow_https" {
  name         = "vpc-network-allow-https"
  network      = google_compute_network.main_vpc.name
  priority     = 1000

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Permite HTTPS VPC por defecto"
}


# ============================================================================
# VPN: Regla para permitir tráfico UDP 1194 hacia vpn-server
# ============================================================================
resource "google_compute_firewall" "allow_vpn_from_internet" {
  name    = "allow-vpn-from-internet"
  network = google_compute_network.main_vpc.name

  # Prioridad más alta (número más bajo) que reglas DENY generales
  priority = 500

  allow {
    protocol = "udp"
    ports    = ["1194"]
  }

  source_ranges = ["0.0.0.0/0"]

  # Solo se aplica a instancias con la etiqueta "vpn-server"
  target_tags = ["vpn-server"]

  description = "Fase 3: Permite tráfico UDP 1194 (OpenVPN) desde Internet hacia vpn-server"
}