# instances.tf
# Instancias de prueba para verificar conectividad
# Descomenta este archivo cuando quieras crear instancias para pruebas

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

  tags = ["ventas"]

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

  tags = ["ti"]

  labels = {
    environment = var.environment
    team        = "ti"
  }
}

# Instancia de prueba en Data Center
resource "google_compute_instance" "datacenter_test" {
  name         = "test-datacenter-vm"
  machine_type = "e2-micro"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.datacenter_subnet.name
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y iputils-ping traceroute net-tools apache2
    systemctl start apache2
    systemctl enable apache2
    echo "<h1>Data Center Server</h1>" > /var/www/html/index.html
  EOF

  tags = ["datacenter", "web-server"]

  labels = {
    environment = var.environment
    team        = "datacenter"
  }
}

# Outputs para las instancias
output "ventas_vm_internal_ip" {
  description = "IP interna de la VM de Ventas"
  value       = google_compute_instance.ventas_test.network_interface[0].network_ip
}

output "ti_vm_internal_ip" {
  description = "IP interna de la VM de TI"
  value       = google_compute_instance.ti_test.network_interface[0].network_ip
}

output "datacenter_vm_internal_ip" {
  description = "IP interna de la VM de Data Center"
  value       = google_compute_instance.datacenter_test.network_interface[0].network_ip
}
