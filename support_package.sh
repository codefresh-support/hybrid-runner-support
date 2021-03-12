#!/usr/bin/env bash

# Set Runtime Name
RUNTIME=$1

# Set Kubernetes Namespace
NAMESPACE=$2

# Set Date in tha year month day hour minutes seconds
NOW=$(date '+%Y%m%d%H%M%S')

echo "Creating Codefresh temp directory"
mkdir -p codefresh/$NOW
cd codefresh/$NOW

echo "Exporting Nodes Descriptions"
kubectl describe nodes >> node-describe.txt

echo "Gather Pod information in the $NAMESPACE namespace"
kubectl get pods -n $NAMESPACE -o wide >> pod-list.txt

for POD in $(kubectl get pods -n $NAMESPACE --no-headers -o custom-columns=":metadata.name")
do
  mkdir $POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> $POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> $POD/describe.txt
  kubectl logs $POD -n $NAMESPACE >> $POD/logs.log
done

echo "Exporting Codefresh Runtime"
codefresh get runtime-environment $RUNTIME -o json >> cf-runtime.json

echo "Exporting Deployments"
kubectl get deployments -n $NAMESPACE -o yaml >> cf-deployments.yaml

echo "Exporting Storage Class"
STORAGE_CLASS=$(jq .dockerDaemonScheduler.pvcs.dind.storageClassName cf-runtime.json | sed 's/"//g')
kubectl get storageclass $STORAGE_CLASS -o yaml >> cf-storageclass.yaml

echo "Archiving Contents and cleaning up"
cd ../..
tar -czvf codefresh/codefresh-support-$NOW.tar.gz codefresh/$NOW
rm -rf codefresh/$NOW

echo "New Tar Package: codefresh/codefresh-support-$NOW.tar.gz"
echo "Please attach .tar.gz to your support ticket"
