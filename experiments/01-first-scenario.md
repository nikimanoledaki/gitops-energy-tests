# Table of contents
- [GitOps tools setup](#gitops-tools-setup)
  - [Install Argo CD](#install-argo-cd)
  - [Install Flux CD](#install-flux-cd)
- [Deploying guestbook application](#deploying-guestbook-application)
  - [Fork argocd-example-apps repository](#fork-argocd-example-apps-repository)
  - [Deploy the application using Argo CD](#deploy-the-application-using-argo-cd)
  - [Deploy the application using Flux CD](#deploy-the-application-using-flux-cd)
  - [Performing a rolling update](#performing-a-rolling-update)
  - [Performing a rollback](#performing-a-rollback)
  - [Clean up](#clean-up)
- [Deploying podinfo application](#deploying-podinfo-application)
  - [Fork podinfo repository](#fork-podinfo-repository)
  - [Set the initial version](#set-the-initial-version)
  - [Deploy the application using Argo CD](#deploy-the-application-using-argo-cd-1)
  - [Deploy the application using Flux CD](#deploy-the-application-using-flux-cd-1)
  - [Performing a rolling update](#performing-a-rolling-update-1)
  - [Performing a rollback](#performing-a-rollback-1)
  - [Clean up](#clean-up-1)

# GitOps tools setup

## Install Argo CD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
#### Login to Argo CD
```bash
# start a port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get the initial password in another window
PASSWORD=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$PASSWORD

# (Optional) Check the clusters
argocd cluster list
```

## Install Flux CD
```bash
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

# Deploying guestbook application

## Fork argocd-example-apps repository
```bash
gh repo fork https://github.com/argoproj/argocd-example-apps.git
export GITHUB_USERNAME="YOUR_GITHUB_USERNAME"
```

## Deploy the application using Argo CD
```bash
kubectl create namespace guestbook-argocd
argocd app create guestbook \
  --app-namespace argocd \
  --repo https://github.com/$GITHUB_USERNAME/argocd-example-apps.git \
  --path helm-guestbook \
  --release-name guestbook \
  --dest-namespace guestbook-argocd \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --self-heal \
  --auto-prune
```

## Deploy the application using Flux CD
#### Create a source from a public Git repository master branch
```bash
flux create source git guestbook \
  --namespace=flux-system \
  --url=https://github.com/$GITHUB_USERNAME/argocd-example-apps \
  --branch=master \
  --interval=180s
```

#### Create a HelmRelease with a chart from a GitRepository source
```bash
flux create helmrelease guestbook \
  --namespace=flux-system \
  --release-name=guestbook \
  --source=GitRepository/guestbook.flux-system \
  --chart=./helm-guestbook \
  --target-namespace=guestbook-fluxcd \
  --create-target-namespace=true \
  --interval=180s
```

#### (Optional) Check the current deployed image tag
```bash
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'
```

## Performing a rolling update

#### Update the image tag of helm-guestbook in git repository
```bash
git clone https://github.com/$GITHUB_USERNAME/argocd-example-apps.git
cd argocd-example-apps/
sed -i 's/tag: .*/tag: 0.2/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.2.0/' helm-guestbook/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 0.2.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Perform a rolling update"
git push
```

#### (Optional) Check the current deployed image tag
```bash
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'
```

## Performing a rollback

#### Update the image tag of helm-guestbook in git repository
```bash
sed -i 's/tag: .*/tag: 0.1/' helm-guestbook/values.yaml
sed -i 's/version: .*/version: 0.1.0/' helm-guestbook/Chart.yaml
git add helm-guestbook/values.yaml helm-guestbook/Chart.yaml
git commit -m "Rollback to a previous version"
git push
```

#### (Optional) Check the current deployed image tag
```bash
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'
```

## Clean up

#### Delete the application and the namespace
```bash
argocd app delete guestbook
kubectl delete namespace guestbook-argocd
```

#### Delete the GitRepository and HelmRelease
```bash
flux delete helmrelease guestbook
flux delete source git guestbook
kubectl delete namespace guestbook-fluxcd
````

# Deploying podinfo application

## Fork podinfo repository
```bash
gh repo fork https://github.com/stefanprodan/podinfo.git
```

## Set the initial version
```bash
cd ..
git clone https://github.com/$GITHUB_USERNAME/podinfo.git
cd podinfo/
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Update image tag and chart version"
git push
```

## Deploy the application using Argo CD
```bash
kubectl create namespace podinfo-argocd
argocd app create podinfo \
  --app-namespace argocd \
  --repo https://github.com/$GITHUB_USERNAME/podinfo.git \
  --path charts/podinfo \
  --release-name podinfo \
  --dest-namespace podinfo-argocd \
  --dest-server https://kubernetes.default.svc \
  --sync-policy automated \
  --self-heal \
  --auto-prune
```

## Deploy the application using Flux CD
#### Create a source from a public Git repository master branch
```bash
flux create source git podinfo \
  --namespace=flux-system \
  --url=https://github.com/$GITHUB_USERNAME/podinfo \
  --branch=master \
  --interval=180s
```

#### Create a HelmRelease with a chart from a GitRepository source
```bash
flux create helmrelease podinfo \
  --namespace=flux-system \
  --release-name=podinfo \
  --source=GitRepository/podinfo.flux-system \
  --chart=./charts/podinfo \
  --target-namespace=podinfo-fluxcd \
  --create-target-namespace=true \
  --interval=180s
```

#### (Optional) Check the current deployed image tag
```bash
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/podinfo/ {split($2,a,":"); print $1, a[2]}'
```

## Performing a rolling update

#### Update the image tag of podinfo in git repository
```bash
sed -i 's/tag:.*/tag: 6.3.5/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.5/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.5/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Perform a rolling update"
git push
```

#### (Optional) Check the current deployed image tag
```bash
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/podinfo/ {split($2,a,":"); print $1, a[2]}'
````

## Performing a rollback

#### Update the image tag of podinfo in git repository
```bash
sed -i 's/tag:.*/tag: 6.3.4/' charts/podinfo/values.yaml
sed -i 's/version:.*/version: 6.3.4/' charts/podinfo/Chart.yaml
sed -i 's/appVersion:.*/appVersion: 6.3.4/' charts/podinfo/Chart.yaml
git add charts/podinfo/Chart.yaml charts/podinfo/values.yaml
git commit -m "Rollback to a previous version"
git push
```

#### (Optional) Check the current deployed image tag
```bash
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/podinfo/ {split($2,a,":"); print $1, a[2]}'
```
## Clean up

#### Delete the application and the namespace
```bash
argocd app delete podinfo
kubectl delete namespace podinfo-argocd
```

#### Delete the GitRepository and HelmRelease
```bash
flux delete helmrelease podinfo
flux delete source git podinfo
kubectl delete namespace podinfo-fluxcd
```
