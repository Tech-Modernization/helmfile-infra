variable "cluster_name" {
  type        = string
  description = "cluster name"
  default     = "gcp"
}

variable "namespaces" {
  type = list(string)
  default = [
  "cert-manager",
  "vault",
  "devops",
  "twistlock",
  "myapp-prometheus",
  "nginx",
  "prometheus",
  "sonarqube",
  "kafka",
  "my-kafka-project",
  ]
  description = "List of namespaces to enable on the cluster"
}

variable "admin_user" {
  type        = string
  description = "cluster admin user (email)"
  default     = "bill.hood@dexcom.com"
}
