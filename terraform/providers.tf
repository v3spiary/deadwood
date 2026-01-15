terraform {
  required_version = ">= 1.6.0"

  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "~> 6.0"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = ">= 2.1.0"
    }
  }
}

provider "selectel" {
  domain_name = var.selectel_domain_name
  username    = var.selectel_username
  password    = var.selectel_password
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
  auth_region = var.region
}

provider "openstack" {
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3"
  domain_name = var.selectel_domain_name
  tenant_id   = var.project_id
  user_name   = var.selectel_username
  password    = var.selectel_password
  region      = var.region
}
