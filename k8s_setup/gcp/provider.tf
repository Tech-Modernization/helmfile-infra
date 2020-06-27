provider "google" {
}
provider "kubernetes" {
  load_config_file = false
  host = "https://${module.gke.endpoint}"
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token = data.google_client_config.current.access_token
}

#provider "kubernetes-alpha" {
#  load_config_file = false
#  host = "https://${module.gke.endpoint}"
#  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
#  token = data.google_client_config.current.access_token
#}
