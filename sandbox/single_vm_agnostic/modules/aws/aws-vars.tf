variable "name_prefix" { type = string }
variable "admin_username" { type = string }
variable "ssh_pub_key" { type = string }
variable "open_ports"  { type = list(number) }

variable "provider_config" {
  type = object({
    region = string
    ami_id = string
    instance_type = string
  })
}