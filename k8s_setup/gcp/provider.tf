provider "google" {
  credentials = file("~/account.json")
  project = var.project
  region  = var.location
  #zone    = "us-east1-c"
}
provider "kubernetes" {
  load_config_file = false
  host = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  token = data.google_client_config.current.access_token
}
