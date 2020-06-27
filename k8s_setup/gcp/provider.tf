provider "google" {
}
provider "kubernetes" {
#  gke managed by LZ
#  host = "https://${data.google_container_cluster.primary.endpoint}"
#  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)

  load_config_file = false
  host = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token = data.google_client_config.current.access_token
}

provider "kubernetes-alpha" {
  load_config_file = false
  host = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token = data.google_client_config.current.access_token
}
