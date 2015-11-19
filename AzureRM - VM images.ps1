$location = "South Central US"

Get-AzureRmVMImagePublisher -Location $location

$publisher = "datastax"

Get-AzureRmVMImageOffer -location $location -PublisherName $publisher

$offer = "datastax"

Get-AzureRmVMImageSku -Location $location -PublisherName $publisher -Offer $offer

$sku = "enterprise"

$version = (Get-AzureRmVMImage -Location $location -PublisherName $publisher -Offer $offer -Sku $sku)[-1].Version

$vmImage = Get-AzureRmVMImage -Location $location -PublisherName $publisher -Offer $offer -Sku $sku -Version $version

