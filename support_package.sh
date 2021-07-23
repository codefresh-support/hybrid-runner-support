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

# getting RE information. sed is there if more than 1 RE is atatched to an agent
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

  echo "Gather Events for $NAMESPACE namespace"
  kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp >> $NAMESPACE/events.txt

  echo "Gather PVC list for $NAMESPACE namespace"
  kubectl get pvc -n $NAMESPACE -o wide >> $NAMESPACE/pvc-list.txt

  echo "Gather PV list for $NAMESPACE namespace"
  kubectl get pv -l pod_namespace=$NAMESPACE >> $NAMESPACE/pv-list.txt

  echo "Gather Pod information in the $NAMESPACE namespace"
  kubectl get pods -n $NAMESPACE -o wide >> $NAMESPACE/pod-list.txt

  # For codefresh runner init installs
  for POD in $(kubectl get pods -n $NAMESPACE -l 'app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE/$POD
    kubectl get pods $POD -n $NAMESPACE -o yaml >> $NAMESPACE/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE >> $NAMESPACE/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE --all-containers >> $NAMESPACE/$POD/logs.log
  done

  # For helm installs
  for POD in $(kubectl get pods -n $NAMESPACE -l 'codefresh.io/application in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE/$POD
    kubectl get pods $POD -n $NAMESPACE -o yaml >> $NAMESPACE/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE >> $NAMESPACE/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE --all-containers >> $NAMESPACE/$POD/logs.log
  done

  # Additional items from helm installs
  for POD in $(kubectl get pods -n $NAMESPACE -l 'codefresh-app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE/$POD
    kubectl get pods $POD -n $NAMESPACE -o yaml >> $NAMESPACE/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE >> $NAMESPACE/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE --all-containers >> $NAMESPACE/$POD/logs.log
  done

  # getting PVC
  echo "Gather PVC information in the $NAMESPACE namespace"
  for PVC in $(kubectl get pvc -n $NAMESPACE -l 'codefresh-app=dind' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE/$PVC
    kubectl get pvc $PVC -n $NAMESPACE -o yaml >> $NAMESPACE/$PVC/get.yaml
    kubectl describe pvc $PVC -n $NAMESPACE >> $NAMESPACE/$PVC/describe.txt
  done

  # getting PV
  echo "Gather PV information in the $NAMESPACE namespace"
  for PV in $(kubectl get pv -l 'codefresh-app=dind' -l pod_namespace=$NAMESPACE --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE/$PV
    kubectl get pv $PV -o yaml >> $NAMESPACE/$PV/get.yaml
    kubectl describe pv $PV >> $NAMESPACE/$PV/describe.txt
  done

done

if [ -n "$NAMESPACE2" ]; then

  mkdir $NAMESPACE2

  echo "Exporting Deployments in the $NAMESPACE2 namespace"
  kubectl get deployments -n $NAMESPACE2 -o yaml >> $NAMESPACE2/cf-deployments-$NAMESPACE2.yaml

  echo "Exporting Storage Class"
  STORAGE_CLASS=$(jq .dockerDaemonScheduler.pvcs.dind.storageClassName $NAMESPACE2/cf-runtime.json | sed 's/"//g')
  kubectl get storageclass $STORAGE_CLASS -o yaml >> $NAMESPACE2/cf-storageclass.yaml

  echo "Gather Pod information in the $NAMESPACE2 namespace"
  kubectl get pods -n $NAMESPACE2 -o wide >> $NAMESPACE2/pod-list.txt

  echo "Gather Events for $NAMESPACE2 namespace"
  kubectl get events -n $NAMESPACE2 --sort-by=.metadata.creationTimestamp >> $NAMESPACE2/events.txt

  echo "Gather PVC list for $NAMESPACE2 namespace"
  kubectl get pvc -n $NAMESPACE2 -o wide >> $NAMESPACE2/pvc-list.txt

  echo "Gather PV list for $NAMESPACE2 namespace"
  kubectl get pv -l pod_namespace=$NAMESPACE2 >> $NAMESPACE2/pv-list.txt

  echo "Gather Pod information in the $NAMESPACE2 namespace"
  kubectl get pods -n $NAMESPACE2 -o wide >> $NAMESPACE2/pod-list.txt

  # For codefresh runner init installs
  for POD in $(kubectl get pods -n $NAMESPACE2 -l 'app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE2/$POD
    kubectl get pods $POD -n $NAMESPACE2 -o yaml >> $NAMESPACE2/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE2 >> $NAMESPACE2/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE2 --all-containers >> $NAMESPACE2/$POD/logs.log
  done

  # For helm installs
  for POD in $(kubectl get pods -n $NAMESPACE2 -l 'codefresh.io/application in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE2/$POD
    kubectl get pods $POD -n $NAMESPACE2 -o yaml >> $NAMESPACE2/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE2 >> $NAMESPACE2/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE2 --all-containers >> $NAMESPACE2/$POD/logs.log
  done

  # Additional items from helm installs
  for POD in $(kubectl get pods -n $NAMESPACE2 -l 'codefresh-app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE2/$POD
    kubectl get pods $POD -n $NAMESPACE2 -o yaml >> $NAMESPACE2/$POD/get.yaml
    kubectl describe pods $POD -n $NAMESPACE2 >> $NAMESPACE2/$POD/describe.txt
    kubectl logs $POD -n $NAMESPACE2 --all-containers >> $NAMESPACE2/$POD/logs.log
  done

  runtime_env=$(echo $RUNTIME | sed -e 's/\//-/g') #get runtime label

  echo "Gather PVC information in the $NAMESPACE2 namespace"

  for PVC in $(kubectl get pvc -n $NAMESPACE2 -l 'codefresh-app=dind' --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE2/$PVC
    kubectl get pvc $PVC -n $NAMESPACE2 -o yaml >> $NAMESPACE2/$PVC/get.yaml
    kubectl describe pvc $PVC -n $NAMESPACE2 >> $NAMESPACE2/$PVC/describe.txt
  done

  echo "Gather PV information in the $NAMESPACE2 namespace"
  for PV in $(kubectl get pv -l 'codefresh-app=dind' -l pod_namespace=$NAMESPACE2 --no-headers -o custom-columns=":metadata.name")
  do
    mkdir $NAMESPACE2/$PV
    kubectl get pv $PV -o yaml >> $NAMESPACE2/$PV/get.yaml
    kubectl describe pv $PV >> $NAMESPACE2/$PV/describe.txt
  done

fi

# compressing and cleaning up
echo "Archiving Contents and cleaning up"
cd ../..
tar -czvf codefresh/codefresh-support-$NOW.tar.gz codefresh/$NOW
rm -rf codefresh/$NOW

echo "New Tar Package: codefresh/codefresh-support-$NOW.tar.gz"
echo "Please attach .tar.gz to your support ticket"