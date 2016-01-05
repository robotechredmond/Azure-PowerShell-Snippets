# Authenticate to Azure Account

Login-AzureRmAccount

# Select an Azure subscription 

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# Select existing Resource Group in which VM is contained

$rgName = 
    (Get-AzureRmResourceGroup).ResourceGroupName |
    Out-GridView `
        -Title "Select Resource Group in which VM exists ..." `
        -PassThru

# Select sysprepp'd VM to capture

$vmName = 
    (Get-AzureRmVM -ResourceGroup $rgName).Name |
    Out-GridView `
        -Title "Select VM to Capture Image ..."`
        -PassThru

# Capture Azure VM Image

$containerName = "vmimages"

$vhdPrefix = "kemvhd"

Set-AzureRmVM `
    -ResourceGroupName $rgName `
    -Name $vmName `
    -Generalized

$vmTemplate = 
    Save-AzureRmVMImage `
        -ResourceGroupName $rgName `
        -Name $vmName `
        -DestinationContainerName $containerName `
        -VHDNamePrefix $vhdPrefix `
        -Overwrite

# Write Captured Template for VM Deployment

$templateFile = ".\vmtemplate.json"

$vmTemplate.Output | 
    Out-File `
        -FilePath $templateFile

