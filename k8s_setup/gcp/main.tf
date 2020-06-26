resource "google_project_service" "compute" {
  project = var.project
  service = "compute.googleapis.com"
}
resource "google_project_service" "container" {
  project = var.project
  service = "container.googleapis.com"
}
resource "google_project_service" "iam" {
  project = var.project
  service = "iam.googleapis.com"
}
resource "google_project_service" "serviceusage" {
  project = var.project
  service = "serviceusage.googleapis.com"
}
resource "google_project_service" "cloudresourcemanager" {
  project = var.project
  service = "cloudresourcemanager.googleapis.com"
}

data "google_client_config" "current" {
}

# you must handle dns subdomain wildcard for ingress on your own

data "google_container_cluster" "primary" {
  name = var.cluster_name
  location = var.location
}

resource "google_compute_network" "default" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "default" {
  name                     = var.network_name
  ip_cidr_range            = "10.127.0.0/20"
  network                  = google_compute_network.default.self_link
  region                   = var.location
  private_ip_google_access = true
}

# data "google_container_engine_versions" "default" {
#   zone = var.zone
# } 

resource "google_container_cluster" "primary" {
# if cluster managed by LZ
#  count = 0
  name = var.cluster_name
  location = var.location
  remove_default_node_pool = true
  initial_node_count = 1
  # zone               = var.zone
  # min_master_version = data.google_container_engine_versions.default.latest_master_version
  min_master_version = "1.15.9-gke.24"
  network            = google_compute_network.default.name
  subnetwork         = google_compute_subnetwork.default.name

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
  }
  
  #node_config {
  #  preemptible  = true
  #  #machine_type = "n1-standard-1"
  #}
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}


resource "google_container_node_pool" "node-pool-1" {
# if cluster managed by LZ
#  count = 0
  name       = "node-pool-1"
  location   = var.location
  cluster    = google_container_cluster.primary.name
  #cluster    = var.cluster_name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    preemptible  = true
    machine_type = "n1-standard-2"
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "kubernetes_namespace" "cert-manager" {
  metadata { name = "cert-manager" }
}
resource "kubernetes_namespace" "vault" {
  metadata { name = "vault" }
}
resource "kubernetes_namespace" "devops" {
  metadata { name = "devops" }
}
resource "kubernetes_namespace" "twistlock" {
  metadata { name = "twistlock" }
}
resource "kubernetes_namespace" "myapp-prometheus" {
  metadata { name = "myapp-prometheus" }
}
resource "kubernetes_namespace" "nginx" {
  metadata { name = "nginx" }
}
resource "kubernetes_namespace" "prometheus" {
  metadata { name = "prometheus" }
}
resource "kubernetes_namespace" "sonarqube" {
  metadata { name = "sonarqube" }
}
resource "kubernetes_namespace" "kafka" {
  metadata { name = "kafka" }
}
resource "kubernetes_namespace" "my-kafka-project" {
  metadata { name = "my-kafka-project" }
}

resource "kubernetes_service_account" "helm" {
  metadata {
    name = "helm"
    namespace = "kube-system"
  }
}

resource "kubernetes_cluster_role_binding" "helm" {
  metadata {
    name = "helm"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "helm"
    namespace = "kube-system"
  }
}

resource "null_resource" "import" {
  triggers = {
    always_run = "${timestamp()}"
    #run = kubernetes_namespace.cert-manager.uid
  }
  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.location} --project ${var.project} && kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml && kubectl apply -f ../issuer_prod.yaml && kubectl apply -f ../issuer_staging.yaml"

  }
  depends_on = [google_container_cluster.primary, google_container_node_pool.node-pool-1]
}

output "get-creds" {
 value = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.location} --project ${var.project}"
}
