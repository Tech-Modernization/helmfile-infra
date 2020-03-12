#!/bin/sh

#https://github.com/roboll/helmfile#environment-secrets

cp secret.yaml.dec environments/ldev/secret.yaml
helm secrets enc environments/ldev/secret.yaml

cp secret.yaml.dec environments/lprod/secret.yaml
helm secrets enc  environments/lprod/secret.yaml

cp secret.yaml.dec environments/gcp/secret.yaml
helm secrets enc  environments/gcp/secret.yaml

echo "update those secrets in git"
