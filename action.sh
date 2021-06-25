#!/bin/bash

set -eo pipefail


export HELM_EXPERIMENTAL_OCI=1

valuesstring=""

for element in $(echo $INPUT_VALUES_FILE | tr "," "\n")
do
  valuesstring+="-f $element "
done

helm template "${valuesstring}"--set "${INPUT_ADDITIONAL_VALUES}" -n "${INPUT_NAMESPACE}" "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}"

#helm template "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}" -f "${INPUT_VALUES_FILE}" --set "${INPUT_ADDITIONAL_VALUES}" -n "${INPUT_NAMESPACE}"
echo "Deploying using values file for: ${INPUT_RELEASE_NAME}"
echo "Best steps to investigate if step fails:"
echo "- Run your branch in a container locally"
echo "- Run the deployment again, but check the kube-dashboard while it's deploying -- especially the replicaset for errors, and the pod logs for errors"

#helm upgrade --install "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}" -f "${INPUT_VALUES_FILE}" --atomic --timeout 3m -n "${INPUT_NAMESPACE}"
helm upgrade --install ${valuesstring} --set "${INPUT_ADDITIONAL_VALUES}" --atomic --timeout 3m -n "${INPUT_NAMESPACE}" "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}"

helm status "${INPUT_RELEASE_NAME}"
echo "✅ Helm upgrade complete"
