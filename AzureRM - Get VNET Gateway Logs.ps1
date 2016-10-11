# STEP 1: Sign-in to Azure via Azure Resource Manager

Login-AzureRmAccount

# STEP 2: Select Azure Subscription

$subscriptionId = 
    ( Get-AzureRmSubscription |
        Out-GridView `
          -Title "Select an Azure Subscription ..." `
          -PassThru
    ).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# STEP 3: If needed, register ARM core resource providers

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

# STEP 4: Select Azure Resource Group in which existing VNET is provisioned

$rgName =
    ( Get-AzureRmResourceGroup |
        Out-GridView `
          -Title "Select an Azure Resource Group ..." `
          -PassThru
    ).ResourceGroupName

# STEP 5: Select Azure VNET gateway on which to start diagnostics logging

$vnetGwName = 
    ( Get-AzureRmVirtualNetworkGateway `
        -ResourceGroupName $rgName
    ).Name |
    Out-GridView `
        -Title "Select an Azure VNET Gateway ..." `
        -PassThru

# STEP 6: Select Azure Storage Account on which to send logs

$storageAccountName = 
    ( Get-AzureRmStorageAccount `
        -ResourceGroupName $rgName
    ).StorageAccountName |
    Out-GridView `
        -Title "Select an Azure Storage Account ..." `
        -PassThru

# STEP 7: Get Key for Azure Storage Account

$storageAccountKey = 
    ( Get-AzureRmStorageAccountKey `
          -Name $storageAccountName `
          -ResourceGroupName $rgName
    )[0].Value

# STEP 8: Sign-in to Azure via Azure Service Management

Add-AzureAccount

# STEP 9: Select same Azure subscription via Azure Service Management

Select-AzureSubscription `
    -SubscriptionId $subscriptionId

# STEP 10: Set Storage Context for storing logs

$storageContext = 
    New-AzureStorageContext `
        -StorageAccountName $storageAccountName `
        -StorageAccountKey $storageAccountKey

# STEP 11: Get Gateway ID for VNET Gateway

$vnetGws = Get-AzureVirtualNetworkGateway 

$vnetGwId = 
    ( $vnetGws | 
        ? GatewayName -eq $vnetGwName 
    ).GatewayId

# STEP 12: Start Azure VNET Gateway logging

$captureDuration = 60

$storageContainer = "vpnlogs"

Start-AzureVirtualNetworkGatewayDiagnostics  `
    -GatewayId $vnetGwId `
    -CaptureDurationInSeconds $captureDuration `
    -StorageContext $storageContext `
    -ContainerName $storageContainer

# STEP 13: Test VNET gateway connection to another server across the tunnel 
 
Test-NetConnection `
    -ComputerName 10.0.0.4 `
    -CommonTCPPort RDP

# STEP 14: Wait for diagnostics capturing to complete
 
Sleep -Seconds $captureDuration

# STEP 15: Download VNET gateway diagnostics log

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