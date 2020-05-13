variable "location" {
  type        = string
  description = "Location (region or zone) for resources"
  default     = "us-central1" 
}

variable "project" {
  type        = string
  description = "Project were resources are managed"
  #default     = "bhood-214523"
  default      = "level-totality-277022" 
}

variable "cluster_name" {
  type        = string
  description = "cluster name"
  #default     = "gcp"
  default     = "gcp"
}

variable "credential_file" {
  type        = string
  description = "gcp credential file"
  #default    = "~/account.json"
  default    = "~/account.json"
}
