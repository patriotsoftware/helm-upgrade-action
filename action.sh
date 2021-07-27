#!/bin/bash

set -eo pipefail


export HELM_EXPERIMENTAL_OCI=1


INPUT_VALUES_FILE="-f "${INPUT_VALUES_FILE}
INPUT_VALUES_FILE=$(echo ${INPUT_VALUES_FILE} | sed -r 's/[,]+/ -f /g')
echo ${INPUT_VALUES_FILE}

helm_template_cmd="helm template ${INPUT_RELEASE_NAME} ${INPUT_BASE_CHART} ${INPUT_ADDITIONAL_ARGS} ${INPUT_VALUES_FILE} --set ${INPUT_ADDITIONAL_VALUES} -n ${INPUT_NAMESPACE}"
echo $helm_template_cmd
eval $helm_template_cmd


echo "Deploying using values file for: ${INPUT_RELEASE_NAME}"
echo "Best steps to investigate if step fails:"
echo "- Run your branch in a container locally"
echo "- Run the deployment again, but check the kube-dashboard while it's deploying -- especially the replicaset for errors, and the pod logs for errors"

helm_upgrade_cmd="helm upgrade --install ${INPUT_ADDITIONAL_ARGS} ${INPUT_VALUES_FILE} --set ${INPUT_ADDITIONAL_VALUES} -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME} ${INPUT_BASE_CHART}"
eval $helm_upgrade_cmd

helm status "${INPUT_RELEASE_NAME}" -n "${INPUT_NAMESPACE}"
echo "✅ Helm upgrade complete"
