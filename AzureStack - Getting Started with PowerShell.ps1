# Get Azure AD Tenant ID

Login-AzureRmAccount

$aadTenantId = 
    (Get-AzureRmContext).Tenant.TenantId

# Register environment for Azure Stack

Add-AzureRmEnvironment `
    -Name 'Azure Stack' `
    -ActiveDirectoryEndpoint ("https://login.windows.net/$aadTenantId/") `
    -ActiveDirectoryServiceEndpointResourceId "https://azurestack.local-api/" `
    -ResourceManagerEndpoint ("https://api.azurestack.local/") `
    -GalleryEndpoint ("https://gallery.azurestack.local:30016/") `
    -GraphEndpoint "https://graph.windows.net/"

# Get Azure Stack environment

$azureEnv = 
    Get-AzureRmEnvironment `
        -Name 'Azure Stack'

# Authenticate to Azure Stack environment

Login-AzureRmAccount `
    -Environment $azureEnv

# Select Azure subscription

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# View ARM Resource Providers

Get-AzureRmResourceProvider | 
    Select-Object `
    -Property ProviderNamespace `
    -ExpandProperty ResourceTypes

# Select Azure Resource Group 

$rgName =
    (Get-AzureRmResourceGroup |
     Out-GridView `
        -Title "Select an Azure Resource Group ..." `
        -PassThru).ResourceGroupName

# Select an Azure VM from Resource Group

$vmName =
    (Get-AzureRmVm `
        -ResourceGroupName $rgName).Name |
    Out-GridView `
        -Title "Select an Azure VM ..." `
        -PassThru

$vm = 
    Get-AzureRmVm `
        -ResourceGroupName $rgName `
        -Name $vmName

# Get Azure VM Status

$vm | Get-AzureRmVm -Status
