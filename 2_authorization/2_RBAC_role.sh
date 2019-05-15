#!/bin/sh

set -e
set -x

# RBAC
# see "kubernetes in action" p357

DIR=$(cd "$(dirname "$0")"; pwd -P)

# Delete all namespaces with label 'RBAC=role' to make current script idempotent
kubectl delete ns -l RBAC=role

# Create namespaces 'foo' and 'bar' and add label "RBAC=role"
kubectl create ns foo
kubectl create ns bar
kubectl label ns foo bar "RBAC=role"

# Create a deployment and its related service in ns 'foo'
# for example use image dontrebootme/microbot:v1
kubectl create deployment microbot --image=dontrebootme/microbot:v1 -n foo
kubectl expose deployment microbot -n foo --type=NodePort --port=80 --name=microbot-service

# Create pod using image 'luksa/kubectl-proxy', and named 'shell' in ns 'bar'
kubectl run --generator=run-pod/v1 shell --image=luksa/kubectl-proxy -n bar

# Wait for pod bar:shell to be in running state
while true
do
    sleep 2
    STATUS=$(kubectl get pods -n bar shell -o jsonpath="{.status.phase}")
    if [ "$STATUS" = "Running" ]; then
        break
    fi
done

# Access svc 'foo:microbot-service' from pod 'bar:shell'
while ! kubectl exec -it -n bar shell -- curl --connect-timeout 2 microbot-service.foo
do
    echo "Waiting for microbot svc"
    sleep 2
done

# Set the namespace preference to 'foo'
# so that all kubectl command are ran in ns 'foo' by default

# Create pod using image 'luksa/kubectl-proxy', and named 'shell' in ns 'foo'

# Wait for foo:shell to be in running state
while true
do
    sleep 2
    STATUS=$(kubectl get pods -n foo shell -o jsonpath="{.status.phase}")
    if [ "$STATUS" = "Running" ]; then
        break
    fi
done

# Check RBAC is enabled:
# inside foo:shell, curl k8s api server 
# at URL <API_SERVER>:<PORT>/api/v1/namespaces/foo/services

# Study and create role manifest/service-reader.yaml in ns 'foo'

# Create role service-reader.yaml in ns 'bar'
# Use 'kubectl create role' command instead of yaml

# Create a rolebindind 'service-reader-rb' to bind role foo:service-reader
# to sa (i.e. serviceaccount) foo:default

# List service in ns 'foo' from foo:shell

# List service in ns 'foo' from bar:shell

# Use the patch command, and jsonpatch syntax to add bind foo:service-reader to sa bar.default
# See http://jsonpatch.com for examples

# List service in ns 'foo' from bar:shell
