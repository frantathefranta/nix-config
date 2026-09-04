terraform {
  required_version = ">= 1.0"

  required_providers {
    garage = {
      source  = "jkossis/garage"
      version = "~> 1.0.5"
    }
  }

  backend "s3" {
    bucket = "terraform-state"
    key    = "garage/terraform.tfstate"
    region = "garage"
    endpoints = {
      s3 = "http://s3.infra.franta.us:3900"
    }
    use_path_style              = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "garage" {
  endpoint = var.garage_endpoint
  token    = var.garage_token
}
