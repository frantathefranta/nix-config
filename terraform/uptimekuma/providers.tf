terraform {
  required_version = ">= 1.0"

  required_providers {
    uptimekuma = {
      source  = "breml/uptimekuma"
      version = "~> 0.3"
    }
    akeyless = {
      source  = "akeyless-community/akeyless"
      version = "~> 2.0"
    }
  }
}

provider "uptimekuma" {
  endpoint = var.uptimekuma_endpoint
  username = var.uptimekuma_username
  password = var.uptimekuma_password
}

provider "akeyless" {
  api_key_login {
    access_id  = var.access_id
    access_key = var.access_key
  }
}
