terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "cloud-portability-experiment-gcp"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# Network
resource "google_compute_network" "main" {
  name                    = "vnet"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "main" {
  name          = "subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.main.id
}

# Firewall
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Static IP
resource "google_compute_address" "main" {
  name   = "static-ip"
  region = "us-central1"
}

# VM
resource "google_compute_instance" "main" {
  name         = "cloud-portability-gcp-vm-01"
  machine_type = "e2-small"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {
      nat_ip = google_compute_address.main.address
    }
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_ed25519.pub")}"
  }
}

output "public_ip_address" {
  value = google_compute_address.main.address
}

output "ssh_connection" {
  value = "ssh ubuntu@${google_compute_address.main.address}"
}
