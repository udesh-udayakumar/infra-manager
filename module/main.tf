resource "google_compute_network" "vpc_network" {

  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "dev_subnet" {

  name          = var.subnet
  ip_cidr_range = "10.4.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

resource "google_compute_instance" "dev_vm" {

  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.dev_subnet.name

    access_config {
      // Ephemeral public IP
    }
  }
  depends_on = [google_compute_network.vpc_network]
}

resource "google_compute_global_address" "private_ip_address" {

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {

  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {

  name             = "private-sample-instance-${random_id.db_name_suffix.hex}"
  region           = var.region
  database_version = "MYSQL_5_7"

  depends_on = [google_service_networking_connection.private_vpc_connection]
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.vpc_network.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}