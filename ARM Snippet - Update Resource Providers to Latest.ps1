Add-AzureAccount

Select-AzureSubscription -Name "Subscription Name"

Switch-AzureMode -Name AzureResourceManager

Register-AzureProvider -ProviderNamespace Microsoft.Compute

Register-AzureProvider -ProviderNamespace Microsoft.Storage

Register-AzureProvider -ProviderNamespace Microsoft.Network

Get-AzureProvider | Select-Object -Property ProviderNamespace -ExpandProperty ResourceTypes

Get-AzureResource -ResourceGroupName Microsoft.Network -ResourceType virtualnetworks -OutputObjectFormat New -ApiVersion 2015-06-01

Get-AzureVM

Stop-AzureVM 