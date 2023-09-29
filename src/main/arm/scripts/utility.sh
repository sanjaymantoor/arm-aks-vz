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
  #  grafanaUrl=`cat vzStatusOut | grep grafanaUrl| awk '{print ""$2""}'`
  #  grafanaUrl="\"grafanaUrl\":\"$grafanaUrl\","
  #  keyCloakUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
  #  keyCloakUrl="\"keyCloakUrl\":\"$keyCloakUrl\","
  #  kialiUrl=`cat vzStatusOut | grep kialiUrl| awk '{print ""$2""}'`
  #  kialiUrl="\"keyCloakUrl\":\"$keyCloakUrl\","
  #  openSearchDashboardsUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
  #  openSearchDashboardsUrl="\"openSearchDashboardsUrl\":\"$openSearchDashboardsUrl\","
  #  openSearchUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
  #  openSearchUrl="\"openSearchUrl\":\"$openSearchUrl\","
  #  prometheusUrl=`cat vzStatusOut | grep prometheusUrl| awk '{print ""$2""}'`
  #  prometheusUrl="\"prometheusUrl\":\"$prometheusUrl\","
  #  rancherUrl=`cat vzStatusOut | grep prometheusUrl| awk '{print ""$2""}'`
  #  rancherUrl="\"rancherUrl\":\"$rancherUrl\""
  #  data="$consoleUrl\n$grafanaUrl\n$kialiUrl\n$openSearchDashboardsUrl\n$openSearchUrl\n$prometheusUrl\n$rancherUrl"
   result=$(jq -n -c --arg consoleUrl "$consoleUrl" '{consoleUrl: $consoleUrl}')
   echo_stdout $result
   echo $result >$AZ_SCRIPTS_OUTPUT_PATH 
   rm -f vzStatusOut
}