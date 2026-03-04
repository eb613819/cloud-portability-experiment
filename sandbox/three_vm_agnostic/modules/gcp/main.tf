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

resource "google_compute_firewall" "web_ssh" {
  name    = "${local.full_name_prefix}-web-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "web_http" {
  name    = "${local.full_name_prefix}-web-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "app_ssh" {
  name    = "${local.full_name_prefix}-app-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["app"]
}

resource "google_compute_firewall" "app_ghost" {
  name    = "${local.full_name_prefix}-app-ghost"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["2368"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["app"]
}

resource "google_compute_firewall" "db_mysql" {
  name    = "${local.full_name_prefix}-db-mysql"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["db"]
}

resource "google_compute_firewall" "db_ssh" {
  name    = "${local.full_name_prefix}-db-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["db"]
}

resource "google_compute_address" "web" {
  name   = "${local.full_name_prefix}-web-ip"
  region = var.provider_config.region
}

resource "google_compute_instance" "web" {
  name         = "${local.full_name_prefix}-web-vm"
  machine_type = var.provider_config.machine_type
  zone         = var.provider_config.zone
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = var.provider_config.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.web.address
    }
  }

  metadata = {
    ssh-keys = "${var.admin_username}:${var.ssh_pub_key}"
  }
}

resource "google_compute_instance" "app" {
  name         = "${local.full_name_prefix}-app-vm"
  machine_type = var.provider_config.machine_type
  zone         = var.provider_config.zone
  tags         = ["app"]

  boot_disk {
    initialize_params {
      image = var.provider_config.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  metadata = {
    ssh-keys = "${var.admin_username}:${var.ssh_pub_key}"
  }
}

resource "google_compute_instance" "db" {
  name         = "${local.full_name_prefix}-db-vm"
  machine_type = var.provider_config.machine_type
  zone         = var.provider_config.zone
  tags         = ["db"]

  boot_disk {
    initialize_params {
      image = var.provider_config.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  metadata = {
    ssh-keys = "${var.admin_username}:${var.ssh_pub_key}"
  }
}
