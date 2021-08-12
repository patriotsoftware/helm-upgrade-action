#!/bin/bash

set -eo pipefail

show_problems() {
    sleep ${INPUT_PROBLEMS_TIMEOUT}
    helm status -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME}
    echo -e "\n \n"
    
    echo -e "\nDeployment Description: \n"
    deploy_description="$(kubectl describe deploy -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME})"
    echo $deploy_description
    
    echo -e "\nReplicaSet Description: \n"
    replicaset_name=$(kubectl describe deployment -n ${INPUT_NAMESPACE} ${INPUT_RELEASE_NAME} | grep "^NewReplicaSet"| awk '{print $2}')
    replicaset_description="$(kubectl describe rs -n ${INPUT_NAMESPACE} $replicaset_name)"
    echo $replicaset_description
    
    echo -e "\nPod Description: \n"
    pod_hash_label=$(kubectl get rs -n ${INPUT_NAMESPACE} $replicaset_name -o jsonpath="{.metadata.labels.pod-template-hash}")
    pod_names=$(kubectl get pods -n ${INPUT_NAMESPACE} -l pod-template-hash=$pod_hash_label --show-labels | tail -n +2 | awk '{print $1}')
    pod_descriptions="$(echo $pod_names | xargs kubectl describe pod -n ${INPUT_NAMESPACE})"
    echo pod_descriptions

    echo -e "\nPod Logs: \n"
    pod_logs="$(echo $pod_names | xargs kubectl logs -n ${INPUT_NAMESPACE})"
    echo pod_logs

    # TODO: Add Green check, red X, save outputs to variables to do quick check after printing. Check for: Startup error, Image error, No node available
    echo "There are a variety of reasons a deployment could fail. Search the GitHub Action logs for the following headers to jump to a specific part:"
    echo " Deployment Description"
    echo " ReplicaSet Description"
    echo " Pod Description"
    echo " Pod Logs"
    echo -e "\n\nSearching common causes. Findings will be shown below. If none are shown, take a look through each of the previous sections."

    full_logs=$(echo -e "$deploy_description $replicaset_description $pod_descriptions $pod_logs")
    
    if [[ "$full_logs" == *"CrashLoopBackOff"* ]]; then
        echo "CrashLoopBackoff found. This occurs when either a pod crashes during startup, or a health check probe continually fails. Check pod logs above."
    fi

    if [[ "$full_logs" == *"probe errored"* ]] || [[ "$full_logs" == *"probe failed"* ]]; then
        echo "One or more probes (startup, liveness, readiness) has failed. Check the pod description above."
    fi

    if [[ "$full_logs" == *"ImagePullBackOff"* ]]; then
        echo "ImagePullBackOff found. This occurs when the container image cannot be pulled. Check that the image exists and that the node has access to that image."
    fi
    
    if [[ "$full_logs" == *"FailedScheduling"* ]]; then
        echo "FailedScheduling found. Check the 'Events' section of the pod description above."
    fi

    if [[ "$full_logs" == *"FailedCreate"* ]]; then
        echo "FailedCreate found. Check the 'Events' section of the pod description above."
    fi
    
    
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
