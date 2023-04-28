# Utilities
The following utilities need to be installed in order to follow Kepler installation guide:

- Go
- Make
- Docker
- kubectl
- Helm

# Installation Steps

## Installing Go

```bash
sudo apt install golang-go
```

## Installing Make

```bash
sudo apt install make
```

## Installing Docker 

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release 
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
```

## Installing kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Installing Helm

```bash
tar -zxvf helm-v3.11.0-linux-amd64.tar.gz 
sudo mv linux-amd64/helm /usr/local/bin/helm
```
