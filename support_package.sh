#!/bin/bash

# Set Runtime Name

RUNTIME=$1

NAMESPACE=$2

# Set Kubernetes Namespace

NOW=$(date '+%Y%m%d%H%M%S')

echo "Creating Support Directory"

mkdir -p codefresh/support_package_temp/$NOW

echo "Changing to Temp Directory"

cd codefresh/support_package_temp/$NOW

echo "Exporting Pod List"

kubectl get pods -n $NAMESPACE > kube-pod-list-$NOW.txt

echo "Exporting pod logs"

kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=venona --no-headers -o custom-columns=":metadata.name") > kube-venona-log-$NOW.log
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=dind --no-headers -o custom-columns=":metadata.name") > kube-venona-log-$NOW.log
kubectl logs -n $NAMESPACE $(kubectl get pods -n $NAMESPACE -l app=runtime --no-headers -o custom-columns=":metadata.name") > kube-venona-log-$NOW.log
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