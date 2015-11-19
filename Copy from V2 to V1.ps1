# Login to Azure Subscription via ARM (v2) mode
Login-AzureRmAccount

# Select Subscription in which V2 VM exists
$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# Select Resource Group in which V2 VM exists
$rgName =
(Get-AzureRmResourceGroup |
    Out-GridView `
    -Title "Select an Azure Resource Group ..." `
    -PassThru).ResourceGroupName

# Select V2 VM
$vmName = (Get-AzureRmVm -ResourceGroupName $rgName).Name |
    Out-GridView `
    -Title "Select Azure V2 VM ..."`
    -PassThru

# Stop V2 VM if currently running
Stop-AzureRmVm -ResourceGroupName $rgName -Name $vmName

# Identify V2 VM disk info
$vm = Get-AzureRmVm -ResourceGroupName $rgName -Name $vmName
$osDiskUri = $vm.StorageProfile.OSDisk.VirtualHardDisk.Uri
$dataDisks = $vm.StorageProfile.DataDisks

# Get Storage Account and blob info
$storageAccountName = $osDiskUri.Split("/.")[2]
$storageAccountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -Name $storageAccountName).Key1
$containerName = $osDiskUri.Split("/")[-2]
$blobName = $osDiskUri.Split("/")[-1]

# Delete V2 VM but preserve disks
Remove-AzureRmVm -ResourceGroupName $rgName -Name $vmName

# Login to Azure subscription via ASM (Classic) mode
Add-AzureAccount

# Set default Azure subscription via ASM (Classic) mode
Select-AzureSubscription -SubscriptionId $subscriptionId -Default

# Create new "Classic" Storage Account
$v1StorageAccountName = "v1stor01"
$location = "West US"
New-AzureStorageAccount -StorageAccountName $v1StorageAccountName -Location $location -Type "Standard_LRS"

# Get Access Key for new V1 Storage Account
$v1StorageAccountKey = (Get-AzureStorageKey -StorageAccountName $v1StorageAccountName).Primary

# Set Source and Destination Storage Context
$srcStorageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey
$dstStorageContext = New-AzureStorageContext -StorageAccountName $v1StorageAccountName -StorageAccountKey $v1StorageAccountKey

# Create destination Storage Container in destination Storage Account using same name as source Storage Container
New-AzureStorageContainer -Name $containerName -Context $dstStorageContext

# Wait until source Blob lease is "unlocked"
Do 
{
    Sleep 30
    $blobLeaseStatus = (Get-AzureStorageBlob -Context $srcStorageContext -Container $containerName -Blob $blobName).ICloudBlob.Properties.LeaseStatus
} Until ($blobLeaseStatus -eq "Unlocked")

# Initiate copy from source to destination Storage Account
Start-AzureStorageBlobCopy -Context $srcStorageContext -SrcContainer $containerName -SrcBlob $blobName -DestContext $dstStorageContext -DestContainer $containerName -DestBlob $blobName

# Wait for copy to complete
Get-AzureStorageBlobCopyState -Context $dstStorageContext -Container $containerName -Blob $blobName -WaitForComplete

# Get properties for copied Blob
$dstBlobUri = (Get-AzureStorageBlob -Context $dstStorageContext -Container $containerName -Blob $blobName).ICloudBlob.Uri.AbsoluteUri

# Add Azure Disk for copied Blob
$osName = "Linux"
Add-AzureDisk -DiskName $blobName -Label $blobName -MediaLocation $dstBlobUri -OS $osName
