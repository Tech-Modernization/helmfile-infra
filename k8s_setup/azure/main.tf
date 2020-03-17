resource "azurerm_resource_group" "k8s" {
  name     = var.project
  location = var.location
}

resource "azurerm_kubernetes_cluster" "k8s" {
    name                = var.cluster_name
    location            = azurerm_resource_group.k8s.location
    resource_group_name = azurerm_resource_group.k8s.name
    dns_prefix          = var.project

    kubernetes_version  = "1.15.7"

    default_node_pool {
        name            = "agentpool"
        node_count      = var.agent_count
        vm_size         = "Standard_DS2_v2"
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    tags = {
        Project = var.project
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
    command = "az aks get-credentials --resource-group ${var.project} --name ${var.cluster_name} && kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml && kubectl apply -f ../issuer_prod.yaml && kubectl apply -f ../issuer_staging.yaml"
  }
  depends_on = [azurerm_kubernetes_cluster.k8s]
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate
}
