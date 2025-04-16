## Upstream KServe

### Prerequisites

- Install KServe

### Run setup

```shell
./kserve/setup.sh
```

### Notes and useful commands

```shell
kubectl port-forward svc/huggingface-fbopt-predictor 8080:80

NAMESPACE="default"
METRIC_NAME="s0-prometheus"
SCALED_OBJECT_NAME="huggingface-fbopt-predictor"
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/${NAMESPACE}/${METRIC_NAME}?labelSelector=scaledobject.keda.sh%2Fname%3D${SCALED_OBJECT_NAME}"

curl -XPOST -H "Content-Type: application/json" -d '{"model": "fbopt", "prompt": "Write a poem about colors", "stream": false, "max_tokens": 400}' http://localhost:8080/openai/v1/completions | jq

hey -z 300s -c 10 -m POST -host ${SERVICE_HOSTNAME} -H "Content-Type: application/json" -d '{"model": "fbopt", "prompt": "Write a poem about colors", "stream": false, "max_tokens": 100}' http://localhost:8080/openai/v1/completions
```

## OpenShift CMA (regular deployment)

### Setup
```shell
# Enable UWM.
# add `enableUserWorkload: true` to `config.yaml`
kubectl -n openshift-monitoring edit configmap cluster-monitoring-config
kubectl apply -f ./docs/samples/keda-prometheus/rhoai/uwm.yaml

# Install CMA
kubectl apply -f ./docs/samples/keda-prometheus/rhoai/cma.yaml
# After waiting for operator to be installed
kubectl apply -f ./docs/samples/keda-prometheus/rhoai/keda-controller.yaml

kubectl apply -f ./docs/samples/keda-prometheus/rhoai/test.yaml

APP_URL=$(oc get routes -n kserve-keda-prometheus sample-app-route -o jsonpath='{.status.ingress[0].host}')
hey -z 50s -c 20 -m GET $APP_URL
```

### View HPA Metrics

```shell
kubectl get --raw "/apis/external.metrics.k8s.io/v1beta1/namespaces/kserve-keda-prometheus/s0-prometheus?labelSelector=scaledobject.keda.sh%2Fname%3Dsample-app-scaler" | jq
```