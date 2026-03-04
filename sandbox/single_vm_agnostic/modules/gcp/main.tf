locals {
  full_name_prefix = "${var.name_prefix}-gcp"
}

resource "google_compute_network" "main" {
  name                    = "${local.full_name_prefix}-vnet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${local.full_name_prefix}-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.provider_config.region
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "main" {
  name    = "${local.full_name_prefix}-fw"
  network = google_compute_network.main.name

  dynamic "allow" {
    for_each = var.open_ports
    content {
      protocol = "tcp"
      ports    = [allow.value]
    }
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "main" {
  name   = "${local.full_name_prefix}-ip"
  region = var.provider_config.region
}

resource "google_compute_instance" "main" {
  name         = "${local.full_name_prefix}-vm"
  machine_type = var.provider_config.machine_type
  zone         = var.provider_config.zone

  boot_disk {
    initialize_params {
      image = var.provider_config.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  metadata = {
    ssh-keys = "${var.admin_username}:${var.ssh_pub_key}"
  }
}
