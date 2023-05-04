#!/bin/bash

# Verify that Grafana is running
kubectl get pod -l app.kubernetes.io/name=grafana -n monitoring
kubectl wait --for=condition=Ready=true pods -l app.kubernetes.io/name=grafana -n monitoring

kubectl port-forward service/grafana 3000:3000 -n monitoring &

