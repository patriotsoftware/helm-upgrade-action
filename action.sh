#!/bin/bash

set -eo pipefail

show_problems() {
    sleep ${INPUT_PROBLEMS_TIMEOUT}
    helm status -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME}
    echo -e "\n \n"

    export revision=$(kubectl get deploy -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME} -o jsonpath="{.metadata.annotations.deployment\.kubernetes\.io\/revision}")
    RS_NAME=`kubectl describe deployment -n ${INPUT_NAMESPACE} $DEPLOY_NAME|grep "^NewReplicaSet"|awk '{print $2}'`; echo $RS_NAME
    kubectl describe rs -n ${INPUT_NAMESPACE} $RS_NAME
    POD_HASH_LABEL=`kubectl get rs $RS_NAME -o jsonpath="{.metadata.labels.pod-template-hash}"` ; echo $POD_HASH_LABEL
    POD_NAMES=`kubectl get pods -l pod-template-hash=$POD_HASH_LABEL --show-labels | tail -n +2 | awk '{print $1}'`; echo $POD_NAMES
    kubectl describe deploy -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME}
    echo $POD_NAMES | xargs kubectl describe pod -n ${INPUT_NAMESPACE}
    kubectl logs -n ${INPUT_NAMESPACE} deploy/${INPUT_RELEASE_NAME}
}
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

helm_upgrade_cmd="helm upgrade --install ${INPUT_RELEASE_NAME} ${INPUT_BASE_CHART} ${INPUT_ADDITIONAL_ARGS} ${INPUT_VALUES_FILE} --set ${INPUT_ADDITIONAL_VALUES} -n ${INPUT_NAMESPACE}"
echo $helm_upgrade_cmd
show_problems &
eval $helm_upgrade_cmd
kill %1 # kill the show problems so it doesn't hang
helm status "${INPUT_RELEASE_NAME}" -n "${INPUT_NAMESPACE}"
echo "✅ Helm upgrade complete"
