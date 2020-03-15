variable "location" {
  type        = string
  description = "Location (region or zone) for resources"
  default     = "us-central1" 
}

variable "project" {
  type        = string
  description = "Project were resources are managed"
  default     = "bhood-214523"
}

variable "cluster_name" {
  type        = string
  description = "Project were resources are managed"
  default     = "gcp"
}
