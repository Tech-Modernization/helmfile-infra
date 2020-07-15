terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "bhood4"
    workspaces {
      name = "bhood-214523"
    }
  }
}
