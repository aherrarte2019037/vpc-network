# instances.tf
# Definición de todas las instancias del proyecto
# Incluye servidores de producción y VMs de prueba

# =============================================================================
# SERVIDORES DE PRODUCCIÓN
# =============================================================================

# Servidor DNS
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

  # Startup script para instalar y configurar BIND9 completamente
  metadata_startup_script = file("${path.module}/scripts/dns_startup.sh")

  tags = ["dns-server", "datacenter", "iap-ssh"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "dns"
  }

  # Ignorar cambios en atributos que pueden estar configurados manualmente
  # Nota: metadata_startup_script ya NO se ignora para que Terraform pueda actualizar la configuración DNS
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      boot_disk[0].initialize_params[0].size
    ]
  }
}

# Servidor LDAP
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
    # No asignamos IP externa para forzar el uso de Cloud NAT
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
  }

  # Startup script para instalar y configurar OpenLDAP completamente
  metadata_startup_script = file("${path.module}/scripts/ldap_startup.sh")

  tags = ["ldap-server", "datacenter", "iap-ssh"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "ldap"
  }

  # Ignorar cambios en atributos que pueden estar configurados manualmente
  # Nota: metadata_startup_script ya NO se ignora para que Terraform pueda actualizar la configuración LDAP
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
      boot_disk[0].initialize_params[0].size
    ]
  }
}

# Servidor Web Interno (RRHH)
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
    # No asignamos IP externa para forzar el uso de Cloud NAT
  }

  allow_stopping_for_update = true

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/scripts/rrhh_startup.sh")

  tags = ["web-server-internal", "datacenter", "iap-ssh"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "rrhh-web"
  }

  # Ignorar cambios en atributos que pueden estar configurados manualmente
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

# Instancia de prueba en subred de Ventas
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
    # No asignamos IP externa para forzar el uso de Cloud NAT
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y iputils-ping traceroute net-tools
  EOF

  tags = ["ventas", "iap-ssh"]

  labels = {
    environment = var.environment
    team        = "ventas"
  }
}

# Instancia de prueba en subred de TI
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
    # No asignamos IP externa para forzar el uso de Cloud NAT
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y iputils-ping traceroute net-tools
  EOF

  tags = ["ti", "iap-ssh", "ssh-public"]

  labels = {
    environment = var.environment
    team        = "ti"
  }
}

