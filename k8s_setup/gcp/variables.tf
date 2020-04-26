variable "location" {
  type        = string
  description = "Location (region or zone) for resources"
  #default     = "us-central1" 
}

variable "project" {
  type        = string
  description = "Project were resources are managed"
  #default     = "bhood-214523"
}

variable "cluster_name" {
  type        = string
  description = "Project were resources are managed"
  #default     = "gcp"
}

variable "credential_file" {
  type        = string
  description = "gcp credential file"
  #default    = "~/account.json"
}

variable "cluster_ca_cert" {
  type        = string
  description = "gke cluster CA cert"
}
