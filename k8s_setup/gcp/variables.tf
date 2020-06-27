variable "cluster_name" {
  type        = string
  description = "cluster name"
  default     = "gcp"
}

variable "network_name" {
  type        = string
  description = "network name"
  default     = "default"
}

variable "project_services" {
  type = list(string)
  default = [
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "container.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "serviceusage.googleapis.com",
  ]
  description = "List of services to enable on the project."
}

variable "master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "admin_user" {
  type        = string
  description = "cluster admin user (email)"
  default     = "bill.hood@dexcom.com"
}
