#!/bin/bash

set -eo pipefail

show_problems() {
    sleep ${INPUT_PROBLEMS_TIMEOUT}
    helm status -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME}
    echo -e "\n \n"
    
    echo -e "\nDeployment Description: \n"
    deploy_description="$(kubectl describe deploy -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME})"
    echo "$deploy_description"
    
    echo -e "\nReplicaSet Description: \n"
    replicaset_name=$(kubectl describe deployment -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME} | grep "^NewReplicaSet"| awk '{print $2}')
    replicaset_description="$(kubectl describe rs -n ${INPUT_NAMESPACE} $replicaset_name)"
    echo "$replicaset_description"
    
    echo -e "\nPod Description: \n"
    pod_hash_label=$(kubectl get rs -n ${INPUT_NAMESPACE} $replicaset_name -o jsonpath="{.metadata.labels.pod-template-hash}")
    pod_names=$(kubectl get pods -n ${INPUT_NAMESPACE} -l pod-template-hash=$pod_hash_label --show-labels | tail -n +2 | awk '{print $1}')
    pod_descriptions="$(echo $pod_names | xargs kubectl describe pod -n ${INPUT_NAMESPACE})"
    echo "$pod_descriptions"

    echo -e "\nPod Logs: \n"
    pod_logs="$(echo $pod_names | xargs kubectl logs -n ${INPUT_NAMESPACE} || echo "Could not access pod logs. Container may not have started.")"
    echo "$pod_logs"


    echo -e "\n\nℹ️ Problems timeout seconds exceeded. Beginning analysis. \n\n"
    echo -e "ℹ️ There are a variety of reasons a deployment could fail. Search the GitHub Action logs for the following headers to jump to a specific section:"
    echo "    Deployment Description"
    echo "    ReplicaSet Description"
    echo "    Pod Description"
    echo "    Pod Logs"

    echo -e "\n\n⏳ Searching common causes for failures. Findings will be shown below. If none are shown, take a look through each of the previous sections."

    full_logs=$(echo -e "$deploy_description $replicaset_description $pod_descriptions $pod_logs")
    
    if [[ "$full_logs" == *"CrashLoopBackOff"* ]]; then
        echo -e "❌ CrashLoopBackoff found.\n This occurs when either a pod crashes during startup, or a health check probe continually fails. Check pod logs above.\n"
    fi

    if [[ "$full_logs" == *"probe errored"* ]] || [[ "$full_logs" == *"probe failed"* ]]; then
        echo -e "❌ One or more probes (startup, liveness, readiness) has failed. Check the pod description above.\n"
    fi

    if [[ "$full_logs" == *"ImagePullBackOff"* ]]; then
        echo -e "❌ ImagePullBackOff found.\n This occurs when the container image cannot be pulled. Check that the image exists and that the node has access to that image.\n"
    fi
    
    if [[ "$full_logs" == *"FailedScheduling"* ]]; then
        echo -e "❌ FailedScheduling found.\n Check the 'Events' section of the pod description above.\n"
    fi

    if [[ "$full_logs" == *"FailedCreate"* ]]; then
        echo -e "❌ FailedCreate found.\n Check the 'Events' section of the pod description above.\n"
    fi

    shopt -s nocasematch
    if [[ "$pod_logs" =~ "error" ]]; then
        echo -e "❌ Error found in pod logs. Check the pod logs above.\n"
    fi
    
}
export HELM_EXPERIMENTAL_OCI=1


INPUT_VALUES_FILE="-f "${INPUT_VALUES_FILE}
INPUT_VALUES_FILE=$(echo ${INPUT_VALUES_FILE} | sed -r 's/[,]+/ -f /g')
echo ${INPUT_VALUES_FILE}

if [[ ${INPUTS_PRINT_TEMPLATE} == "true" ]]; then
    helm_template_cmd="helm template ${INPUT_RELEASE_NAME} ${INPUT_BASE_CHART} ${INPUT_ADDITIONAL_ARGS} ${INPUT_VALUES_FILE} --set ${INPUT_ADDITIONAL_VALUES} -n ${INPUT_NAMESPACE}"
    echo $helm_template_cmd
    eval $helm_template_cmd
fi

helm_upgrade_cmd="helm upgrade --install ${INPUT_RELEASE_NAME} ${INPUT_BASE_CHART} ${INPUT_ADDITIONAL_ARGS} ${INPUT_VALUES_FILE} --set ${INPUT_ADDITIONAL_VALUES} -n ${INPUT_NAMESPACE}"
echo $helm_upgrade_cmd
if [[ -n ${INPUT_PROBLEMS_TIMEOUT} ]]; then 
    show_problems &
    eval $helm_upgrade_cmd

    # Prevent show_problems from continuing to execute
    kill %1
else
    eval $helm_upgrade_cmd
fi

helm status "${INPUT_RELEASE_NAME}" -n "${INPUT_NAMESPACE}"
echo "✅ Helm upgrade complete"
