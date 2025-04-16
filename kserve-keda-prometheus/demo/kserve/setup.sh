#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo "=== Installing KEDA ==="
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda --namespace keda --create-namespace

echo "=== Installing Prometheus ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install "kube-prometheus-stack"  prometheus-community/kube-prometheus-stack --namespace kube-prometheus --create-namespace

echo "=== Waiting for Prometheus and KEDA to become ready ==="
kubectl wait deployments --namespace kube-prometheus -l "release=kube-prometheus-stack" --for=condition=available
kubectl wait pods --namespace kube-prometheus -l "release=kube-prometheus-stack" --for=condition=ready
kubectl wait deployments --namespace keda --for=condition=available --all

echo "=== Applying inference service ==="

kubectl apply -Rf "${SCRIPT_DIR}/resources"
