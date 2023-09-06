param _artifactsLocation string = deployment().properties.templateLink.uri
@secure()
param _artifactsLocationSasToken string = ''
param aksClusterRGName string = ''
param aksClusterName string = ''
param acrName string = ''
param location string
param identity object = {}
param vzCliDownload string = 'https://github.com/verrazzano/verrazzano/releases/download/v1.6.5/verrazzano-1.6.5-linux-amd64.tar.gz'
param azCliVersion string = ''
param utcValue string = utcNow()
var const_scriptLocation = uri(_artifactsLocation, 'scripts/')
var const_installVZCLI = 'installVZCLI.sh'
var const_installVZ = 'installVZ.sh'
var const_utility = 'utility.sh'

resource deploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
    name: 'ds-install-VZ'
    location: location
    kind: 'AzureCLI'
    identity: identity
    properties: {
        azCliVersion: azCliVersion
        environmentVariables: [
            {
                name: 'VZ_CLI_DOWNLOAD'
                value: vzCliDownload
            }
            {
                name: 'AKS_CLUSTER_RESOURCEGROUP_NAME'
                value: aksClusterRGName
            }
            {
                name: 'AKS_CLUSTER_NAME'
                value: aksClusterName 
            }
	]
    primaryScriptUri: uri(const_scriptLocation, '${const_installVZ}${_artifactsLocationSasToken}')
	supportingScriptUris: [
		uri(const_scriptLocation, '${const_installVZCLI}${_artifactsLocationSasToken}')
		uri(const_scriptLocation, '${const_utility}${_artifactsLocationSasToken}')
	]
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
    forceUpdateTag: utcValue
    }
}

