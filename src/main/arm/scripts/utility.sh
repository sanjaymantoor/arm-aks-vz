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

function checkStatus() {
	statusCode=$1
	statusMessage=$2
	if [[ $statusCode != 0 ]]; then
		echo_stderr $2
		exit $statusCode
	fi
}

# Write vz status output as JSON format so that deployment script can read it
function vzStatus_jsonout() {
    vz status > vzStatusOut
    checkStatus $? "Unable to get Verrazzano status"
    consoleUrl=`cat vzStatusOut | grep consoleUrl| awk '{print ""$2""}'`
    grafanaUrl=`cat vzStatusOut | grep grafanaUrl| awk '{print ""$2""}'`
	keyCloakUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
  	kialiUrl=`cat vzStatusOut | grep kialiUrl| awk '{print ""$2""}'`
    openSearchDashboardsUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
    openSearchUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
	prometheusUrl=`cat vzStatusOut | grep prometheusUrl| awk '{print ""$2""}'`
	rancherUrl=`cat vzStatusOut | grep prometheusUrl| awk '{print ""$2""}'`
    accessEndPoints="{consoleUrl=$consoleUrl},   {grafanaUrl=$grafanaUrl},   {keyCloakUrl=$keyCloakUrl},   {kialiUrl=$kialiUrl},   {openSearchDashboardsUrl=$openSearchDashboardsUrl},   {openSearchUrl=$openSearchUrl},   {prometheusUrl=$prometheusUrl},   {rancherUrl=$rancherUrl}"
    result=$(jq -n -c --arg accessEndPoints "$accessEndPoints" '{accessEndPoints: $accessEndPoints}')
    checkStatus $? "Unable to JSON format Verrazzano accessEndpoints output"
    echo_stdout $result
    echo $result >$AZ_SCRIPTS_OUTPUT_PATH 
    rm -f vzStatusOut
}

# Connect to AKS cluster
function connect_aks_cluster() {
   echo_stdout "Connecting to AKS cluster ${AKS_CLUSTER_NAME} for the resource group ${AKS_CLUSTER_RESOURCEGROUP_NAME}"
   state=$(az aks get-credentials --resource-group ${AKS_CLUSTER_RESOURCEGROUP_NAME} --name ${AKS_CLUSTER_NAME} --overwrite-existing)
   echo_stdout ${state}
}

# Download Verrazzano CRD file
function getVerrazzanoCRDFile() {
	crdFileURL=$1
	echo_stdout "CRD File downloading from ${crdFileURL}"
	wget --no-check-certificate -q $crdFileURL
	checkStatus $? "Failed to download ${crdFileURL}"
	fileName=`echo $VZ_CRD_FILE_URL | awk -F/ '{print $NF}'`
	ls $fileName
	checkStatus $? "$fileName is not available locally"
}

# Wait for verrazzano installation
function waitForReady() {
	vz status >> ${AZ_SCRIPTS_PATH_OUTPUT_DIRECTORY}/debug.log
	attempt=1
	vz status | grep 'Available Components: 26/26'
	while [[ $? != 0 ]]
	do
		echo "Waiting for verrazzanon installation to complete"
		sleep 30s
		if [[ $attempt -gt 10 ]]; then
			break
		fi 
		attempt=`expr($attempt+1)`
		vz status | grep 'Available Components: 26/26'
	done
}

# Download and install dependencies
function installUtilities() {
	curl -LOqf "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" | true
	cp kubectl /bin/.
	kubectl version | tee -a ${AZ_SCRIPTS_PATH_OUTPUT_DIRECTORY}/debug.log
	checkStatus $? "kubectl is not installed or not available"
}

# Update Verrazzano console password
function updateVZConsolePswd() {
	vz status > vzStatusOut
	consoleUrl=`cat vzStatusOut | grep consoleUrl| awk '{print ""$2""}'`
	keyCloakUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
	vzConsoleUser=$1
	vzConsolePassword=$2
	keyCloakUser=$3
	echo_stdout "Starting password reset for Verrazzano console user ${vzConsoleUser}"
	HEADERS="-H 'Accept: application/json' -H 'Content-Type: application/x-www-form-urlencoded' -H 'cache-control: no-cache'"
	echo_stdout "Getting keycloak password"
	keyCloakPswd=$(kubectl get secret --namespace keycloak keycloak-http -o jsonpath={.data.password} | base64 -d; echo)
	echo_stdout "keyCloakPswd=$keyCloakPswd"
	checkStatus $? "Unable to get keycloak password"
	echo_stdout "Getting keycloak access token"
	echo_stdout curl -k -X POST $keyCloakUrl/auth/realms/master/protocol/openid-connect/token $HEADERS -d "grant_type=password&username=${keyCloakUser}&password=${keyCloakPswd}&client_id=admin-cli"  
	curl -k -X POST $keyCloakUrl/auth/realms/master/protocol/openid-connect/token $HEADERS -d "grant_type=password&username=${keyCloakUser}&password=${keyCloakPswd}&client_id=admin-cli" | grep access_token > token.json
	checkStatus $? "Unable to get keycloak access token"
	token=`jq '.access_token' token.json `
	token=`echo $token | sed 's|\"||g'`
	auth="Authorization: Bearer $token"
	echo_stdout "auth=$auth"
	echo_stdout "Getting verrazzano-system users list"
#	echo_stdout curl -skX GET $keyCloakUrl/auth/admin/realms/verrazzano-system/users  -H "${auth}" > id.json 
	curl -skX GET $keyCloakUrl/auth/admin/realms/verrazzano-system/users  -H "${auth}" > id.json
	checkStatus $? "Unable to get keycloak users list"
	echo_stdout "Getting id for user ${vzConsoleUser}"
	vzConsoleUserID=`cat id.json | jq -r '.[0].id'`
	echo_stdout "vzConsoleUserID=$vzConsoleUserID"
	echo_stdout "Resetting password for user ${vzConsoleUser}"
	# Get again access token in case it is expired
	curl -k -X POST $keyCloakUrl/auth/realms/master/protocol/openid-connect/token $HEADERS -d "grant_type=password&username=${keyCloakUser}&password=${keyCloakPswd}&client_id=admin-cli" | grep access_token > token.json
	token=`jq '.access_token' token.json `
	token=`echo $token | sed 's|\"||g'`
	auth="Authorization: Bearer $token"
#	echo_stdout "auth=$auth"
#	echo_stdout curl -k -X PUT "$keyCloakUrl/auth/admin/realms/verrazzano-system/users/${vzConsoleUserID}/reset-password" -H "Content-Type: application/json" -H "${auth}" --data "{ \"type\": \"password\", \"temporary\": false, \"value\": \"${vzConsolePassword}\"}" 
	curl -k -X PUT "$keyCloakUrl/auth/admin/realms/verrazzano-system/users/${vzConsoleUserID}/reset-password" -H "Content-Type: application/json" -H "${auth}" --data "{ \"type\": \"password\", \"temporary\": false, \"value\": \"${vzConsolePassword}\"}"
	checkStatus $? "Unable to reset password"	 
	echo_stdout "Updating the verrazzano secret"
	base64vzConsolePassword=`echo -n ${vzConsolePassword} | base64`
#	echo_stdout "base64vzConsolePassword=$base64vzConsolePassword"
#	echo_stdout kubectl patch secret verrazzano -n verrazzano-system -p "{\"data\": {\"password\": \"${base64vzConsolePassword}\"}}"
	kubectl patch secret verrazzano -n verrazzano-system -p "{\"data\": {\"password\": \"${base64vzConsolePassword}\"}}"
	checkStatus $? "Unable to update verrazzano secret"
	echo_stdout "Completed password reset for Verrazzano console user ${vzConsoleUser}"
}


# Update Keycloak admin password
function updateKeycloakAdminPswd() {
	vz status > vzStatusOut
	keyCloakUrl=`cat vzStatusOut | grep keyCloakUrl| awk '{print ""$2""}'`
	keyCloakUser=$1
	keyCloakNewPassword=$2
	HEADERS="-H 'Accept: application/json' -H 'Content-Type: application/x-www-form-urlencoded' -H 'cache-control: no-cache'"
	keyCloakPswd=$(kubectl get secret --namespace keycloak keycloak-http -o jsonpath={.data.password} | base64 -d; echo)
	checkStatus $? "Unable to get keycloak password"
	echo_stdout "Starting password reset for ${keyCloakUser} user"
	echo_stdout "Getting keycloak access token"
	curl -k -X POST $keyCloakUrl/auth/realms/master/protocol/openid-connect/token $HEADERS -d "grant_type=password&username=${keyCloakUser}&password=${keyCloakPswd}&client_id=admin-cli" | grep access_token > token.json
	checkStatus $? "Unable to get keycloak access token"
	token=`jq '.access_token' token.json `
	token=`echo $token | sed 's|\"||g'`
	auth="Authorization: Bearer $token"
	echo_stdout "auth=$auth"
	echo_stdout "Getting keycloak admin users list"
	curl -skX GET $keyCloakUrl/auth/admin/realms/master/users  -H "${auth}" > id.json
	checkStatus $? "Unable to get keycloak users list"
	echo_stdout "Getting id for user ${keyCloakUser}"
	keyCloakAdminUserID=`cat id.json | jq -r '.[0].id'`
	echo_stdout "Resetting password for user ${keyCloakUser}"
	# Get again access token in case it is expired
	curl -k -X POST $keyCloakUrl/auth/realms/master/protocol/openid-connect/token $HEADERS -d "grant_type=password&username=${keyCloakUser}&password=${keyCloakPswd}&client_id=admin-cli" | grep access_token > token.json
	token=`jq '.access_token' token.json `
	token=`echo $token | sed 's|\"||g'`
	auth="Authorization: Bearer $token"
	curl -k -X PUT "$keyCloakUrl/auth/admin/realms/master/users/${keyCloakAdminUserID}/reset-password" -H "Content-Type: application/json" -H "${auth}" --data "{ \"type\": \"password\", \"temporary\": false, \"value\": \"${keyCloakNewPassword}\"}"
	checkStatus $? "Unable to reset password"	 
	echo_stdout "Updating the keycloak secret"
	base64keyCloakPassword=`echo -n ${keyCloakNewPassword} | base64`
	kubectl patch secret keycloak-http -n keycloak -p "{\"data\": {\"password\": \"${base64keyCloakPassword}\"}}"
	checkStatus $? "Unable to update keycloak secret"
	echo_stdout "Completed password reset for ${keyCloakUser} user"
}