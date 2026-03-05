provider_configs = {
  aws = {
    region = "us-east-2"
    ami_id = "ami-0198cdf7458a7a932" #Ubuntu 24.04 - can find more here https://cloud-images.ubuntu.com/locator/ec2/
    instance_type = "t2.micro"
  }

  azure = {
    location = "northcentralus"
    vm_size  = "Standard_B2pts_v2"
    image = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server-arm64"
      version   = "latest"
    }
  }

  gcp = {
    project = "cloud-portability-experiment"
    region  = "us-central1"
    zone    = "us-central1-a"
    machine_type = "e2-small"
    image   = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
  }
}