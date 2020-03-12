#!/bin/sh

kubectl create configmap $1 --namespace=myapp-prometheus --from-file=./$1/ --dry-run=true -o yaml | kubectl apply -f -
kubectl label configmap $1 --namespace=myapp-prometheus --overwrite=true grafana_dashboard="1"
