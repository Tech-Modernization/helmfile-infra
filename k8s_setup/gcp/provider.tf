provider "google" {
  credentials = file(var.credential_file)
  project = var.project
  region  = var.location
}
provider "kubernetes" {
  load_config_file = false
  host = "https://${data.google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token = data.google_client_config.current.access_token
}
