# Sign-in with Azure account credentials

Login-AzureRmAccount

# Select Azure Subscription

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

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


# Stop and Deallocate VM if running

$vmStatus =
    (Get-AzureRmVm `
        -ResourceGroupName $rgName `
        -Name $vmName `
        -Status).Statuses

if ($vmStatus[-1].Code -ne "PowerState/deallocated") {
    $vm | Stop-AzureRmVm -Force
}

# Identify VM disks

$vmDisks = @()

$vmDisks += 
    $vm.StorageProfile.OSDisk.VirtualHardDisk.Uri

Foreach ($vmDisk in $vm.StorageProfile.DataDisks) {

    $vmDisks += 
        $vmDisk.VirtualHardDisk.Uri

}

# Define Context for Storage Account

$storageAccountName = 
    $vmDisks[0].Substring(8).Split('.')[0]

$storageContext = 
    (Get-AzureRmStorageAccount `
        -ResourceGroupName $rgName `
        -Name $storageAccountName).Context

# Create "backups" container in Storage Account

$destContainer = 
    "backups-" + 
    (Get-Date -Format o).Replace(":","-").Replace(".","-").ToLower()

New-AzureStorageContainer `
    -Name $destContainer `
    -Context $storageContext

# Create backup copy of each VM disk to backup container

ForEach ($vmDisk in $vmDisks) {

    $srcContainer = 
        $vmDisk.Split('/')[3]

    $srcBlob = 
        $vmDisk.Split('/')[4]

    Start-AzureStorageBlobCopy `
        -Context $storageContext `
        -SrcContainer $srcContainer `
        -SrcBlob $srcBlob `
        -DestContainer $destContainer

}

# Wait for copy to complete for each disk

ForEach ($vmDisk in $vmDisks) {

    $srcContainer = 
        $vmDisk.Split('/')[3]

    $srcBlob = 
        $vmDisk.Split('/')[4]

    Get-AzureStorageBlobCopyState `
        -Context $storageContext `
        -Container $destContainer `
        -Blob $srcBlob `
        -WaitForComplete

}

# Start VM if it was previously not de-allocated

if ($vmStatus[-1].Code -ne "PowerState/deallocated") {
    $vm | Start-AzureRmVm 
}