# Sign-in to Azure via Azure Resource Manager

Login-AzureRmAccount

# Select Azure Subscription

$subscriptionId = 
    ( Get-AzureRmSubscription |
        Out-GridView `
          -Title "Select an Azure Subscription ..." `
          -PassThru
    ).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# If needed, register ARM core resource providers

Register-AzureRmResourceProvider `
    -ProviderNamespace Microsoft.Compute

Register-AzureRmResourceProvider `
    -ProviderNamespace Microsoft.Storage

Register-AzureRmResourceProvider `
    -ProviderNamespace Microsoft.Network

Get-AzureRmResourceProvider | 
    Select-Object `
    -Property ProviderNamespace `
    -ExpandProperty ResourceTypes

# Select Azure Resource Group in which existing VNET is provisioned

$rgName =
    ( Get-AzureRmResourceGroup |
        Out-GridView `
          -Title "Select an Azure Resource Group ..." `
          -PassThru
    ).ResourceGroupName

# Select Azure VNET gateway on which to start diagnostics logging

$vnetGwName = 
    ( Get-AzureRmVirtualNetworkGateway `
        -ResourceGroupName $rgName
    ).Name |
    Out-GridView `
        -Title "Select an Azure VNET Gateway ..." `
        -PassThru

# Select Azure Storage Account on which to send logs

$storageAccountName = 
    ( Get-AzureRmStorageAccount `
        -ResourceGroupName $rgName
    ).StorageAccountName |
    Out-GridView `
        -Title "Select an Azure Storage Account ..." `
        -PassThru

# Get Key for Azure Storage Account

$storageAccountKey = 
    ( Get-AzureRmStorageAccountKey `
          -Name $storageAccountName `
          -ResourceGroupName $rgName
    ).Key1

# Sign-in to Azure via Azure Service Management

Add-AzureAccount

# Select same Azure subscription via Azure Service Management

Select-AzureSubscription `
    -SubscriptionId $subscriptionId

# Set Storage Context for storing logs

$storageContext = 
    New-AzureStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

# Get Gateway ID for VNET Gateway

$vnetGws = Get-AzureVirtualNetworkGateway 

$vnetGwId = 
    ( $vnetGws | 
        ? GatewayName -eq $vnetGwName 
    ).GatewayId

# Start Azure VNET Gateway logging

$captureDuration = 60

$storageContainer = "vpnlogs"

Start-AzureVirtualNetworkGatewayDiagnostics  `
    -GatewayId $vnetGwId `
    -CaptureDurationInSeconds $captureDuration `
    -StorageContext $storageContext `
    -ContainerName $storageContainer

# Test VNET gateway connection to another server across the tunnel 
 
Test-NetConnection `
    -ComputerName 10.0.0.4 `
    -CommonTCPPort RDP

# Wait for diagnostics capturing to complete
 
Sleep -Seconds $captureDuration

# Download VNET gateway diagnostics log

$logUrl = 
    ( Get-AzureVirtualNetworkGatewayDiagnostics `
        -GatewayId $vnetGwId
    ).DiagnosticsUrl
 
$logContent = 
    ( Invoke-WebRequest `
        -Uri $logUrl
    ).RawContent
 
$logContent | 
    Out-File `
        -FilePath vpnlog.txt