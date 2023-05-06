#!/bin/bash

echo "Starting with 3 minutes reconciliation interval ..."

# Keep Argo CD in idle state for 15 minutes
sleep 15m

# Start a port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the initial password
password=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$password

# fork the following repository https://github.com/argoproj/argocd-example-apps
gh repo fork https://github.com/argoproj/argocd-example-apps.git --clone --default-branch-only

export github_username=$(gh api user --jq .login)

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
argocd app delete guestbook --yes
kubectl delete namespace guestbook-argocd
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
gh repo delete $github_username/argocd-example-apps --yes
rm -R -f argocd-example-apps

echo "Starting with 30 minutes reconciliation interval ..."

echo "Re-installing Argo CD"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data":{"timeout.reconciliation": "1800s"}}'
kubectl rollout restart deployment argocd-repo-server -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd
kubectl rollout restart statefulset argocd-application-controller -n argocd
kubectl rollout status statefulset argocd-application-controller -n argocd

# Keep Argo CD in idle state for 15 minutes
sleep 15m

# Start a port-forward in another window
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the initial password
password=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$password

# Fork the following repository https://github.com/argoproj/argocd-example-apps
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
argocd app delete guestbook --yes
kubectl delete namespace guestbook-argocd
gh repo delete $github_username/argocd-example-apps --yes
rm -R -f argocd-example-apps
