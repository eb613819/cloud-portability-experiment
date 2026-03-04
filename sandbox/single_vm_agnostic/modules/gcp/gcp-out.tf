output "public_ip" {
  value = google_compute_address.main.address
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${google_compute_address.main.address}"
}