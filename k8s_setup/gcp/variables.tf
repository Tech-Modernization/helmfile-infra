variable "location" {
  type        = string
  description = "Location (region or zone) for resources"
}

variable "project" {
  type        = string
  description = "Project were resources are managed"
}

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

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
  default     = 0
}

variable "master_authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access (except the cluster node IPs, which GKE automatically whitelists)."
  default     = []
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "(Beta) The IP range in CIDR notation to use for the hosted master network"
}

variable "ip_range_pods" {
  description = "The name of the secondary range for the pods"
}

variable "ip_range_services" {
  description = "The name of the secondary range for the services"
}

