#! /bin/bash

# Set the exit code of a pipeline to that of the rightmost command
# to exit with a non-zero status, or zero if all commands of the pipeline exit
set -o pipefail
# cause a bash script to exit immediately when a command fails
set -e
# cause the bash shell to treat unset variables as an error and exit immediately
set -u
# echo each line of the script to stdout so we can see what is happening
set -o xtrace
#to turn off echo do 'set +o xtrace'

#get install git-secrets script from UI
GIT_SECRETS_SOURCE="https://raw.githubusercontent.com/dockstore/dockstore-ui2/develop/scripts/install-git-secrets.sh"
wget -O git-secrets.sh --no-verbose --tries=10 ${GIT_SECRETS_SOURCE}
chmod u+x git-secrets.sh
bash git-secrets.sh
