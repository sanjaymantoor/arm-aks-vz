	echo "Script ${0} starts"

	#Function to display usage message
	function usage() {
		usage=$(
			cat <<-END
	Specify the following ENV variables:
	VZ_CLI_DOWNLOAD
	VZ_CONSOLE_PSW
	KEYCLOAK_ADMIN_PSW
	AKS_CLUSTER_RESOURCEGROUP_NAME
	AKS_CLUSTER_NAME
	VZ_CRD_FILE_URL
	END
		)
		echo_stdout ${usage}
		if [ $1 -lt 6 ]; then
			echo_stderr ${usage}
			exit 1
		fi
	}

	#Function to validate input
	function validate_input() {
		if [ -z "$VZ_CLI_DOWNLOAD" ]; then
			echo_stderr "USER_PROVIDED_IMAGE_PATH is required. "
			usage 1
		fi
		if [ -z "$AKS_CLUSTER_RESOURCEGROUP_NAME" ]; then
			echo_stderr "AKS_CLUSTER_RESOURCEGROUP_NAME is required. "
			usage 1
		fi
		if [ -z "$AKS_CLUSTER_NAME" ]; then
			echo_stderr "AKS_CLUSTER_NAME is required. "
			usage 1
		fi
		if [ -z "$VZ_CRD_FILE_URL" ]; then
			echo_stderr "Upload the vz crd data file"
			usage 1
		fi
		if [ -z "$VZ_CONSOLE_PSW" ]; then
			echo_stderr "Provide verrazzano console password"
			usage 1
		fi
		if [ -z "$KEYCLOAK_ADMIN_PSW" ]; then
			echo_stderr "Provide keycloak admin password"
			usage 1
		fi
		
	}

	# Main script
	export script="${BASH_SOURCE[0]}"
	export scriptDir="$(cd "$(dirname "${script}")" && pwd)"
	# Temporarily users are hardcoded
	VZ_CONSOLE_USER="verrazzano"
	KEYCLOAK_ADMIN_USER="keycloakadmin"
	source ${scriptDir}/utility.sh
	installUtilities
	./installVZCLI.sh ${VZ_CLI_DOWNLOAD}
	connect_aks_cluster
	export KUBECONFIG=$HOME/.kube/config
	echo_stdout "KUBECONFIG is set to $KUBECONFIG"
	echo_stdout "Installing vz using vz cli"
	getVerrazzanoCRDFile $VZ_CRD_FILE_URL
	fileName=`echo $VZ_CRD_FILE_URL | awk -F/ '{print $NF}'`
	vz install -f $fileName >> ${AZ_SCRIPTS_PATH_OUTPUT_DIRECTORY}/debug.log 2>&1
	waitForReady
	vz status | grep 'Available Components: 26/26'
	checkStatus $? "VZ installation is not successful"
	echo_stdout "VZ installation is successful"
	vzStatus_jsonout
	updateVZConsolePswd $VZ_CONSOLE_USER $VZ_CONSOLE_PSW $KEYCLOAK_ADMIN_USER
	updateKeycloakAdminPswd $KEYCLOAK_ADMIN_USER $KEYCLOAK_ADMIN_PSW