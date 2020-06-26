provider "google" {
}
provider "kubernetes" {
  load_config_file = false

#  gke managed by LZ
#  host = "https://${data.google_container_cluster.primary.endpoint}"
#  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)

  host = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)

  token = data.google_client_config.current.access_token
}
