echo "Script ${0} starts"

#Function to display usage message
function usage() {
    usage=$(
        cat <<-END
Specify the following ENV variables:
VZ_CLI_DOWNLOAD
AKS_CLUSTER_RESOURCEGROUP_NAME
AKS_CLUSTER_NAME
END
    )
    echo_stdout ${usage}
    if [ $1 -eq 2 ]; then
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
    
}

# Connect to AKS cluster
function connect_aks_cluster() {
    echo_stdout "Connecting to AKS cluster ${AKS_CLUSTER_NAME}"
    state=$(az aks get-credentials --resource-group ${AKS_CLUSTER_RESOURCEGROUP_NAME} --name ${AKS_CLUSTER_NAME} --overwrite-existing$)
    if [ "$state" != "0" ]; then
        echo_stderr "Failed to connect AKS cluster  ${AKS_CLUSTER_NAME}"
    else
        echo_stdout "$@"
    fi
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
vz install -f - <<EOF
apiVersion: install.verrazzano.io/v1beta1
kind: Verrazzano
metadata:
  name: example-verrazzano
spec:
  profile: prod
  defaultVolumeSource:
    persistentVolumeClaim:
      claimName: globalOverride
  volumeClaimSpecTemplates:
    - metadata:
        name: globalOverride
      spec:
        resources:
          requests:
            storage: 50Gi
  components:
    ingressNGINX:
      overrides:
      - values:
          controller:
            service:
              annotations:
                service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
EOF
echo_stdout "Getting vz status"
vz status | grep Ready
if [ "$?" != "0" ]; then
  echo_stderr "vz status execution is unsuccessful"
else
  echo_stdout "vz installation is successful"
  vz status 
fi
