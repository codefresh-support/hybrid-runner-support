#!/bin/bash

# Set Runtime Name

RUNTIME=$1

NAMESPACE=$2

# Set Kubernetes Namespace

NOW=$(date '+%Y%m%d%H%M%S')

echo "Creating codefresh directory"

mkdir -p codefresh/support_package_temp/$NOW

echo "Changing to temp directory"

cd codefresh/support_package_temp/$NOW

echo "Exporting Node Descriptions"

kubectl describe nodes > kube-node-descriptions-$NOW.txt

echo "Exporting Pod List"

kubectl get pods -n $NAMESPACE > kube-pod-list-$NOW.txt

echo "Exporting Pod Descriptions"

kubectl describe pods -n $NAMESPACE > kube-pod-descriptions-$NOW.txt

echo "Exporting Pod Logs"

mkdir pod-logs

kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=venona --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-venona-log-$NOW.log || echo "venona pod not found!"
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=dind --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-dind-log-$NOW.log || echo "did pod not found!"
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=runtime --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-runtime-log-$NOW.log || echo "engine Pod not found!"
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=dind-lv-monitor --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-dind-lv-monitor-log-$NOW.log || echo "engine Pod not found!"
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=dind-volume-provisioner --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-dind-volume-provisioner-$NOW.log || echo "venona pod not found!"
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=monitor --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-monitor-log-$NOW.log || echo "venona pod not found!"
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=runner --no-headers -o custom-columns=":metadata.name") > pod-logs/kube-runner-log-$NOW.log || echo "venona pod not found!"

echo "Exporting Codefresh Runtime"

codefresh get runtime-environment $RUNTIME -o json > cf-runtime-$NOW.json

echo "Exporting Deployments"

kubectl get deployments -n $NAMESPACE -o json > kube-cf-deployments-$NOW.json

echo "Exporting Storage Class"

STORAGE_CLASS=$(jq .dockerDaemonScheduler.pvcs.dind.storageClassName cf-runtime-$NOW.json | sed 's/"//g')

kubectl get storageclass $STORAGE_CLASS -o json > kube-cf-storageclass-$NOW.json

echo "Changing back to root directory"

cd ../../..

echo "Archiving Contents"

tar -czvf codefresh/venona-support-$NOW.tar.gz codefresh/support_package_temp/$NOW

echo "New Tar Package: codefresh/venona-support-$NOW.tar.gz "

echo "Please attach .tar.gz to your support ticket" 
