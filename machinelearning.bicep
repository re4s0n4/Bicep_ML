// Creates a machine learning workspace, private endpoints and compute resources
// Compute resources include a GPU cluster, CPU cluster, compute instance and attached private AKS cluster
/* @description('Prefix for resource names')
param prefix string */

@description('Azure region of the deployment')
param location string

@description('Tags to add to the resources')
param tags object

@description('Machine learning workspace name')
param machineLearningName string

@description('Machine learning workspace display name')
param machineLearningFriendlyName string = machineLearningName

@description('Machine learning workspace description')
param machineLearningDescription string

/* @description('Name of the Azure Kubernetes services resource to create and attached to the machine learning workspace')
param mlAksName string */

@description('Resource ID of the application insights resource')
param applicationInsightsId string

@description('Resource ID of the container registry resource')
param containerRegistryId string

@description('Resource ID of the key vault resource')
param keyVaultId string

@description('Resource ID of the storage account resource')
param storageAccountId string

@description('Resource ID of the subnet resource')
param subnetId string

/* @description('Resource ID of the compute subnet')
param computeSubnetId string */

/* @description('Resource ID of the Azure Kubernetes services resource')
param aksSubnetId string */

@description('Resource ID of the virtual network')
param virtualNetworkId string

@description('Machine learning workspace private link endpoint name')
param machineLearningPleName string

/* @description('Enable public IP for Azure Machine Learning compute nodes')
param amlComputePublicIp bool = true */

param logAnalyticsWorkspaceId string

resource machineLearning 'Microsoft.MachineLearningServices/workspaces@2021-07-01' = {
  name: machineLearningName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // workspace organization
    friendlyName: machineLearningFriendlyName
    description: machineLearningDescription

    // dependent resources
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    keyVault: keyVaultId
    storageAccount: storageAccountId

    // configuration for workspaces with private link endpoint
    //imageBuildCompute: 'cluster001'
    publicNetworkAccess: 'Enabled'
    allowPublicAccessWhenBehindVnet: true
  }

}

module machineLearningPrivateEndpoint 'machinelearningnetworking.bicep' = {
  name: 'machineLearningNetworking'
  scope: resourceGroup()
  params: {
    location: location
    tags: tags
    virtualNetworkId: virtualNetworkId
    workspaceArmId: machineLearning.id
    subnetId: subnetId
    machineLearningPleName: machineLearningPleName
  }
}
/* var filePrivateDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'

resource workspacefilestore 'Microsoft.MachineLearningServices/workspaces/datastores@2021-03-01-preview' = {
  name: '${machineLearningName}/workspacefilestore'
  properties: {
    contents: {
      contentsType: 'AzureFile'
      accountName: storageAccountName
      containerName: 'code'
      endpoint: environment().suffixes.storage
      protocol: 'https'
      credentials: {
        credentialsType: 
        secrets:{
          secretsType: 'Sas'
          key: keyVaultObjec
        }
      }
    }
    isDefault: false
  }
} */

/* module machineLearningCompute 'machinelearningcompute.bicep' = {
  name: 'machineLearningComputes'
  scope: resourceGroup()
  params: {
    machineLearning: machineLearningName
    location: location
    computeSubnetId:computeSubnetId
    aksName: mlAksName
    aksSubnetId: aksSubnetId
    prefix: prefix
    tags: tags
    amlComputePublicIp: amlComputePublicIp
  }
  dependsOn: [
    machineLearning
    machineLearningPrivateEndpoint
  ]
} */

resource mlDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'ds-${machineLearningName}-ml'
  // this is where you enable diagnostic setting for the specificed security group
  scope: machineLearning
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        
        enabled: true
      }
      {
        categoryGroup: 'audit'
        
        enabled: true
      }
    ]

    metrics: [
      {
        enabled: true
      }
    ]
  }
}

output machineLearningId string = machineLearning.id

