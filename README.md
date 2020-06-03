# Creating a Support Package for Venona

## PreReqs

1. Kubernetes context must be configured to cluster running Venona.
1. [Codefresh CLI](https://codefresh-io.github.io/cli/installation/) must be installed and configured.

## Script Usage

Script for gathering up details on Venona "Codefresh Runner" for support ticket

You may need to chmod +x to run.

The 1st argument is your runtime name from `codefresh get runtime-environments`.

* Please make sure you add double quotes around the runtime name due to `/` character.

The 2nd argument is the Kubernetes namespace where you installed venona.

Example:

`./support_package.sh "sales-dev-eks/codefresh-runtime" codefresh-runtime`
