#!/bin/bash

# Keep Argo CD and Flux CD in idle state for 15 minutes
sleep 15m

# Start a port-forward in another window
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the initial password
password=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$password

# fork the following repository https://github.com/argoproj/argocd-example-apps
gh repo fork https://github.com/argoproj/argocd-example-apps.git --clone --default-branch-only

echo "Deploy guestbook application with Argo CD"

kubectl create namespace guestbook-argocd
argocd app create guestbook \
  --app-namespace argocd \
  --repo https://github.com/$github_username/argocd-example-apps.git \
  --path helm-guestbook \
  --release-name guestbook \
  --dest-namespace guestbook-argocd \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --self-heal \
  --auto-prune

echo "Deploy guestbook application with Flux CD"

# Create a source from a public Git repository master branch
flux create source git guestbook \
  --namespace=flux-system \
  --url=https://github.com/$github_username/argocd-example-apps \
  --branch=master \
  --interval=180s

# Create a HelmRelease with a chart from a GitRepository source
flux create helmrelease guestbook \
  --namespace=flux-system \
  --release-name=guestbook \
  --source=GitRepository/guestbook.flux-system \
  --chart=./helm-guestbook \
  --target-namespace=guestbook-fluxcd \
  --create-target-namespace=true \
  --interval=180s

# Perform a rolling update after 15 minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'

echo "Perform a rolling update"

# Update version in git repository
cd argocd-example-apps/
sed -i 's/tag: .*/tag: 0.2/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.2.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.2.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Perform a rolling update"
git push

# Perform a rollback 15 after minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'

echo "Perform a rollback"

# Rollback to a previous version in git repository
sed -i 's/tag: .*/tag: 0.1/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.1.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.1.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Rollback to a previous version"
git push

# Perform a clean up after 15 after minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'

echo "Clean up"
# Delete the Applications and the namespaces
argocd app delete guestbook --yes
kubectl delete namespace guestbook-argocd

flux delete helmrelease guestbook --silent
flux delete source git guestbook --silent
kubectl delete namespace guestbook-fluxcd

gh repo delete $github_username/argocd-example-apps --yes
cd ..
rm -R -f argocd-example-apps
