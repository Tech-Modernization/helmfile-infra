variable "agent_count" {
  type        = number
  description = "number of worker nodes in cluster"
  default     = 2
}

variable "location" {
  type        = string
  description = "Location (region or zone) for resources"
  default     = "eastus" 
}

variable "project" {
  type        = string
  description = "Project were resources are managed"
  default     = "bhood-214523"
}

variable "cluster_name" {
  type        = string
  description = "Project were resources are managed"
  default     = "azure"
}

variable "client_id" {
  type        = string
  description = "app service account client id"
  default     = "9ad2b2a7-0fc3-4af7-b607-8a9457a8f9c8"
}

variable "client_secret" {
  type        = string
  description = "app service account client secret (export TF_VAR_client_secret)"
}
