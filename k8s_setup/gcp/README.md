# gke env setup for helmfile-infra on GCP Sandbox Project

Creates infrastructure for running GKE in private GCP Sandbox from terraform cloud:
* VPC with 
* private GKE (private nodes, public kubernetes API)
* NAT to get out to public internet

See terraformcloud.md for details


# gke env setup for helmfile-infra with GCP Trial Account (OLD)

* create new "trial" account https://accounts.google.com/signup/v2/webcreateaccount?service=cloudconsole&continue=https%3A%2F%2Fconsole.cloud.google.com%2Fgetting-started%3Fproject%3Dlevel-totality-277022&hl=en_US&gmb=exp&biz=false&flowName=GlifWebSignIn&flowEntry=SignUp&nogm=true (e.g. bhood4contino@gmail.com)
* login to gcp console: https://console.cloud.google.com/
* IAM & Admin + Service Account + Create Service Account "terraform", Role="Owner"+Create Key
* save the key file as ~/account.json (use in terraform cloud ENV GOOGLE_CREDENTIALS)
* gcloud init, create a new configuration, login with new account, pick default project, set region and zone
