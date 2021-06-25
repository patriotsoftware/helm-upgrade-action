#!/bin/bash

set -eo pipefail


export HELM_EXPERIMENTAL_OCI=1


sed -i -e 's/^/-f /' ${INPUT_VALUES_FILE}
suffix=" -f ";  echo ${INPUT_VALUES_FILE} | sed -E "s/([^,]+)/\1${suffix}/g"
echo ${${INPUT_VALUES_FILE}//,/}

echo ${INPUT_VALUES_FILE}

helm template "${values-string}" --set "${INPUT_ADDITIONAL_VALUES}" -n "${INPUT_NAMESPACE}" "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}"

#helm template "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}" -f "${INPUT_VALUES_FILE}" --set "${INPUT_ADDITIONAL_VALUES}" -n "${INPUT_NAMESPACE}"
echo "Deploying using values file for: ${INPUT_RELEASE_NAME}"
echo "Best steps to investigate if step fails:"
echo "- Run your branch in a container locally"
echo "- Run the deployment again, but check the kube-dashboard while it's deploying -- especially the replicaset for errors, and the pod logs for errors"

#helm upgrade --install "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}" -f "${INPUT_VALUES_FILE}" --atomic --timeout 3m -n "${INPUT_NAMESPACE}"
helm upgrade --install ${values-string} --set "${INPUT_ADDITIONAL_VALUES}" --atomic --timeout 3m -n "${INPUT_NAMESPACE}" "${INPUT_RELEASE_NAME}" "${INPUT_BASE_CHART}"

helm status "${INPUT_RELEASE_NAME}"
echo "✅ Helm upgrade complete"
