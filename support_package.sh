#!/usr/bin/env bash

# Set Runtime Name
RUNTIME=$1

# Set Kubernetes Namespace
NAMESPACE1=$2

if [ -n "$3" ]; then
  NAMESPACE2=$3
else
  echo "Only 1 namespace provided"
fi

# Set Date in tha year month day hour minutes seconds
NOW=$(date '+%Y%m%d%H%M%S')

# setting work directory

echo "Creating Codefresh temp directory"
mkdir -p codefresh/$NOW
cd codefresh/$NOW

# getting node information

echo "Exporting Nodes Descriptions"
kubectl describe nodes >> node-describe.txt

# First Namespace

echo "Exporting Deployments in the $NAMESPACE1 namespace"
kubectl get deployments -n $NAMESPACE1 -o yaml >> cf-deployments-$NAMESPACE1.yaml

echo "Gather Pod information in the $NAMESPACE1 namespace"
kubectl get pods -n $NAMESPACE1 -o wide >> pod-list-$NAMESPACE1.txt

for POD in $(kubectl get pods -n $NAMESPACE1 -l 'app in (dind, dind-lv-monitor, dind-volume-provisioner, runtime, monitor, runner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir $POD
  kubectl get pods $POD -n $NAMESPACE1 -o yaml >> $POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE1 >> $POD/describe.txt
  kubectl logs $POD -n $NAMESPACE1 --all-containers >> $POD/logs.log
done

# Second Namespace

if [ -n "$NAMESPACE2" ]; then
  echo "Exporting Deployments in the $NAMESPACE2 namespace"
  kubectl get deployments -n $NAMESPACE2 -o yaml >> cf-deployments-$NAMESPACE2.yaml

  echo "Gather Pod information in the $NAMESPACE2 namespace"
  kubectl get pods -n $NAMESPACE2 -o wide >> pod-list-$NAMESPACE2.txt

  for POD in $(kubectl get pods -n $NAMESPACE2 -l 'app in (dind, dind-lv-monitor, dind-volume-provisioner, runtime, monitor, runner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $POD
    kubectl get pods $POD -n $NAMESPACE2 -o yaml >> $POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE2 >> $POD/describe.txt
    kubectl logs $POD -n $NAMESPACE2 --all-containers >> $POD/logs.log
  done
else
  echo "Only 1 namespace provided"
fi

# runtime and storage class

echo "Exporting Codefresh Runtime"
codefresh get runtime-environment $RUNTIME -o json >> cf-runtime.json

echo "Exporting Storage Class"
STORAGE_CLASS=$(jq .dockerDaemonScheduler.pvcs.dind.storageClassName cf-runtime.json | sed 's/"//g')
kubectl get storageclass $STORAGE_CLASS -o yaml >> cf-storageclass.yaml

# compressing and cleaning up

echo "Archiving Contents and cleaning up"
cd ../..
tar -czvf codefresh/codefresh-support-$NOW.tar.gz codefresh/$NOW
rm -rf codefresh/$NOW

echo "New Tar Package: codefresh/codefresh-support-$NOW.tar.gz"
echo "Please attach .tar.gz to your support ticket"
