#!/usr/bin/env bash

# Set Runtime Name
RUNTIME=$1

# Set Kubernetes Namespace
NAMESPACE=$2

# Set Date
NOW=$(date '+%Y%m%d%H%M%S')


echo "Creating Codefresh temp directory"
mkdir -p codefresh/$NOW

echo "Changing to temp directory"
cd codefresh/$NOW

echo "Exporting Nodes Descriptions"
kubectl describe nodes >> kube-node-descriptions-$NOW.txt

echo "Exporting Pod List"
kubectl get pods -n $NAMESPACE -o wide >> kube-pod-list-$NOW.txt
echo " " >> kube-pod-list-$NOW.txt
kubectl get pods -n $NAMESPACE -o yaml >> kube-pod-list-$NOW.txt

echo "Exporting Pod Descriptions"
kubectl describe pods -n $NAMESPACE >> kube-pod-descriptions-$NOW.txt

echo "Exporting Pod Logs"
mkdir pod-logs

kubectl logs -n $NAMESPACE -l app=venona >> pod-logs/kube-venona-log-$NOW.log || echo "venona pod not found!"
kubectl logs -n $NAMESPACE -l app=dind >> pod-logs/kube-dind-log-$NOW.log || echo "dind pod not found!"
kubectl logs -n $NAMESPACE -l app=runtime >> pod-logs/kube-runtime-log-$NOW.log || echo "runtime pod not found!"
kubectl logs -n $NAMESPACE -l app=dind-lv-monitor >> pod-logs/kube-dind-lv-monitor-log-$NOW.log || echo "dind lv monitor pod not found!"
kubectl logs -n $NAMESPACE -l app=dind-volume-provisioner >> pod-logs/kube-dind-volume-provisioner-$NOW.log || echo "dind volume provisioner pod not found!"
kubectl logs -n $NAMESPACE -l app=monitor >> pod-logs/kube-monitor-log-$NOW.log || echo "monitor pod not found!"
kubectl logs -n $NAMESPACE -l app=runner >> pod-logs/kube-runner-log-$NOW.log || echo "runner pod not found!"

echo "Exporting Codefresh Runtime"
codefresh get runtime-environment $RUNTIME -o json >> cf-runtime-$NOW.json

echo "Exporting Deployments"
kubectl get deployments -n $NAMESPACE -o yaml >> kube-cf-deployments-$NOW.yaml

echo "Exporting Storage Class"
STORAGE_CLASS=$(jq .dockerDaemonScheduler.pvcs.dind.storageClassName cf-runtime-$NOW.json | sed 's/"//g')

kubectl get storageclass $STORAGE_CLASS -o yaml >> kube-cf-storageclass-$NOW.yaml

echo "Archiving Contents and cleaning up"
cd ../..
tar -czvf codefresh/codefresh-support-$NOW.tar.gz codefresh/$NOW
rm -rf codefresh/$NOW

echo "New Tar Package: codefresh/codefresh-support-$NOW.tar.gz"

echo "Please attach .tar.gz to your support ticket"
