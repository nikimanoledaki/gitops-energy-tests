#!/bin/bash

# Keep Argo CD in idle state for 15 minutes
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
# Delete the ApplicationSet and the namespaces
argocd app delete guestbook --yes
kubectl delete namespace guestbook-argocd
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd

echo "Re-installing Argo CD"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Keep Argo CD in idle state for 15 minutes
sleep 15m

# Start a port-forward in another window
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Get the initial password
password=$(argocd admin initial-password -n argocd | head -n 1 | awk '{print $NF}')

# Login to ArgoCD
argocd login localhost:8080 --insecure --username=admin --password=$password

# Get a list of cluster names
clusters=$(kubectl config get-contexts -o name)

# Loop through each cluster name
for cluster in $clusters; do
  # Check if the cluster name is not minikube
  if [ "$cluster" != "minikube" ]; then
    # Run argocd cluster add <clustername> --yes
    argocd cluster add $cluster --yes
  fi
done

echo "Deploy guestbook application"

# Define the contents of the ApplicationSet
cat <<EOF > guestbook-applicationset.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: guestbook
  namespace: argocd
spec:
  generators:
  - clusters: {} # Automatically use all clusters defined within Argo CD
  template:
    metadata:
      name: '{{name}}-guestbook' # 'name' field of the Secret
    spec:
      project: "default"
      source:
        repoURL: https://github.com/$github_username/argocd-example-apps/
        targetRevision: HEAD
        path: helm-guestbook
      destination:
        server: '{{server}}' # 'server' field of the secret
        namespace: guestbook-argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
EOF

# Run the command to create the ApplicationSet
argocd appset create guestbook-applicationset.yaml

# Perform a rolling update after 15 minutes
sleep 15m

echo "The current deployed image(s) tag is:"
kubectl get pods --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,IMAGE:.spec.containers[].image' | awk '/guestbook/ {split($2,a,":"); print $1, a[2]}'

echo "Perform a rolling update"

# Update version in git repository
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

# Delete the ApplicationSet and the namespaces
argocd appset delete guestbook --yes

# get the list of clusters
clusters=$(kubectl config get-contexts -o name)

# Loop through each cluster name
for cluster in $clusters
do
	# Check if the cluster name is not minikube
	if [ "$cluster" != "minikube" ]
	then
		# Run argocd cluster add <clustername> --yes
		argocd cluster rm $cluster --yes
	fi
done

# iterate over each cluster and switch to it
for cluster in $clusters
do
    echo "Switching to cluster: $cluster"
    kubectl config use-context $cluster

    # check if the namespace exists and delete it if it does
    namespace=$(kubectl get ns | grep guestbook-argocd | awk '{print $1}')
    if [ ! -z "$namespace" ]
    then
        echo "Deleting namespace: $namespace"
        kubectl delete ns $namespace
    else
        echo "Namespace guestbook-argocd does not exist"
    fi
done

gh repo delete $github_username/argocd-example-apps --yes
cd ..
rm -R -f argocd-example-apps
