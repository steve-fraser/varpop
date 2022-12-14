#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

logit() {
	echo "${CLUSTER_NAME}: $@"
}

# Populate platform manifests with environment variables
varpop() {
	cd /tmp
	git clone https://$GITHUB_TOKEN@github.com/weavegitops/$CLUSTER_NAME.git
	logit "WGE repo cloned"
	cd $CLUSTER_NAME
	cp -R bin/platform/* platform
	logit "Platform directory copied"
	for file in $(ls platform/)
	do
		envsubst < platform/$file > /tmp/$file && mv /tmp/$file platform/$file
		logit "Variables replaced in $file"
	done
	logit "Variables replaced in all files in platform directory"
	git config user.name github-actions
	git config user.email github-actions@github.com
	git add platform/.
	git commit -m 'Cluster variables populated'
	git push
	logit "Updated files pushed to git"
}

# Test to see if terraform is complete
# Meaning repo has been provisioned
fail=0
until [ $fail -gt 9 ]
do
	if [ "$(kubectl get terraform --namespace $NAMESPACE $CLUSTER_NAME-wge-repo -o jsonpath='{.status.conditions[0].status}')" == "True" ]
	then
		logit "WGE repo provisioned, populating repo"
		varpop
		exit 0
	else
		logit "WGE repo not yet provisioned, waiting 2 minutes"
		#sleep 120
		((fail++))
		echo $fail
	fi
done

if [ $fail -gt 9 ]
then
	logit "WGE repo provisioning seems to have failed"
	exit 1
fi
