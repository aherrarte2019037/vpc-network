# =============================================================================
# instances.tf
# Definición de todas las instancias del proyecto
# Incluye servidores de producción y VMs de prueba
# =============================================================================

# =============================================================================
# SERVIDORES DE PRODUCCIÓN
# =============================================================================

# -----------------------
# Servidor DNS
# -----------------------
resource "google_compute_instance" "dns" {
  name         = "dns"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.datacenter_subnet.name
    # No asignamos IP externa para forzar el uso de Cloud NAT
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/scripts/dns_startup.sh")

  tags = ["dns-server", "datacenter", "iap-ssh", "snmp-enabled"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "dns"
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      boot_disk[0].initialize_params[0].size
    ]
  }
}

# -----------------------
# Servidor LDAP
# -----------------------
resource "google_compute_instance" "ldap_server" {
  name         = "ldap-server"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.datacenter_subnet.name
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/scripts/ldap_startup.sh")

  tags = ["ldap-server", "datacenter", "iap-ssh", "snmp-enabled"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "ldap"
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      boot_disk[0].initialize_params[0].size
    ]
  }
}

# -----------------------
# Servidor Web Interno (RRHH)
# -----------------------
resource "google_compute_instance" "rrhh_server" {
  name         = "rrhh-server"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.datacenter_subnet.name
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/scripts/rrhh_startup.sh")

  tags = ["web-server-internal", "datacenter", "iap-ssh", "snmp-enabled"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "rrhh-web"
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      boot_disk[0].initialize_params[0].size,
      metadata_startup_script
    ]
  }
}

# -----------------------
# Servidor Web Público (DMZ)
# -----------------------
resource "google_compute_instance" "web_server" {
  name         = "web-server"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.visitas_subnet.name  # Subred DMZ
    access_config {}  # IP pública
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/scripts/web_startup.sh")

  tags = ["web-server", "dmz-web"]

  labels = {
    environment = var.environment
    team        = "dmz"
    service     = "web"
  }

  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      boot_disk[0].initialize_params[0].size,
      metadata_startup_script
    ]
  }
}

# =============================================================================
# VMs DE PRUEBA
# =============================================================================

# -----------------------
# Prueba en subred de Ventas
# -----------------------
resource "google_compute_instance" "ventas_test" {
  name         = "test-ventas-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ventas_subnet.name
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
    ldap-server-ip = google_compute_instance.ldap_server.network_interface[0].network_ip
  }

  metadata_startup_script = file("${path.module}/scripts/sssd_ldap_client.sh")

  tags = ["ventas", "iap-ssh", "snmp-enabled"]

  labels = {
    environment = var.environment
    team        = "ventas"
  }
}

# -----------------------
# Prueba en subred de TI
# -----------------------
resource "google_compute_instance" "ti_test" {
  name         = "test-ti-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ti_subnet.name
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
    ldap-server-ip = google_compute_instance.ldap_server.network_interface[0].network_ip
  }

  metadata_startup_script = file("${path.module}/scripts/sssd_ldap_client.sh")

  tags = ["ti", "iap-ssh", "ssh-public", "snmp-enabled"]

  labels = {
    environment = var.environment
    team        = "ti"
  }
}
