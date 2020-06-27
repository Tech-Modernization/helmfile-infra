resource "kubernetes_manifest" "clusterissuer_letsencrypt_staging" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1alpha2"
    "kind" = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-staging"
      "namespace" = "cert-manager"
    }
    "spec" = {
      "acme" = {
        "email" = "bill.hood@contino.io"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-staging"
        }
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
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
