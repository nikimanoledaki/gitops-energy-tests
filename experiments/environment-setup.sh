#!/bin/bash

echo "Creating Minikube cluster"
minikube start --cpus 4 --memory 6144

export github_username=$(gh api user --jq .login)

function check_pods_ready() {
  local namespace="$1"

  while true
  do
    # Get new output here
    output=$(kubectl get pods -n "$namespace" --no-headers | awk '{print $2}')

    all_ones=true
    while read -r line; do
      num=$(echo "$line" | cut -d'/' -f1)
      denom=$(echo "$line" | cut -d'/' -f2)
      result=$(echo "$num / $denom" | bc -l)

      if (( $(echo "$result != 1.0" | bc -l) )); then
        all_ones=false
        echo "Waiting for pods to be ready"
        sleep 10
        break
      fi
    done <<< "$output"

    if $all_ones; then
      echo "All pods in $namespace namespace are ready"
      break
    fi
  done
}

echo "Installing kube-prometheus operator"
git clone https://github.com/prometheus-operator/kube-prometheus.git
cd kube-prometheus
kubectl apply --server-side -f manifests/setup
kubectl wait \
  --for condition=Established \
  --all CustomResourceDefinition \
  --namespace=monitoring
kubectl apply -f manifests/
check_pods_ready monitoring

# Remove kube-prometheus manifests
cd ..
rm -R -f kube-prometheus

echo "Installing Kepler"
kubectl apply -f $1/_output/generated-manifest/deployment.yaml
check_pods_ready kepler

if [[ $2 == "argo" ]]; then
    echo "Installing Argo CD"
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    check_pods_ready argocd
elif [[ $2 == "flux" ]]; then
    flux bootstrap github \
      --owner=$github_username \
      --repository=gitops-energy-tests \
      --path=clusters/my-cluster \
      --private=false \
      --personal=true
    check_pods_ready flux-system
else
    echo "Installing Argo CD"
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "Installing Flux CD"
    flux bootstrap github \
      --owner=$github_username \
      --repository=gitops-energy-tests \
      --path=clusters/my-cluster \
      --private=false \
      --personal=true
    check_pods_ready argocd
    check_pods_ready flux-system
fi

if [ "$3" ]; then
    chmod +x $3
    $3
fi
