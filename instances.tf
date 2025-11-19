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
  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -eux
    
    # Instalar BIND9
    apt-get update
    apt-get install -y bind9 bind9utils bind9-doc
    
    # Configurar named.conf.options
    cat > /etc/bind/named.conf.options <<'OPTIONS_EOF'
options {
        directory "/var/cache/bind";

        recursion yes;
        allow-recursion { 10.0.0.0/16; };

        forwarders {
                8.8.8.8;
                1.1.1.1;
        };

        dnssec-validation auto;

        listen-on { any; };
        listen-on-v6 { none; };
};
OPTIONS_EOF

    # Configurar named.conf.local
    cat > /etc/bind/named.conf.local <<'LOCAL_EOF'
zone "x.local" {
        type master;
        file "/etc/bind/db.x.local";
};

zone "3.0.10.in-addr.arpa" {
        type master;
        file "/etc/bind/db.10.0.3";
};
LOCAL_EOF

    # Configurar zona forward db.x.local
    cat > /etc/bind/db.x.local <<'ZONE_EOF'
$TTL    604800
@       IN      SOA     dns.x.local. admin.x.local. (
                        2         ; Serial
                        604800     ; Refresh
                        86400      ; Retry
                        2419200    ; Expire
                        604800 )   ; Negative Cache TTL

@       IN      NS      dns.x.local.

dns     IN      A       10.0.3.10
rrhh    IN      A       10.0.3.20
ldap    IN      A       10.0.3.30
ZONE_EOF

    # Configurar zona reverse db.10.0.3
    cat > /etc/bind/db.10.0.3 <<'REVERSE_EOF'
$TTL    604800
@       IN      SOA     dns.x.local. admin.x.local. (
                        2
                        604800
                        86400
                        2419200
                        604800 )

@       IN      NS      dns.x.local.

10      IN      PTR     dns.x.local.
20      IN      PTR     rrhh.x.local.
30      IN      PTR     ldap.x.local.
REVERSE_EOF

    # Verificar configuración
    named-checkconf
    named-checkzone x.local /etc/bind/db.x.local
    named-checkzone 3.0.10.in-addr.arpa /etc/bind/db.10.0.3
    
    # Habilitar y reiniciar BIND9
    systemctl enable named
    systemctl restart named
    
    # Verificar que está corriendo
    systemctl status named --no-pager
  EOF

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

  # Startup script para instalar OpenLDAP
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y slapd ldap-utils
    # La configuración de LDAP se hace manualmente después de la instalación
  EOF

  tags = ["ldap-server", "datacenter", "iap-ssh"]

  labels = {
    environment = var.environment
    team        = "datacenter"
    service     = "ldap"
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

  # Startup script para instalar Apache
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    
    # Crear página HTML básica para RRHH
    mkdir -p /var/www/html
    echo "<h1>Sistema de Administración de RRHH</h1>" > /var/www/html/index.html
    echo "<p>Bienvenido al sistema interno de Recursos Humanos</p>" >> /var/www/html/index.html
    
    systemctl enable apache2
    systemctl start apache2
  EOF

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

