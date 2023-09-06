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
    az aks get-credentials --resource-group ${AKS_CLUSTER_RESOURCEGROUP_NAME} --name ${AKS_CLUSTER_NAME} --overwrite-existing
}
# Main script
export script="${BASH_SOURCE[0]}"
export scriptDir="$(cd "$(dirname "${script}")" && pwd)"
./installVZCLI.sh ${VZ_CLI_DOWNLOAD}

connect_aks_cluster
export KUBECONFIG=$HOME/.kube/config
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

vz status
sleep 30m
