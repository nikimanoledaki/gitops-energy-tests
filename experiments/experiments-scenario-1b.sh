#!/bin/bash

# Keep Argo CD and Flux CD in idle state for 15 minutes
sleep 15m

# Start a port-forward in another window
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the initial password
password=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$password

# fork the following repository https://github.com/stefanprodan/podinfo
gh repo fork https://github.com/stefanprodan/podinfo.git --clone --default-branch-only

export github_username=$(gh api user --jq .login)

# Start with the first version
cd podinfo/
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Update image tag and chart version"
git push

echo "Deploy podinfo application with Argo CD"

kubectl create namespace podinfo-argocd
argocd app create podinfo \
  --app-namespace argocd \
  --repo https://github.com/$github_username/podinfo.git \
  --path charts/podinfo \
  --release-name podinfo \
  --dest-namespace podinfo-argocd \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --self-heal \
  --auto-prune

echo "Deploy podinfo application with Flux CD"

# Create a source from a public Git repository master branch
flux create source git podinfo \
  --namespace=flux-system \
  --url=https://github.com/$github_username/podinfo \
  --branch=master \
  --interval=180s

# Create a HelmRelease with a chart from a GitRepository source
flux create helmrelease podinfo \
  --namespace=flux-system \
  --release-name=podinfo \
  --source=GitRepository/podinfo.flux-system \
  --chart=./charts/podinfo \
  --target-namespace=podinfo-fluxcd \
  --create-target-namespace=true \
  --interval=180s

# Perform a rolling update after 15 minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/podinfo/ {split($2,a,":"); print $1, a[2]}'

echo "Perform a rolling update"

# Update version in git repository
sed -i 's/tag:.*/tag: 6.3.5/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.5/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.5/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Perform a rolling update"
git push

# Perform a rollback 15 after minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/podinfo/ {split($2,a,":"); print $1, a[2]}'

echo "Perform a rollback"

# Rollback to a previous version in git repository
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Rollback to a previous version"
git push

# Perform a clean up after 15 after minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/podinfo/ {split($2,a,":"); print $1, a[2]}'

echo "Clean up"
# Delete the ApplicationSet and the namespaces
argocd app delete podinfo --yes
kubectl delete namespace podinfo-argocd

flux delete helmrelease podinfo --silent
flux delete source git podinfo --silent
kubectl delete namespace podinfo-fluxcd

gh repo delete $github_username/podinfo --yes
cd ..
rm -R -f podinfo
