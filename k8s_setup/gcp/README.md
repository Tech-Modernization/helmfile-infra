Letsencrypt
https://medium.com/bluekiri/deploy-a-nginx-ingress-and-a-certitificate-manager-controller-on-gke-using-helm-3-8e2802b979ec

kubectl apply --validate=false -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml
kubectl create namespace cert-manager
kubectl apply -f issuer.yaml

https://medium.com/@maninder.bindra/auto-provisioning-of-letsencrypt-tls-certificates-for-kubernetes-services-deployed-to-an-aks-52fd437b06b0

The kind of Issuer and the name of the Issuer should match the values mentioned in the ingressShim.extraArgs (of the cert-manager helm installation command). cert-manager uses the ACME protocol to verify ownership of the domain before getting certificates from Letsencrypt. In the yaml above we have provided the url of the production Letsencrypt ACME server. The staging url of the Letsencrypt ACME server is https://acme-staging.api.letsencrypt.org/directory . You can find more detail on these settings at the linkkkkkjkk

https://cert-manager.readthedocs.io/en/latest/tutorials/acme/http-validation.html


https://certbot.eff.org/docs/using.html#manual

Use existing DNS hover
gcp.allaboutthatbassstudios.com 
to IP of ingress

afraid.org
no wildcard without paying

https://ipv6.he.net/certification/login.php

#https://medium.com/faun/dns-and-gke-network-configuration-on-google-cloud-platform-1bfdc74fe2e

https://cloud.google.com/kubernetes-engine/docs/concepts/ingress

#TODO
#create gke cluster, 3-5 n2
#create sa, ns

# firewall for admission webhook 
gcloud container clusters describe acme --region us-central1-c | yq r - ipAllocationPolicy.clusterIpv4CidrBlock
10.36.0.0/14

gcloud compute firewall-rules list \
    --filter 'name~^gke-acme' \
    --format 'table(
        name,
        network,
        direction,
        sourceRanges.list():label=SRC_RANGES,
        allowed[].map().firewall_rule().list():label=ALLOW,
        targetTags.list():label=TARGET_TAGS
    )'

NAME                   NETWORK  DIRECTION  SRC_RANGES        ALLOW                         TARGET_TAGS
gke-acme-f12e5ab7-all  default  INGRESS    10.36.0.0/14      tcp,udp,icmp,esp,ah,sctp      gke-acme-f12e5ab7-node
gke-acme-f12e5ab7-ssh  default  INGRESS    35.225.215.43/32  tcp:22                        gke-acme-f12e5ab7-node
gke-acme-f12e5ab7-vms  default  INGRESS    10.128.0.0/9      icmp,tcp:1-65535,udp:1-65535  gke-acme-f12e5ab7-node

gcloud compute firewall-rules create allow-apiserver-to-admission-webhook-8443 \
    --action ALLOW \
    --direction INGRESS \
    --source-ranges 10.36.0.0/14 \
    --rules tcp :8443 \
    --target-tags gke-acme-f12e5ab7-node




https://github.com/helm/charts/issues/16249
#!/bin/bash
CLUSTER_NAME=clustername
CLUSTER_REGION=europe-west1
VPC_NETWORK=$(gcloud container clusters describe $CLUSTER_NAME --region $CLUSTER_REGION --format='value(network)')
MASTER_IPV4_CIDR_BLOCK=$(gcloud container clusters describe $CLUSTER_NAME --region $CLUSTER_REGION --format='value(privateClusterConfig.masterIpv4CidrBlock)')
NODE_POOLS_TARGET_TAGS=$(gcloud container clusters describe $CLUSTER_NAME --region $CLUSTER_REGION --format='value[terminator=","](nodePools.config.tags)' --flatten='nodePools[].config.tags[]' | sed 's/,\{2,\}//g')

echo $VPC_NETWORK
echo $MASTER_IPV4_CIDR_BLOCK
echo $NODE_POOLS_TARGET_TAGS

gcloud compute firewall-rules create "allow-apiserver-to-admission-webhook-8443" \
      --allow tcp:8443 \
      --network="$VPC_NETWORK" \
      --source-ranges="$MASTER_IPV4_CIDR_BLOCK" \
      --target-tags="$NODE_POOLS_TARGET_TAGS" \
      --description="Allow apiserver access to admission webhook pod on port 8443" \
      --direction INGRESS



gcloud container clusters get-credentials acme --zone us-central1-c --project bhood-214523

kubectl create ns prometheus
kubectl create ns cwow-sonarqube
kubectl create ns cwow-prometheus


https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip
SETUP DNS and gcp compute static IP address
https://medium.com/faun/dns-and-gke-network-configuration-on-google-cloud-platform-1bfdc74fe2e


Contino GCP 
https://console.cloud.google.com/kubernetes/add?project=bhood-214523
GKE create cluster
acme
1.15.9-gke.9

apiVersion: v1
kind: ServiceAccount
metadata:
  name: helm
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: helm
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: helm
    namespace: kube-system

Cloud shell:
gcloud container clusters get-credentials acme --zone us-central1-c --project bhood-214523
vi helm-sa.yaml
kubectl apply -f helm-sa.yaml


https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip

gcloud compute addresses create helmfile-infra-ip --global
address: 35.241.12.208


https://cloud.google.com/kubernetes-engine/docs/tutorials/http-balancer


https://github.com/kelseyhightower/ingress-with-static-ip
gcloud compute addresses create kubernetes-ingress --global
gcloud compute addresses describe kubernetes-ingress --global
address: 34.107.230.49

https://istio.io/docs/tasks/traffic-management/ingress/ingress-control/
kubectl get svc  -n gke-system istio-ingress

spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  loadBalancerIP: @GKE_STATIC_IP_ADDRESS  # static IP pre-allocated.


https://medium.com/bluekiri/deploy-a-nginx-ingress-and-a-certitificate-manager-controller-on-gke-using-helm-3-8e2802b979ec

helm3 install nginx stable/nginx-ingress --namespace nginx --set rbac.create=true --set controller.publishService.enabled=true
