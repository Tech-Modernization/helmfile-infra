#!/bin/bash
rm -f certs/*
gcloud kms keyrings create vault --location global
gcloud kms keys create etcd --location global --keyring vault --purpose encryption
gcloud kms keys create init --location global --keyring vault --purpose encryption
./create-etcd-certs.sh
./create-etcd-secrets.sh
