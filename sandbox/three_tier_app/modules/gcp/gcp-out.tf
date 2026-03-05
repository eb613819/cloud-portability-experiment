output "web_public_ip" {
  value = google_compute_address.web.address
}

output "app_private_ip" {
  value = google_compute_instance.app.network_interface[0].network_ip
}

output "db_private_ip" {
  value = google_compute_instance.db.network_interface[0].network_ip
}