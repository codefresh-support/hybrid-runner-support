#!/usr/bin/env bash

RENV=$1
if [ -z "$RENV" ]
then
  echo "Please pass RE name as the first argument"
  echo "Example: './support_package.sh my-runtime'"
  exit 1
fi
NOW=$(date '+%Y%m%d%H%M%S')

echo "Creating Codefresh Temp Directory"
mkdir -p codefresh-$NOW
cd codefresh-$NOW

echo "Gathering Codefresh Runtime Information"
codefresh get runtime-environment $RENV -o json > cf-runtime.json
if [ $? -ne 0 ]
then
  echo "Unable to get runtime environment, please check the error above and try one more time"
  echo "Cleaning up and exiting"
  cd ..
  rm -rf codefresh-$NOW
  exit 1
fi

NAMESPACE=$(jq --raw-output '.dockerDaemonScheduler.cluster.namespace' cf-runtime.json)
STORAGE_CLASS=$(jq --raw-output .dockerDaemonScheduler.pvcs.dind.storageClassName cf-runtime.json)

echo "Describing nodes..."
kubectl describe nodes > nodes.txt
echo "Getting storage class..."
kubectl get storageclass $STORAGE_CLASS -o yaml > storageClass.yaml
echo "Getting deployments..."
kubectl get deployments -n $NAMESPACE -o yaml > deployments.yaml
echo "Getting daemonsets..."
kubectl get daemonsets -n $NAMESPACE -o yaml > daemonsets.yaml
echo "Getting services..."
kubectl get service -n $NAMESPACE -o yaml > services.yaml
echo "Getting events..."
kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp > events.txt
echo "Getting persistent volumes..."
kubectl get persistentvolume -l pod_namespace=$NAMESPACE -o wide > persistentVolume-list.txt
echo "Getting persistent volume claims..."
kubectl get persistentvolumeclaim -n $NAMESPACE -o wide > persistentVolumeClaim-list.txt
echo "Getting pods..."
kubectl get pods -n $NAMESPACE -o wide > pod-list.txt
echo "Getting cronjobs..."
kubectl get cronjob -l app=dind-volume-cleanup -n $NAMESPACE -o yaml > cronjob-out.yaml

echo "Gathering Hybrid Runner Information in $NAMESPACE namespace"

PVCS_COUNT=$(kubectl get persistentvolumeclaim -n $NAMESPACE -l codefresh-app=dind -o json | jq '.items | length')
echo "Gathering detailed info about PVCs (total: $PVCS_COUNT)..."
for PVC in $(kubectl get persistentvolumeclaim -n $NAMESPACE -l codefresh-app=dind --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p persistentVolumeClaim/$PVC
  kubectl get persistentvolumeclaim $PVC -n $NAMESPACE -o yaml > persistentVolumeClaim/$PVC/get.yaml
  kubectl describe persistentvolumeclaim $PVC -n $NAMESPACE > persistentVolumeClaim/$PVC/describe.txt
done

PVS_COUNT=$(kubectl get persistentvolume -l codefresh-app=dind -l pod_namespace=$NAMESPACE -o json | jq '.items | length')
echo "Gathering detailed info about PVs (total: $PVS_COUNT)..."
for PV in $(kubectl get persistentvolume -l codefresh-app=dind -l pod_namespace=$NAMESPACE --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p persistentVolume/$PV
  kubectl get persistentvolume $PV -o yaml > persistentVolume/$PV/get.yaml
  kubectl describe persistentvolume $PV > persistentVolume/$PV/describe.txt
done

# For codefresh runner init installs
PODS_INIT_COUNT=$(kubectl get pods -n $NAMESPACE -l 'app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' -o json | jq '.items | length')
echo "Gathering detailed info about pods, 'runner init' installs (total: $PODS_INIT_COUNT)..."
for POD in $(kubectl get pods -n $NAMESPACE -l 'app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  kubectl logs $POD -n $NAMESPACE --timestamps --all-containers >> pods/$POD/logs.log
done

# For helm installs
PODS_HELM_COUNT1=$(kubectl get pods -n $NAMESPACE -l 'codefresh.io/application in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' -o json | jq '.items | length')
echo "Gathering detailed info about pods, Helm installs (total: $PODS_HELM_COUNT1)..."
for POD in $(kubectl get pods -n $NAMESPACE -l 'codefresh.io/application in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  kubectl logs $POD -n $NAMESPACE --timestamps --all-containers >> pods/$POD/logs.log
done

# Additional items from helm installs
PODS_HELM_COUNT2=$(kubectl get pods -n $NAMESPACE -l 'codefresh-app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' -o json | jq '.items | length')
echo "Gathering detailed info about pods, Helm installs — additional (total: $PODS_HELM_COUNT2)..."
for POD in $(kubectl get pods -n $NAMESPACE -l 'codefresh-app in (app-proxy, dind, dind-lv-monitor, dind-volume-provisioner, dind-volume-cleanup, runtime, runner, monitor, venona, volume-provisioner-monitor, volume-provisioner)' --no-headers -o custom-columns=":metadata.name")
do
  mkdir -p pods/$POD
  kubectl get pods $POD -n $NAMESPACE -o yaml >> pods/$POD/get.yaml
  kubectl describe pods $POD -n $NAMESPACE >> pods/$POD/describe.txt
  kubectl logs $POD -n $NAMESPACE --timestamps --all-containers >> pods/$POD/logs.log
done

# cli installation doesn't add `app=dind-volume-cleanup` label into `.spec.jobTemplate.spec.template.metadata`
# so had to use `--show-labels` with `grep`
JOBS=( $(kubectl get job --show-labels -n $NAMESPACE | grep -E 'job-name=dind-volume-cleanup-.*' | awk '{print $1}') )
for JOB in "${JOBS[@]}"
do
  WORKDIR=jobs/$JOB
  mkdir -p $WORKDIR
  kubectl get job $JOB -n $NAMESPACE -o yaml >> $WORKDIR/get.yaml
  kubectl describe job $JOB -n $NAMESPACE >> $WORKDIR/describe.txt
  kubectl logs -l job-name=$JOB -n $NAMESPACE --timestamps --all-containers >> $WORKDIR/logs.log
done

echo "Archiving Contents and cleaning up"
cd ..
tar -czf codefresh-support-$NOW.tar.gz codefresh-$NOW
rm -rf codefresh-$NOW

echo "New Tar Package: codefresh-support-$NOW.tar.gz"
echo "Please attach codefresh-support-$NOW.tar.gz to your support ticket"
