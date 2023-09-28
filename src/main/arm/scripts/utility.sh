# Copyright (c) 2021, Oracle Corporation and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
# This script runs on Azure Container Instance with Alpine Linux that Azure Deployment script creates.

function echo_stderr() {
    echo >&2 "$@"
    # The function is used for scripts running within Azure Deployment Script
    # The value of AZ_SCRIPTS_OUTPUT_PATH is /mnt/azscripts/azscriptoutput
    echo -e "$@" >>${AZ_SCRIPTS_PATH_OUTPUT_DIRECTORY}/errors.log
}

function echo_stdout() {
    echo "$@"
    # The function is used for scripts running within Azure Deployment Script
    # The value of AZ_SCRIPTS_OUTPUT_PATH is /mnt/azscripts/azscriptoutput
    echo -e "$@" >>${AZ_SCRIPTS_PATH_OUTPUT_DIRECTORY}/debug.log
}

function vzStatus_jsonout() {
    vz status > vzStatusOut
    consoleUrl=`cat vzStatusOut | grep consoleUrl| awk '{print ""$2""}'`
    jq -n -c --arg consoleUrl "$consoleUrl" '{$consoleUrl}' > $AZ_SCRIPTS_OUTPUT_PATH
    grafanaUrl=`cat vzStatusOut | grep grafanaUrl| awk '{print ""$2""}'`
    jq -n -c --arg grafanaUrl "$grafanaUrl" '{$grafanaUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    keyCloakUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
    jq -n -c --arg keyCloakUrl "$keyCloakUrl" '{$keyCloakUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    kialiUrl=`cat vzStatusOut | grep kialiUrl| awk '{print ""$2""}'`
    jq -n -c --arg kialiUrl "$kialiUrl" '{$kialiUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    openSearchDashboardsUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
    jq -n -c --arg kialiUrl "$kialiUrl" '{$kialiUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    openSearchUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
    jq -n -c --arg openSearchUrl "$openSearchUrl" '{$openSearchUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    prometheusUrl=`cat vzStatusOut | grep prometheusUrl| awk '{print ""$2""}'`
    jq -n -c --arg prometheusUrl "$prometheusUrl" '{$prometheusUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    rancherUrl=`cat vzStatusOut | grep prometheusUrl| awk '{print ""$2""}'`
    jq -n -c --arg prometheusUrl "$prometheusUrl" '{$prometheusUrl}' >> $AZ_SCRIPTS_OUTPUT_PATH
    rm -f vzStatusOut
}