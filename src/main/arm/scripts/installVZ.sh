	echo "Script ${0} starts"

	#Function to display usage message
	function usage() {
		usage=$(
			cat <<-END
	Specify the following ENV variables:
	VZ_CLI_DOWNLOAD
	AKS_CLUSTER_RESOURCEGROUP_NAME
	AKS_CLUSTER_NAME
	CRD_FILE_DATA
	END
		)
		echo_stdout ${usage}
		if [ $1 -lt 4 ]; then
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
		if [ -z "$CRD_FILE_DATA" ]; then
			echo_stderr "Upload the vz crd data file"
			usage 1
		fi
	   
	}

	# Connect to AKS cluster
	function connect_aks_cluster() {
		echo_stdout "Connecting to AKS cluster ${AKS_CLUSTER_NAME} for the resource group ${AKS_CLUSTER_RESOURCEGROUP_NAME}"
		state=$(az aks get-credentials --resource-group ${AKS_CLUSTER_RESOURCEGROUP_NAME} --name ${AKS_CLUSTER_NAME} --overwrite-existing)
		echo_stdout ${state}
	}
	# Main script
	export script="${BASH_SOURCE[0]}"
	export scriptDir="$(cd "$(dirname "${script}")" && pwd)"
	source ${scriptDir}/utility.sh
	./installVZCLI.sh ${VZ_CLI_DOWNLOAD}

	connect_aks_cluster
	export KUBECONFIG=$HOME/.kube/config
	echo_stdout "KUBECONFIG is set to $KUBECONFIG"
	echo_stdout "Installing vz using vz cli"
	echo "CRD File downloading from ${CRD_FILE_DATA}"
	#CRD_FILE_DATA=https://raw.githubusercontent.com/sanjaymantoor/arm-aks-vz/master/samples/crd-pvc.yaml
	wget $CRD_FILE_DATA
	fileName=`echo $CRD_FILE_DATA | awk -F/ '{print $NF}'`
	vz install -f $fileName
	
	sleep 2m
	echo_stdout "Getting vz status"
	vz status
	vz status | grep 'State: Ready'
	if [[ $? != 0 ]]; then
		echo_stderr "VZ installation is not successful"
	else
		echo_stdout "VZ installation is successful"
	fi 

	curl -LOqf "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" | true
	./kubectl version
	echo_stdout "VZ login details"
	echo_stdout "Username: verrazzano"
	echo_stdout "Password:"
	./kubectl get secret --namespace verrazzano-system verrazzano -o jsonpath={.data.password} | base64 -d; echo
 
