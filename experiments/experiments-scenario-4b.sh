#!/bin/bash

echo "Starting with 3 minutes reconciliation interval ..."

# Keep Flux CD in idle state for 15 minutes
sleep 15m

# fork the following repository https://github.com/argoproj/argocd-example-apps
gh repo fork https://github.com/argoproj/argocd-example-apps.git --clone --default-branch-only

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

echo "Perform a rolling update"

# Update version in git repository
cd argocd-example-apps/
sed -i 's/tag: .*/tag: 0.2/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.2.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.2.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/
git commit -m "Perform a rolling update"
git push

# Perform a rollback 15 after minutes
sleep 15m

echo "Perform a rollback"

# Rollback to a previous version in git repository
sed -i 's/tag: .*/tag: 0.1/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.1.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.1.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/
git commit -m "Rollback to a previous version"
git push
cd ..

# Perform a clean up after 15 after minutes
sleep 15m

echo "Clean up"
flux delete helmrelease guestbook --silent
flux delete source git example-apps --silent
kubectl delete namespace guestbook-fluxcd
gh repo delete $github_username/argocd-example-apps --yes
rm -R -f argocd-example-apps

echo "Starting with 30 minutes reconciliation interval ..."

echo "Re-installing Flux"
flux bootstrap github \
  --owner=$github_username \
  --repository=gitops-energy-tests \
  --path=clusters/my-cluster \
  --private=false \
  --personal=true

# Keep Argo CD in idle state for 15 minutes
sleep 15m

# Fork the following repository https://github.com/argoproj/argocd-example-apps
gh repo fork https://github.com/argoproj/argocd-example-apps.git --clone --default-branch-only

echo "Deploy guestbook application with Flux CD"

# Create a source from a public Git repository master branch
flux create source git guestbook \
  --namespace=flux-system \
  --url=https://github.com/$github_username/argocd-example-apps \
  --branch=master \
  --interval=1800s

# Create a HelmRelease with a chart from a GitRepository source
flux create helmrelease guestbook \
  --namespace=flux-system \
  --release-name=guestbook \
  --source=GitRepository/guestbook.flux-system \
  --chart=./helm-guestbook \
  --target-namespace=guestbook-fluxcd \
  --create-target-namespace=true \
  --interval=1800s

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

# Perform a rollback 15 after minutes
sleep 15m

echo "Perform a rollback"

# Rollback to a previous version in git repository
sed -i 's/tag: .*/tag: 0.1/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.1.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.1.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Rollback to a previous version"
git push
cd ..

# Perform a clean up after 15 after minutes
sleep 15m

echo "Clean up"
flux delete helmrelease guestbook --silent
flux delete source git guestbook --silent
kubectl delete namespace guestbook-fluxcd
gh repo delete $github_username/argocd-example-apps --yes
rm -R -f argocd-example-apps
