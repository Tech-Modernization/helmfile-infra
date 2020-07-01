resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = data.google_client_config.current.project
  service = element(var.project_services, count.index)
  #disable_on_destroy = false
}

data "google_client_config" "current" {
}

module "gke-network" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 2.0"
  project_id   = data.google_client_config.current.project
  network_name = var.network_name

  subnets = [
    {
      subnet_name   = "random-gke-subnet"
      subnet_ip     = "10.0.0.0/24"
      subnet_region = data.google_client_config.current.region
      subnet_private_access	= true
      subnet_flow_logs = true
    },
  ]

  secondary_ranges = {
    "random-gke-subnet" = [
      {
        range_name    = "random-ip-range-pods"
        ip_cidr_range = "10.1.0.0/16"
      },
      {
        range_name    = "random-ip-range-services"
        ip_cidr_range = "10.2.0.0/20"
      },
  ] }
}

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = data.google_client_config.current.region
  network = module.gke-network.network_self_link
  bgp {
    asn = 64514
  }
}

module "cloud-nat" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.2"
  project_id = data.google_client_config.current.project
  region     = data.google_client_config.current.region
  router     = google_compute_router.router.name
}

  
module "gke" {
  #source                 = "terraform-google-modules/kubernetes-engine/google"
  source                            = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"

  project_id                        = data.google_client_config.current.project
  name                              = var.cluster_name
  region                            = data.google_client_config.current.region
  regional                          = true
  network                           = module.gke-network.network_name
  subnetwork                        = module.gke-network.subnets_names[0]
  ip_range_pods                     = module.gke-network.subnets_secondary_ranges[0].*.range_name[0]
  ip_range_services                 = module.gke-network.subnets_secondary_ranges[0].*.range_name[1]

  enable_private_endpoint           = false
  enable_private_nodes              = true
  master_ipv4_cidr_block            = "172.16.0.16/28"
  network_policy                    = true
  horizontal_pod_autoscaling        = true
  create_service_account            = true

#  service_account                   = "create"
#  remove_default_node_pool          = true
#  disable_legacy_metadata_endpoints = true
#  master_authorized_networks = [
#    {
#      cidr_block   = module.gke-network.subnets_ips[0]
#      display_name = "VPC"
#    },
#    {
#      cidr_block   = "0.0.0.0/32"
#      display_name = "ALL"
#    },
#  ]

  node_pools = [
    {
      name               = "my-node-pool"
      machine_type       = "n1-standard-2"
      min_count          = 1
      max_count          = 5
      disk_size_gb       = 100
      disk_type          = "pd-ssd"
      image_type         = "COS"
      auto_repair        = true
      auto_upgrade       = false
      preemptible        = false
      initial_node_count = 1
    },
  ]
#  node_pools_oauth_scopes = {
#    all = [
#      "https://www.googleapis.com/auth/trace.append",
#      "https://www.googleapis.com/auth/service.management.readonly",
#      "https://www.googleapis.com/auth/monitoring",
#      "https://www.googleapis.com/auth/devstorage.read_only",
#      "https://www.googleapis.com/auth/servicecontrol",
#      "https://www.googleapis.com/auth/logging.write",
#    ]
#    my-node-pool = [
#      "https://www.googleapis.com/auth/trace.append",
#      "https://www.googleapis.com/auth/service.management.readonly",
#      "https://www.googleapis.com/auth/monitoring",
#      "https://www.googleapis.com/auth/devstorage.read_only",
#      "https://www.googleapis.com/auth/servicecontrol",
#      "https://www.googleapis.com/auth/logging.write",
#    ]
#  }
  node_pools_labels = {
    all = {}
    my-node-pool = {}
  }
  node_pools_metadata = {
    all = {}
    my-node-pool = {}
  }
  node_pools_tags = {
    all =  []
    my-node-pool = []
  }
}

resource "tfe_workspace" "project" {
  organization = "bhood4"
  name         = data.google_client_config.current.project
}

resource "tfe_variable" "project" {
  key          = "GOOGLE_PROJECT"
  value        = data.google_client_config.current.project
  category     = "env"
  workspace_id = "${tfe_workspace.project.id}"
  description  = "GCP Project"
}

resource "tfe_variable" "region" {
  key          = "GOOGLE_REGION"
  value        = data.google_client_config.current.region
  category     = "env"
  workspace_id = "${tfe_workspace.project.id}"
  description  = "GCP Region"
}

resource "tfe_variable" "zone" {
  key          = "GOOGLE_ZONE"
  value        = data.google_client_config.current.zone
  category     = "env"
  workspace_id = "${tfe_workspace.project.id}"
  description  = "GCP Zone"
}

resource "tfe_variable" "credentials" {
  key          = "GOOGLE_CREDENTIALS"
  value        = data.google_client_config.current.access_token
  category     = "env"
  sensitive    = true
  workspace_id = "${tfe_workspace.project.id}"
  description  = "GCP access token"
}
