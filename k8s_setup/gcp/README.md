# gcp/gke env setup for helmfile-infra

# on the cheap

* create new "trial" account https://accounts.google.com/signup/v2/webcreateaccount?service=cloudconsole&continue=https%3A%2F%2Fconsole.cloud.google.com%2Fgetting-started%3Fproject%3Dlevel-totality-277022&hl=en_US&gmb=exp&biz=false&flowName=GlifWebSignIn&flowEntry=SignUp&nogm=true (e.g. bhood4contino@gmail.com)
* login to gcp console: https://console.cloud.google.com/
* IAM & Admin + Service Account + Create Service Account "terraform", Role="Owner"+Create Key
* save the key file as ~/account.json 
* gcloud init, creaet a new configuration, bhood4contino, login with new account, pick project, don't set region and zone
* enable cloud resource manager API https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=57562663465
* enable kubernetes engine API https://console.developers.google.com/apis/api/container.googleapis.com/overview?project=57562663465

```
terraform init
terrafomr plan
terrafomr apply
```

https://certbot.eff.org/docs/using.html#manual
Use existing DNS hover gcp.continotb.com to IP of ingress
