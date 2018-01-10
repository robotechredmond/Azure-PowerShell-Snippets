Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName "AZ Test"

Get-AzureRmVirtualNetwork -ResourceGroupName "kemsqlaz-rg"

$vnetID = "/subscriptions/sub-id/resourceGroups/kemsqlaz-rg/providers/Microsoft.Network/virtualNetworks/kemsqlvnet-rg"

Select-AzureRmSubscription -SubscriptionName "Contoso Sports"

New-AzureRmResourceGroup -Name "kemdns01-rg" -Location "eastus2"

New-AzureRmDnsZone -Name contoso.local -ResourceGroupName "kemdns01-rg" -ZoneType Private -RegistrationVirtualNetworkId $vnetID
