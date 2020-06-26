resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = var.project
  service = element(var.project_services, count.index)
  disable_on_destroy = false
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

data "google_container_engine_versions" "version" {
  project            = var.project
  location           = var.location
}

module "gke-cluster" {
  source                     = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//modules/beta-private-cluster"
  project_id                 = var.project
  name                       = var.cluster_name
  region                     = var.location
  network                    = google_compute_network.default.name
  #network_project_id         = var.network_project
  subnetwork                 = google_compute_subnetwork.default.name
  ip_range_pods              = var.ip_range_pods
  ip_range_services          = var.ip_range_services
  create_service_account     = true
  kubernetes_version         = var.kubernetes_version == "" ? data.google_container_engine_versions.version.default_cluster_version : var.kubernetes_version
  node_version               = var.node_version
  skip_provisioners          = true
  node_pools = [
    { 
      name            = "pool1"
      machine_type    = "n1-standard-2"
      min_count       = 1
      max_count       = 2
      disk_size_gb    = 100
      disk_type       = "pd-standard"
      image_type      = "COS"
      auto_repair     = true
      preemptible     = false
      initial_node_count = 1
      #auto_upgrade    = true
      #version          = var.node_version
      #service_account = google_service_account.vault-admin.email
    },
  ]

  node_pools_oauth_scopes = {
    all = []
    pool1 = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_metadata = {
    all = {}
    pool1 = {}
  }

  node_pools_taints = {
    all = []
    pool1 = []
  }

  node_pools_labels = {
    all = {}
    pool1 = {
      environment = "sandbox"
    }
  }

  node_pools_tags = {
    all = []
    pool1 = [
      "sandbox",
    ]
  }
  remove_default_node_pool   = true
  initial_node_count         = var.initial_node_count
  enable_private_nodes       = false
  identity_namespace         = "${var.project}.svc.id.goog"
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  master_authorized_networks = var.master_authorized_networks
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
