variable "namecheap_username" {
  type      = string
  sensitive = true
}

variable "namecheap_api_key" {
  type      = string
  sensitive = true
}

variable "namecheap_client_ip" {
  type        = string
  description = "Your whitelisted IP for Namecheap API access"
}