data "google_client_config" "current" { }

data "google_client_openid_userinfo" "provider_identity" {
}

data "google_container_cluster" "my_cluster" {
  name     = var.cluster_name
  location = data.google_client_config.current.region
}

resource "kubernetes_namespace" "namespace" {
  #count = 0
  count   = length(var.namespaces)
  metadata { name = element(var.namespaces, count.index) }
}

resource "kubernetes_cluster_role_binding" "admin" {
  #count = 0
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
    name      = var.admin_user
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "User"
    name      = data.google_client_openid_userinfo.provider_identity.email
    api_group = "rbac.authorization.k8s.io"
  }
}

module "testmodule" {
  source  = "app.terraform.io/bhood4/testmodule/bhood4"
  version = "0.0.4"
  name    = "myfirstmodulevm"
}

