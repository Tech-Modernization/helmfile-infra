resource "kubernetes_manifest" "clusterissuer_letsencrypt_production" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-production"
      "namespace" = "cert-manager"
    }
    "spec" = {
      "acme" = {
        "email" = "bill.hood@contino.io"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-production"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "nginx"
              }
            }
            "selector" = {}
          },
        ]
      }
    }
  }
}
