resource "google_compute_network" "vpc_network" {
  project = var.project_name
  name    = var.vpc_name
}

resource "google_compute_subnetwork" "dev_subnet" {
  project       = var.project_name
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
  project      = var.project_name
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name

    access_config {
      // Ephemeral public IP
    }
  }
  depends_on = [google_compute_network.vpc_network]
}