#Interface variables
variable "platform" {
  description = "Cloud provider to deploy to (aws, azure, gcp)"
  type        = string

  validation {
    condition     = contains(["aws", "azure", "gcp"], var.platform)
    error_message = "Platform must be aws, azure, or gcp."
  }
}

variable "name_prefix" {
  description = "Prefix used for all resource names"
  type        = string
}

variable "admin_username" {
  description = "Admin username for VM access"
  type        = string
}

variable "ssh_pub_key" {
  description = "Public SSH key for VM access"
  type        = string
}

variable "open_ports" {
  description = "List of TCP ports to allow ingress"
  type        = list(number)
}
