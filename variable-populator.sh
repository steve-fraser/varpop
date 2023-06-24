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
	git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_ORG}/${CLUSTER_NAME}.git
	logit "WGE repo cloned, check deployment status"
	cd ${CLUSTER_NAME}
	if [ -f .done ]
	then
		logit "variables previously populated, exiting"
		exit 0
	fi
	find "./" -type f -not -path "./.git/*" | while read -r file
	do
		# Perform operations on each file
		echo "Processing file: $file"
		envsubst < ${file} > ${file}.tmp && mv ${file}.tmp ${file}
		# Add your own commands here to process the file
		# For example, you can perform actions like copying, renaming, or manipulati ng the file

	done
	logit "Variables replaced in all files in platform directory"
	touch .done
	git config user.name github-actions
	git config user.email github-actions@github.com
	git add .
	git commit -m 'Cluster variables populated'
	git push
	logit "Updated files pushed to git"
}

# Test to see if terraform is complete
# Meaning repo has been provisioned
fail=0
until [ $fail -gt 9 ]
do
	if [ "$(kubectl get terraform --namespace ${NAMESPACE} ${CLUSTER_NAME}-wge-repo -o jsonpath='{.status.conditions[0].status}')" == "True" ]
	then
		logit "WGE repo provisioned, populating repo"
		varpop
		exit 0
	else
		logit "WGE repo not yet provisioned, waiting 2 minutes"
		sleep 120
		(( ++fail ))
		echo ${fail}
	fi
done

if [ $fail -gt 9 ]
then
	logit "WGE repo provisioning seems to have failed"
	exit 1
fi
