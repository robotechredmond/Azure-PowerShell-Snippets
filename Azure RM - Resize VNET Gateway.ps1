Login-AzureRmAccount

Select-AzureRmSubscription -SubscriptionName "name-of-subscription"

$vnetGw = Get-AzureRmVirtualNetworkGateway -ResourceGroupName "resource-group-name" -Name "vnet-gateway-name"

Resize-AzureRmVirtualNetworkGateway -VirtualNetworkGateway $vnetGw -GatewaySku HighPerformance