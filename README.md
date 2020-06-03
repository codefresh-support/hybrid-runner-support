# Creating a Support Package for Venona

Script for gathering up details on Venona "Codefresh Runner" for support ticket

You may need to chmod +x to run.

The 1st argument is your runtime name from `codefresh get runtime-environments`.

* Please make sure you add double quotes around the runtime name due to `/` character.

The 2nd argument is the Kubernetes namespace where you installed venona.

Example:

`./support_package.sh "sales-dev-eks/codefresh-runtime" codefresh-runtime`
