variable "name_prefix" { type = string }
variable "admin_username" { type = string }
variable "ssh_pub_key" { type = string }

variable "provider_config" {
  type = object({
    project      = string
    region       = string
    zone         = string
    machine_type = string
    image        = string
  })
}