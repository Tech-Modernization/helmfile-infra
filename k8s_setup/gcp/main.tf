resource "google_compute_global_address" "ingress_service" {
 name = "ingress-static-ip-address"
}

resource "google_dns_record_set" "ingress_service" {
 project = var.project
 managed_zone = "continogcp"
 name = "ingress.gcp.contino.io"
 type = "A"
 ttl = 300
 rrdatas = ["${google_compute_global_address.ingress_service.address}"]
}

resource "google_dns_managed_zone" "zone" {
 count = "1"
 dns_name = "gcp.contino.io"
 name = "continogcp"
 description = "contino gcp env for infra for helmfile-infra"
 #labels = "env=gcp"
}

#data "google_dns_managed_zone" "zone" {
# name = "continogcp"
# project = var.project
#}
