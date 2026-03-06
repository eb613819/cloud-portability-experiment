variable "provider_configs" {
  type = object({
    aws = object({
      region = string
      ami_id = string
      instance_type = string
    })
    azure = object({
      location = string
      vm_size  = string
      image = object({
        publisher = string
        offer     = string
        sku       = string
        version   = string
      })
    })
    gcp = object({
      project      = string
      region       = string
      zone         = string
      machine_type = string
      image        = string
    })
  })
}