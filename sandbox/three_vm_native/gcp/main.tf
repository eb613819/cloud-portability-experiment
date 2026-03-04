terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "cloud-portability-experiment"
  region  = "us-central1"
  zone    = "us-central1-a"
}

resource "google_compute_network" "main" {
  name                    = "vnet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.main.id
}

resource "google_compute_firewall" "web_ssh" {
  name    = "web-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "web_http" {
  name    = "web-http"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "app_ssh" {
  name    = "app-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["app"]
}

resource "google_compute_firewall" "app_ghost" {
  name    = "app-ghost"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["2368"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["app"]
}

resource "google_compute_firewall" "db_mysql" {
  name    = "db-mysql"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["db"]
}

resource "google_compute_firewall" "db_ssh" {
  name    = "db-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.1.0/24"]
  target_tags   = ["db"]
}

resource "google_compute_address" "web" {
  name   = "ghost-web-ip"
  region = "us-central1"
}

resource "google_compute_instance" "web" {
  name         = "ghost-web"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  tags         = ["web"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.web.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "google_compute_instance" "app" {
  name         = "ghost-app"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  tags         = ["app"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

resource "google_compute_instance" "db" {
  name         = "ghost-db"
  machine_type = "e2-small"
  zone         = "us-central1-a"
  tags         = ["db"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

output "web_public_ip" {
  value = google_compute_address.web.address
}

output "app_private_ip" {
  value = google_compute_instance.app.network_interface[0].network_ip
}

output "db_private_ip" {
  value = google_compute_instance.db.network_interface[0].network_ip
}