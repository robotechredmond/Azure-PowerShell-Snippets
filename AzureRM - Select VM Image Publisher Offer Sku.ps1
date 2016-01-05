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

# Set Azure Datacenter Region Location

$location = 
    "West US"

# Select VM Image Publisher

$vmImagePublisher = 
    ( Get-AzureRmVMImagePublisher -Location $location ).PublisherName |
      Out-GridView -Title "Select VM Image Publisher" -PassThru

# Select VM Image Offer

$vmImageOffer =
    ( Get-AzureRmVmImageOffer -Location $location -PublisherName $vmImagePublisher ).Offer |
      Out-GridView -Title "Select VM Image Offer" -PassThru

# Select VM Image Sku

$vmImageSku =
    ( Get-AzureRmVmImageSku -Location $location -PublisherName $vmImagePublisher -Offer $vmImageOffer ).Skus |
      Out-GridView -Title "Select VM Image Sku" -PassThru

# Set VM Image Version

$vmImageVersion = "latest"

# Get Azure VM Image information

$vmImage = Get-AzureRmVmImage -Location $location -PublisherName $vmImagePublisher -Offer $vmImageOffer -Skus $vmImageSku 

$vmImage

$vmImage.Id


