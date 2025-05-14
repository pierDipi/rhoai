#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ENABLE_KUEUE="${ENABLE_KUEUE:-false}"

echo "=== Installing KEDA ==="
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade --install keda kedacore/keda \
  --namespace keda \
  --create-namespace \
  --wait --timeout 300s

echo "=== Installing Prometheus ==="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install "kube-prometheus-stack"  prometheus-community/kube-prometheus-stack \
  --namespace kube-prometheus \
  --create-namespace \
  --wait --timeout 300s

if [[ "${ENABLE_KUEUE}" == "true" ]]; then
  echo "=== Installing Kueue ==="
  helm upgrade --install kueue oci://registry.k8s.io/kueue/charts/kueue \
    --version=0.11.4 \
    -f "${SCRIPT_DIR}/kueue/values.yaml" \
    --namespace  kueue-system \
    --create-namespace \
    --wait --timeout 300s
  kubectl apply --server-side -f https://github.com/kubernetes-sigs/kueue/releases/download/v0.11.4/prometheus.yaml

  kubectl apply \
    -f "${SCRIPT_DIR}/kueue/100-cluster-queue.yaml" \
    -f "${SCRIPT_DIR}/kueue/200-resource-flavor.yaml" \
    -f "${SCRIPT_DIR}/kueue/300-local-queue.yaml" \
    -f "${SCRIPT_DIR}/kueue/400-kserve-kueue-reader-cluster-role.yaml"
fi

echo "=== Applying inference service ==="

kubectl apply -Rf "${SCRIPT_DIR}/resources"
