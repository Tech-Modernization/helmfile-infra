data "google_client_config" "current" { }

data "google_client_openid_userinfo" "provider_identity" {
}

data "google_container_cluster" "my_cluster" {
  name     = var.cluster_name
  location = data.google_client_config.current.region
}

#resource "kubernetes_namespace" "namespace" {
#  count   = length(var.namespaces)
#  metadata { name = element(var.namespaces, count.index) }
#}

resource "kubernetes_cluster_role_binding" "admin" {
  metadata {
    name = "admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    #name      = var.admin_user
    name      = data.google_client_openid_userinfo.provider_identity.email
    api_group = "rbac.authorization.k8s.io"
  }
}


#resource "kubernetes_manifest" "test-configmap" {
#  provider = kubernetes-alpha
#  manifest = "$file(../cert-manager-certificaterequests.tf)"
#}

#cert-manager-certificaterequests.tf
#cert-manager-challenges.tf
#cert-manager-issuers.tf
#issuer_prod.tf
#cert-manager-certificates.tf
#cert-manager-clusterissuers.tf
#cert-manager-orders.tf
#issuer_staging.tf

#kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.14/deploy/manifests/00-crds.yaml 
#&& kubectl apply -f ../issuer_prod.yaml 
#&& kubectl apply -f ../issuer_staging.yaml"
