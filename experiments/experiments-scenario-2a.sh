#!/bin/bash

echo "Starting with Monorepo scenario ..."

# Keep Argo CD in idle state for 15 minutes
sleep 15m

# Start a port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the initial password
password=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$password

echo "Create a git repo to host two Helm charts"

# Clone the repositories
git clone https://github.com/stefanprodan/podinfo.git
git clone https://github.com/argoproj/argocd-example-apps.git

export github_username=$(gh api user --jq .login)

# Create a new repository named example-apps
mkdir example-apps
cd example-apps
git init --initial-branch=main
cp -r ../argocd-example-apps/helm-guestbook .
cp -r ../podinfo/charts/podinfo .
sed -i 's/tag:.*/tag: 6.3.4/' podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' podinfo/Chart.yaml
git add helm-guestbook/ podinfo/
git commit -m "Add charts"
gh repo create example-apps --public
git remote add origin https://github.com/$github_username/example-apps.git
git push --set-upstream origin main

echo "Deploy guestbook application with Argo CD"

kubectl create namespace guestbook-argocd
argocd app create guestbook \
  --app-namespace argocd \
  --repo https://github.com/$github_username/example-apps.git \
  --path helm-guestbook \
  --release-name guestbook \
  --dest-namespace guestbook-argocd \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --self-heal \
  --auto-prune

echo "Deploy podinfo application with Argo CD"

kubectl create namespace podinfo-argocd
argocd app create podinfo \
  --app-namespace argocd \
  --repo https://github.com/$github_username/example-apps.git \
  --path podinfo \
  --release-name podinfo \
  --dest-namespace podinfo-argocd \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --self-heal \
  --auto-prune
  
# Perform a rolling update after 15 minutes
sleep 15m

echo "Perform a rolling update"

# Update version in git repository
sed -i 's/tag: .*/tag: 0.2/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.2.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.2.0/' helm-guestbook/Chart.yaml
sed -i 's/tag:.*/tag: 6.3.5/' podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.5/' podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.5/' podinfo/Chart.yaml
git .
git commit -m "Perform a rolling update"
git push

# Perform a rollback 15 after minutes
sleep 15m

echo "Perform a rollback"

# Rollback to a previous version in git repository
sed -i 's/tag: .*/tag: 0.1/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.1.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.1.0/' helm-guestbook/Chart.yaml
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add .
git commit -m "Rollback to a previous version"
git push
cd ..

# Perform a clean up after 15 after minutes
sleep 15m

echo "Clean up"
argocd app delete guestbook --yes
argocd app delete podinfo --yes
kubectl delete namespace guestbook-argocd
kubectl delete namespace podinfo-argocd
gh repo delete $github_username/example-apps --yes
rm -R -f example-apps

echo "Starting with Multirepo scenario ..."

# Fork the following repository https://github.com/argoproj/argocd-example-apps
gh repo fork https://github.com/argoproj/argocd-example-apps.git --clone --default-branch-only

# Fork the following repository https://github.com/stefanprodan/podinfo
gh repo fork https://github.com/stefanprodan/podinfo.git --clone --default-branch-only
 
# Start with the first version
cd podinfo/
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Update image tag and chart version"
git push
cd ..

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

# Perform a rolling update after 15 minutes
sleep 15m

echo "Perform a rolling update"

# Update version in git repository
cd argocd-example-apps/
sed -i 's/tag: .*/tag: 0.2/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.2.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.2.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Perform a rolling update"
git push
cd ..

# Update version in git repository
cd podinfo/
sed -i 's/tag:.*/tag: 6.3.5/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.5/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.5/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Perform a rolling update"
git push
cd ..

# Perform a rollback 15 after minutes
sleep 15m

echo "Perform a rollback"

# Rollback to a previous version in git repository
cd argocd-example-apps/
sed -i 's/tag: .*/tag: 0.1/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.1.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.1.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Rollback to a previous version"
git push
cd ..

# Rollback to a previous version in git repository
cd podinfo/
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Rollback to a previous version"
git push
cd ..

# Perform a clean up after 15 after minutes
sleep 15m

echo "Clean up"
argocd app delete guestbook --yes
argocd app delete podinfo --yes
kubectl delete namespace guestbook-argocd
kubectl delete namespace podinfo-argocd
gh repo delete $github_username/argocd-example-apps --yes
gh repo delete $github_username/podinfo --yes
rm -R -f podinfo
rm -R -f argocd-example-apps
