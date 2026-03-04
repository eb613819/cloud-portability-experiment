output "public_ip" {
  value = aws_instance.this.public_ip
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${aws_instance.this.public_ip}"
}