variable "selectel_domain_name" {
  type        = string
  description = "Selectel account (domain_name / account ID)"
}

variable "selectel_username" {
  type        = string
  description = "Selectel service user name"
}

variable "selectel_password" {
  type        = string
  sensitive   = true
  description = "Selectel service user password"
}

variable "project_id" {
  type        = string
  description = "Selectel VPC project ID (tenant_id)"
}

variable "region" {
  type        = string
  default     = "ru-9"
  description = "Selectel region"
}

variable "tf_state_region" {
  type        = string
  default     = "ru-1"
  description = "S3 region for Terraform state"
}
