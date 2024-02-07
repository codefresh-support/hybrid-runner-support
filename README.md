# Creating a Support Package for Codefresh Hybrid Runtime

# Please use https://github.com/codefresh-support/codefresh-support-package as this repo is no longer active.

## PreReqs

1. `kubectl config current-context` must be the context of the cluster the runner is located in
2. [Codefresh CLI](https://codefresh-io.github.io/cli/installation/) must be installed and configured for classic runtime
3. jq (used to gather information)
4. git (can download a zip version instead)

## Script Usage

This script is to gather information about the Codefresh Hybrid Runtime for classic and gitops 

### Setup

To begin, you will need to clone the repo, change the directory to this repo, and add execution flag to the script.  Below is the command to do it all in one go.

```bash
git clone https://github.com/codefresh-support/hybrid-runner-support.git && \
cd hybrid-runner-support && \
chmod +x support_package.sh
```

### Syntax

```bash
./support_package.sh 
```

Then follow the prompts.

### Example

```bash
./support_package.sh
```
