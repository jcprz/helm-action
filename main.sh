#!/bin/bash

set -e
set -u
set -o pipefail


COMMAND=$1
TIMEOUT_IN_MINS=$2
REPOSITORY_NAME=$3
HELM_DIR=$4
VALUES_FILE=$5
ENV=$6
RELEASE_NAME=$7
NAMESPACE=$8
IMAGE_TAG=$9
DRY_RUN_OPTION=${10}
IS_DEBUG=${11}
CREATE_NAMESPACE_OPTION=${12}
SET_FLAG=${13}
SET_STRING_FLAG=${14}

CHART_DIRECTORY="${HELM_DIR}/${REPOSITORY_NAME}"

DRY_RUN_OPTION=$([ "${DRY_RUN_OPTION}" == "true" ] && echo "--dry-run" || echo "")
IS_DEBUG=$([ "${IS_DEBUG}" == "true" ] && echo "--debug" || echo "")
CREATE_NAMESPACE_OPTION=$([ "${CREATE_NAMESPACE_OPTION}" == "true" ] && echo "--create-namespace" || echo "")

# Prepare --set and --set-string flags
SET_FLAG_VALUES=""
if [ -n "${SET_FLAG}" ]; then
  IFS=',' read -ra SET_ENTRIES <<< "${SET_FLAG}"
  for ENTRY in "${SET_ENTRIES[@]}"; do
    SET_FLAG_VALUES+="--set ${ENTRY} "
  done
fi

SET_STRING_FLAG_VALUES=""
if [ -n "${SET_STRING_FLAG}" ]; then
  IFS=',' read -ra SET_STRING_ENTRIES <<< "${SET_STRING_FLAG}"
  for ENTRY in "${SET_STRING_ENTRIES[@]}"; do
    SET_STRING_FLAG_VALUES+="--set-string ${ENTRY} "
  done
fi

case "${COMMAND}" in
  "dependency_update")
    FINAL_COMMAND="helm dependency update \"${CHART_DIRECTORY}\" ${DRY_RUN_OPTION} ${IS_DEBUG}"
    ;;
  "lint")
    FINAL_COMMAND="helm lint --values \"${CHART_DIRECTORY}/${VALUES_FILE}\" ${CHART_DIRECTORY} \
      --set-string repositoryName=${REPOSITORY_NAME} \
      --set-string env.ENV=\"${ENV}\" \
      ${SET_STRING_FLAG_VALUES} \
      ${SET_FLAG_VALUES} \
      ${DRY_RUN_OPTION} ${IS_DEBUG}"
    ;;
  "install")
    FINAL_COMMAND="helm install --timeout \"${TIMEOUT_IN_MINS}m\" \
      --values \"${CHART_DIRECTORY}/${VALUES_FILE}\" \
      --set-string repositoryName=${REPOSITORY_NAME} \
      ${SET_STRING_FLAG_VALUES} \
      ${SET_FLAG_VALUES} \
      --set-string image.tag=\"${IMAGE_TAG}\" \
      --set-string env.ENV=\"${ENV}\" \
      \"${RELEASE_NAME}\" \
      --namespace=\"${NAMESPACE}\" \
      \"${CHART_DIRECTORY}\" \
      ${DRY_RUN_OPTION} ${IS_DEBUG} ${CREATE_NAMESPACE_OPTION}"
    ;;
  "upgrade")
    FINAL_COMMAND="helm upgrade --install --atomic --timeout \"${TIMEOUT_IN_MINS}m\" \
      --values \"${CHART_DIRECTORY}/${VALUES_FILE}\" \
      --set-string repositoryName=${REPOSITORY_NAME} \
      ${SET_STRING_FLAG_VALUES} \
      ${SET_FLAG_VALUES} \
      --set-string image.tag=\"${IMAGE_TAG}\" \
      --set-string env.ENV=\"${ENV}\" \
      \"${RELEASE_NAME}\" \
      --namespace=\"${NAMESPACE}\" \
      \"${CHART_DIRECTORY}\" \
      ${DRY_RUN_OPTION} ${IS_DEBUG} ${CREATE_NAMESPACE_OPTION}"
    ;;
  *)
    echo "Invalid command: ${COMMAND}"
    exit 1
    ;;
esac

echo "$(date) - Executing: ${FINAL_COMMAND}"
if ! eval "${FINAL_COMMAND}"; then
  echo "Error: Command failed: ${FINAL_COMMAND}"
  exit 1
fi
