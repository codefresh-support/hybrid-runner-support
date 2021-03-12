# Creating a Support Package for Codefresh Runner

## PreReqs

1. Kubernetes context must be configured to cluster running Codefresh runner.
2. [Codefresh CLI](https://codefresh-io.github.io/cli/installation/) must be installed and configured.
3. git (can download a zip version instead)

## Script Usage

This script is to gather information about the Codefresh Runner (previously Venona) environment.  

> NOTE: This will gather information for all pods in the namespace you specified.

### Setup

To begin, you will need to clone the repo, change the directory to this repo, and add execution flag to the script.  Below is the command to do it all in one go.

```bash
git clone https://github.com/codefresh-contrib/venona-support.git && \
cd venona-support && \
chmod +x support_package.sh
```

### Syntax

```bash
./support_package.sh "Codefresh/Runtime" Codefresh-Namespace
```

The 1st argument is the runtime name. You can run `codefresh get runtime-environments` to get the runtimes.

> NOTE: make sure the runtime name is in `""` because of the `/` character.

The 2nd argument is the Kubernetes namespace where you installed the Codefresh Runner.

Example:

`./support_package.sh "sales-dev-eks/codefresh-runtime" codefresh-namespace`
