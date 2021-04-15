#!/usr/bin/env bash

# Set Runtime Name
RUNTIME=$1
NAMESPACE2=$2

# Set Date in tha year month day hour minutes seconds
NOW=$(date '+%Y%m%d%H%M%S')

# setting work directory
echo "Creating Codefresh temp directory"
mkdir -p codefresh/$NOW
cd codefresh/$NOW

# getting node information
echo "Exporting Nodes Descriptions"
kubectl describe nodes >> nodes.txt

# getting RE information
for RENV in $(codefresh get agents --sc runtimes | grep $RUNTIME | sed -e $'s/,/\\\n/g')
do
  NAMESPACE=$(codefresh get runtime-environments $RENV -o json | jq --raw-output '.dockerDaemonScheduler.cluster.namespace')
  mkdir $NAMESPACE

  echo "Exporting Codefresh Runtime"
  codefresh get runtime-environment $RENV -o json >> $NAMESPACE/cf-runtime.json

  echo "Exporting Storage Class"
  STORAGE_CLASS=$(jq .dockerDaemonScheduler.pvcs.dind.storageClassName $NAMESPACE/cf-runtime.json | sed 's/"//g')
  kubectl get storageclass $STORAGE_CLASS -o yaml >> $NAMESPACE/cf-storageclass.yaml

  echo "Exporting Deployments in the $NAMESPACE namespace"
  kubectl get deployments -n $NAMESPACE -o yaml >> $NAMESPACE/cf-deployments.yaml

  echo "Gather Pod information in the $NAMESPACE namespace"
  kubectl get pods -n $NAMESPACE -o wide >> $NAMESPACE/pod-list.txt

  for POD in $(kubectl get pods -n $NAMESPACE -l 'app in (dind, dind-lv-monitor, dind-volume-provisioner, runtime, monitor, runner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE/$POD
    kubectl get pods $POD -n $NAMESPACE -o yaml >> $NAMESPACE/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE >> $NAMESPACE/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE --all-containers >> $NAMESPACE/$POD/logs.log
  done

done

if [ -n "$NAMESPACE2" ]; then

  mkdir $NAMESPACE2

  echo "Exporting Deployments in the $NAMESPACE2 namespace"
  kubectl get deployments -n $NAMESPACE2 -o yaml >> $NAMESPACE2/cf-deployments-$NAMESPACE2.yaml

  echo "Gather Pod information in the $NAMESPACE2 namespace"
  kubectl get pods -n $NAMESPACE2 -o wide >> $NAMESPACE2/pod-list.txt

  for POD in $(kubectl get pods -n $NAMESPACE2 -l 'app in (dind, dind-lv-monitor, dind-volume-provisioner, runtime, monitor, runner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE2/$POD
    kubectl get pods $POD -n $NAMESPACE2 -o yaml >> $NAMESPACE2/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE2 >> $NAMESPACE2/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE2 --all-containers >> $NAMESPACE2/$POD/logs.log
  done
fi


# compressing and cleaning up
echo "Archiving Contents and cleaning up"
cd ../..
tar -czvf codefresh/codefresh-support-$NOW.tar.gz codefresh/$NOW
rm -rf codefresh/$NOW

echo "New Tar Package: codefresh/codefresh-support-$NOW.tar.gz"
echo "Please attach .tar.gz to your support ticket"
