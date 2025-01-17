#!/bin/sh

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install \
  -n cert-manager \
  --version v1.11.0-beta.1 \
  cert-manager \
  jetstack/cert-manager \
  --create-namespace \
  --set installCRDs=true
