#!/usr/bin/env bash

RENV=$1
NOW=$(date '+%Y%m%d%H%M%S')

echo "Creating Codefresh Temp Directory"
mkdir -p codefresh-$NOW
cd codefresh-$NOW

echo "Gathering Codefresh Runtime Information"
codefresh get runtime-environment $RENV -o json > cf-runtime.json
NAMESPACE=$(jq --raw-output '.dockerDaemonScheduler.cluster.namespace' cf-runtime.json)
STORAGE_CLASS=$(jq --raw-output .dockerDaemonScheduler.pvcs.dind.storageClassName cf-runtime.json)
kubectl describe nodes > nodes.txt
kubectl get storageclass $STORAGE_CLASS -o yaml > storageClass.yaml
kubectl get deployments -n $NAMESPACE -o yaml > deployments.yaml
kubectl get daemonsets -n $NAMESPACE -o yaml > daemonsets.yaml
kubectl get service -n $NAMESPACE -o yaml > services.yaml
kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp > events.txt
kubectl get persistentvolume -l pod_namespace=$NAMESPACE -o wide > persistentVolume-list.txt
kubectl get persistentvolumeclaim -n $NAMESPACE -o wide > persistentVolumeClaim-list.txt
kubectl get pods -n $NAMESPACE -o wide > pod-list.txt

echo "Gathering Hybrid Runner Information in $NAMESPACE namepspace"

for PVC in $(kubectl get persistentvolumeclaim -n $NAMESPACE -l codefresh-app=dind --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p persistentVolumeClaim/$PVC
  kubectl get persistentvolumeclaim $PVC -n $NAMESPACE -o yaml > persistentVolumeClaim/$PVC/get.yaml
  kubectl describe persistentvolumeclaim $PVC -n $NAMESPACE > persistentVolumeClaim/$PVC/describe.txt
done

for PV in $(kubectl get persistentvolume -l codefresh-app=dind -l pod_namespace=$NAMESPACE --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p persistentVolume/$PV
  kubectl get persistentvolume $PV -o yaml > persistentVolume/$PV/get.yaml
  kubectl describe persistentvolume $PV > persistentVolume/$PV/describe.txt
done

# For codefresh runner init installs
for POD in $(kubectl get pods -n $NAMESPACE -l 'app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  kubectl logs $POD -n $NAMESPACE --all-containers >> pods/$POD/logs.log
done

# For helm installs
for POD in $(kubectl get pods -n $NAMESPACE -l 'codefresh.io/application in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  kubectl logs $POD -n $NAMESPACE --all-containers >> pods/$POD/logs.log
done

# Additional items from helm installs
for POD in $(kubectl get pods -n $NAMESPACE -l 'codefresh-app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  kubectl logs $POD -n $NAMESPACE --all-containers >> pods/$POD/logs.log
done

echo "Archiving Contents and cleaning up"
cd ..
tar -czf codefresh-support-$NOW.tar.gz codefresh-$NOW
rm -rf codefresh-$NOW

echo "New Tar Package: codefresh-support-$NOW.tar.gz"
echo "Please attach codefresh-support-$NOW.tar.gz to your support ticket"