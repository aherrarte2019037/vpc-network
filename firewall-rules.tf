# firewall-rules.tf
# Reglas de firewall para la Fase 2 - Seguridad y Control de Acceso
# Implementado por: Angel Herrarte

# Variables locales para rangos de subredes
locals {
  ventas_cidr     = "10.0.0.64/27"
  ti_cidr         = "10.0.0.96/27"
  datacenter_cidr = "10.0.0.128/28"
  visitas_cidr    = "10.0.0.0/26"
  
  # Subredes internas (excluyendo Visitas)
  internal_subnets = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr
  ]
  
  # Subredes que pueden acceder a servicios internos (Ventas, TI, RRHH)
  # Nota: RRHH está en Ventas o puede ser una subred adicional, asumimos Ventas
  authorized_subnets = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr
  ]
}

# =============================================================================
# 1. REGLAS DE AISLAMIENTO DE VISITAS
# =============================================================================

# Bloquear acceso de Visitas a todas las subredes internas (excepto Internet vía NAT)
resource "google_compute_firewall" "deny_visitas_to_internal" {
  name     = "deny-visitas-to-internal"
  network  = google_compute_network.main_vpc.name
  priority = 1000

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
  destination_ranges = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr
  ]

  description = "Fase 2: Bloquea completamente el acceso de Visitas a todas las subredes internas"
}

# =============================================================================
# 2. POLÍTICAS DE ACCESO PARA TI
# =============================================================================

# Permitir que TI acceda a todas las subredes
resource "google_compute_firewall" "allow_ti_to_all" {
  name    = "allow-ti-to-all-subnets"
  network = google_compute_network.main_vpc.name
  priority = 500

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

  source_ranges = [local.ti_cidr]
  destination_ranges = [
    local.ventas_cidr,
    local.ti_cidr,
    local.datacenter_cidr,
    local.visitas_cidr
  ]

  description = "Fase 2: Permite que TI acceda a todas las subredes"
}

# Bloquear acceso a TI desde otras subredes (excepto TI mismo)
resource "google_compute_firewall" "deny_others_to_ti" {
  name     = "deny-others-to-ti"
  network  = google_compute_network.main_vpc.name
  priority = 1000

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
    local.ventas_cidr,
    local.datacenter_cidr,
    local.visitas_cidr
  ]
  destination_ranges = [local.ti_cidr]

  description = "Fase 2: Bloquea el acceso a TI desde otras subredes (excepto TI mismo)"
}

# =============================================================================
# 3. REGLAS PARA SERVIDOR WEB INTERNO
# =============================================================================

# Permitir acceso HTTP/HTTPS al servidor web interno desde subredes autorizadas
resource "google_compute_firewall" "allow_web_internal" {
  name    = "allow-web-internal"
  network = google_compute_network.main_vpc.name
  priority = 500

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = local.authorized_subnets
  target_tags   = ["web-server-internal"]
  description   = "Fase 2: Permite acceso HTTP/HTTPS al servidor web interno desde Ventas, TI y RRHH"
}

# Bloquear acceso al servidor web desde Internet
resource "google_compute_firewall" "deny_web_from_internet" {
  name     = "deny-web-from-internet"
  network  = google_compute_network.main_vpc.name
  priority = 1000

  deny {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges  = ["0.0.0.0/0"]
  target_tags    = ["web-server-internal"]
  description    = "Fase 2: Bloquea acceso al servidor web interno desde Internet"
}

# Bloquear acceso al servidor web desde Visitas
resource "google_compute_firewall" "deny_web_from_visitas" {
  name     = "deny-web-from-visitas"
  network  = google_compute_network.main_vpc.name
  priority = 1000

  deny {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges  = [local.visitas_cidr]
  target_tags    = ["web-server-internal"]
  description    = "Fase 2: Bloquea acceso al servidor web interno desde subred de Visitas"
}

# =============================================================================
# 4. REGLAS PARA LDAP
# =============================================================================

# Permitir acceso LDAP desde subredes autorizadas hacia Data Center
resource "google_compute_firewall" "allow_ldap_internal" {
  name    = "allow-ldap-internal"
  network = google_compute_network.main_vpc.name
  priority = 500

  allow {
    protocol = "tcp"
    ports    = ["389", "636"]  # LDAP y LDAPS
  }

  allow {
    protocol = "udp"
    ports    = ["389"]  # LDAP
  }

  source_ranges      = local.authorized_subnets
  destination_ranges = [local.datacenter_cidr]
  target_tags        = ["ldap-server"]

  description = "Fase 2: Permite acceso LDAP/LDAPS desde Ventas, TI y RRHH hacia Data Center"
}

# Bloquear acceso LDAP desde Visitas
resource "google_compute_firewall" "deny_ldap_from_visitas" {
  name     = "deny-ldap-from-visitas"
  network  = google_compute_network.main_vpc.name
  priority = 1000

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

  description = "Fase 2: Bloquea acceso LDAP desde subred de Visitas"
}

# =============================================================================
# 5. REGLAS PARA DNS
# =============================================================================

# Permitir acceso DNS desde todas las subredes internas
resource "google_compute_firewall" "allow_dns_internal" {
  name    = "allow-dns-internal"
  network = google_compute_network.main_vpc.name
  priority = 500

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

  description = "Fase 2: Permite acceso DNS desde todas las subredes internas hacia Data Center"
}

# Bloquear acceso DNS desde Visitas
resource "google_compute_firewall" "deny_dns_from_visitas" {
  name     = "deny-dns-from-visitas"
  network  = google_compute_network.main_vpc.name
  priority = 1000

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
  target_tags      = ["dns-server"]

  description = "Fase 2: Bloquea acceso DNS desde subred de Visitas"
}

# =============================================================================
# 6. REGLAS PARA SSH
# =============================================================================

# Permitir SSH desde Ventas hacia instancias (la validación LDAP se hace en las instancias)
resource "google_compute_firewall" "allow_ssh_from_ventas" {
  name    = "allow-ssh-from-ventas"
  network = google_compute_network.main_vpc.name
  priority = 500

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.ventas_cidr]
  description   = "Fase 2: Permite SSH desde Ventas (la autenticación LDAP se valida en las instancias)"
}

# Permitir SSH desde TI (TI tiene acceso completo)
resource "google_compute_firewall" "allow_ssh_from_ti" {
  name    = "allow-ssh-from-ti"
  network = google_compute_network.main_vpc.name
  priority = 500

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.ti_cidr]
  description   = "Fase 2: Permite SSH desde TI (acceso completo)"
}

# Bloquear SSH desde Visitas
resource "google_compute_firewall" "deny_ssh_from_visitas" {
  name     = "deny-ssh-from-visitas"
  network  = google_compute_network.main_vpc.name
  priority = 1000

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.visitas_cidr]
  description   = "Fase 2: Bloquea SSH desde subred de Visitas"
}

# Bloquear SSH desde Internet (solo permitir desde subredes internas)
# Nota: Esta regla bloquea SSH desde Internet. Las reglas allow-ssh-from-ventas
# y allow-ssh-from-ti tienen mayor prioridad (500) y permiten SSH desde subredes internas.
# En GCP, menor número de prioridad = mayor precedencia, así que las reglas ALLOW (500)
# se evalúan antes que esta DENY (900).
resource "google_compute_firewall" "deny_ssh_from_internet" {
  name     = "deny-ssh-from-internet"
  network  = google_compute_network.main_vpc.name
  priority = 900  # Menor precedencia que las reglas ALLOW (500) - se evalúa después

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Bloquear desde Internet
  # Las reglas ALLOW (prioridad 500) para Ventas y TI se evalúan primero y permiten SSH
  # desde esas subredes. Esta regla solo bloquea SSH desde otras fuentes (Internet).
  source_ranges = ["0.0.0.0/0"]
  description   = "Fase 2: Bloquea SSH desde Internet (las reglas allow-ssh-from-* tienen precedencia para subredes internas)"
}

# =============================================================================
# 7. HARDENING - Bloquear puertos no esenciales desde Internet
# =============================================================================

# Nota: En GCP, el hardening de puertos se realiza principalmente a través de
# reglas específicas que solo permiten servicios necesarios. Las reglas anteriores
# ya implementan este principio al ser específicas por servicio.
# 
# Esta regla adicional bloquea puertos no esenciales desde Internet, pero permite
# las reglas específicas de servicios (SSH, DNS, HTTP, HTTPS, LDAP) que tienen
# mayor prioridad (500) o menor (400).
#
# IMPORTANTE: Esta regla tiene prioridad 900, menor que las reglas ALLOW (400-500)
# para que las reglas específicas de servicios tengan precedencia.
resource "google_compute_firewall" "deny_non_essential_ports" {
  name     = "deny-non-essential-ports-from-internet"
  network  = google_compute_network.main_vpc.name
  priority = 900  # Menor que las reglas ALLOW para que tengan precedencia

  deny {
    protocol = "tcp"
    # Bloquear todos los puertos excepto los esenciales (22, 53, 80, 443, 389, 636)
    # Pero las reglas ALLOW específicas tienen precedencia
    ports    = ["0-21", "23-51", "54-79", "81-442", "444-636", "637-65535"]
  }

  deny {
    protocol = "udp"
    # Bloquear todos los puertos UDP excepto DNS (53)
    ports    = ["0-52", "54-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  description   = "Fase 2: Hardening - Bloquea puertos no esenciales desde Internet (las reglas ALLOW específicas tienen precedencia)"
}

# =============================================================================
# 8. ACTUALIZAR REGLA DE TRÁFICO INTERNO (sin Visitas)
# =============================================================================

# Reemplazar la regla allow-internal existente para excluir Visitas y TI como destino
# Esta regla permite tráfico interno solo entre subredes autorizadas, pero excluye TI como destino
# (TI solo puede ser accedido desde TI mismo según los requisitos)
resource "google_compute_firewall" "allow_internal_authorized" {
  name    = "allow-internal-authorized"
  network = google_compute_network.main_vpc.name
  priority = 400

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

  source_ranges = local.internal_subnets
  # Excluir TI del destino: solo Ventas y Data Center pueden comunicarse entre sí
  destination_ranges = [
    local.ventas_cidr,
    local.datacenter_cidr
  ]

  description = "Fase 2: Permite tráfico interno entre Ventas y Data Center - excluye Visitas y TI como destino"
}
