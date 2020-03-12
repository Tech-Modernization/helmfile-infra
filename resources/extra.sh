#!/bin/sh

kubectl create configmap extra-configmap --namespace=myapp-prometheus --from-file=./extra --dry-run=true -o yaml | kubectl apply -f -
