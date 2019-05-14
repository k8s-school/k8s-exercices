#!/bin/sh

set -e

kubectl delete pod,service -l "app=nginx" -n logging

# Exercice: create a nginx pod + service in namespace 'loggin'
kubectl run nginx --generator=run-pod/v1 --image=nginx -n logging
kubectl label pod -n logging nginx "app=nginx"
kubectl create service clusterip -n logging nginx --tcp 80

# Wait for logging:nginx to be in running state
while true
do
    sleep 2
    STATUS=$(kubectl get pods -n logging nginx -o jsonpath="{.status.phase}")
    if [ "$STATUS" = "Running" ]; then
        break
    fi
done

# Connect to nginx service to generate logs
kubectl run --generator=run-pod/v1 -n logging loggenerator --image=busybox -- sh -c "while true; do wget http://nginx:80; rm index.html; sleep 2; done"
