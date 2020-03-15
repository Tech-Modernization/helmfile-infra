resource "google_project_service" "kubernetes" {
  project = var.project
  service = "container.googleapis.com"
}

data "google_client_config" "current" {
}

# you must handle dns subdomain wildcard for ingress on your own

#resource "google_compute_global_address" "ingress_service" {
#  name = "ingress-static-ip-address"
#}

#resource "google_dns_record_set" "ingress_service" {
#  project = var.project
#  managed_zone = "continogcp"
#  name = "ingress.${var.cluster_name}.${var.domain}"
#  type = "A"
#  ttl = 300
#  rrdatas = ["${google_compute_global_address.ingress_service.address}"]
#}

#resource "google_dns_managed_zone" "zone" {
#  count = "1"
#  dns_name = "${var.cluster_name}.${var.domain}"
#  name = var.cluster_name
#  description = "dns zone for infra for helmfile-infra"
#  #labels = "env=${var.cluster_name}"
#}

#data "google_dns_managed_zone" "zone" {
#  name = var.cluster_name
#  project = var.project
#}

resource "google_container_cluster" "primary" {
  name = var.cluster_name
  location = var.location
  remove_default_node_pool = true
  initial_node_count = 1
  min_master_version = "1.15.9-gke.9"
  node_config {
    preemptible  = true
    #machine_type = "n1-standard-1"
  }
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}


resource "google_container_node_pool" "node-pool-1" {
  name       = "node-pool-1"
  location = var.location
  cluster    = google_container_cluster.primary.name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 4
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
resource "kubernetes_namespace" "devops" {
  metadata { name = "devops" }
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
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.location} --project ${var.project} && kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml"
  }
  depends_on = [google_container_node_pool.node-pool-1]
}

output "get-creds" {
 value = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.location} --project ${var.project}"
}
