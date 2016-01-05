# Authenticate to Azure Account

Login-AzureRmAccount

# Authenticate to Azure Account with Azure AD credentials

$cred = Get-Credential

Login-AzureRmAccount `
    -Credential $cred

# Select an Azure subscription 

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# Select an Azure Datacenter Region

$location = `
    ( Get-AzureLocation ).Name | `
    Out-GridView `
        -Title "Select an Azure Datacenter  Region ..." `
        -PassThru

# Define a unique prefix for naming resources in this deployment

$prefix = "v2varmdemo" # replace with a unique lowercase value

# Define custom Tags to be used for new deployment

$tags = New-Object System.Collections.ArrayList
$tags.Add( @{ Name = "project"; Value = "demo" } )
$tags.Add( @{ Name = "costCenter"; Value = "0001" } )

# Create Resource Group 

$rgName = "${prefix}-rg"
  
$rg = New-AzureRmResourceGroup `
    -Name $rgName `
    -Location $location `
    -Tag $tags

# Create VNET1

$vnet1Name = "${prefix}-vnet1"

$subnet1Name = "${prefix}-subnet1"

$subnet2Name = "GatewaySubnet"
   
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $subnet1Name `
    -AddressPrefix "10.0.1.0/24"

$subnet2 = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $subnet2Name `
    -AddressPrefix "10.0.2.0/28"

$vnet1 = New-AzureRmVirtualNetwork `
    -Name $vnet1Name `
    -ResourceGroupName $rgName `
    -Location $location `
    -AddressPrefix "10.0.0.0/16" `
    -Subnet $subnet1, $subnet2 `
    -Tag $tags

# Create VNET2

$vnet2Name = "${prefix}-vnet2"

$subnet1Name = "${prefix}-subnet1"

$subnet2Name = "GatewaySubnet"
  
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $subnet1Name `
    -AddressPrefix "10.1.1.0/24"

$subnet2 = New-AzureRmVirtualNetworkSubnetConfig `
    -Name $subnet2Name `
    -AddressPrefix "10.1.2.0/28"

$vnet2 = New-AzureRmVirtualNetwork `
    -Name $vnet2Name `
    -ResourceGroupName $rgName `
    -Location $location `
    -AddressPrefix "10.1.0.0/16" `
    -Subnet $subnet1, $subnet2 `
    -Tag $tags

# Create a Public IP for VNET1 Gateway

$vnet1GatewayName = "${prefix}-gw1"

$vnet1PublicGatewayVipName = "${prefix}-gw1vip"
    
$vnet1PublicGatewayVip = New-AzureRmPublicIpAddress `
    -Name $vnet1PublicGatewayVipName `
    -ResourceGroupName $rgName `
    -Location $location `
    -AllocationMethod Dynamic `
    -DomainNameLabel $vnet1GatewayName `
    -Tag $tags

# Create a Public IP for VNET2 Gateway

$vnet2GatewayName = "${prefix}-gw2"

$vnet2PublicGatewayVipName = "${prefix}-gw2vip"

$vnet2PublicGatewayVip = New-AzureRmPublicIpAddress `
    -Name $vnet2PublicGatewayVipName `
    -ResourceGroupName $rgName `
    -Location $location `
    -AllocationMethod Dynamic `
    -DomainNameLabel $vnet2GatewayName `
    -Tag $tags

# Create IP Config to attach VNET1 Gateway to VIP & Subnet

$vnet1GatewayIpConfigName = "${prefix}-gw1ip"

$vnet1GatewayIpConfig = `
    New-AzureRmVirtualNetworkGatewayIpConfig `
        -Name $vnet1GatewayIpConfigName `
        -PublicIpAddressId $vnet1PublicGatewayVip.Id `
        -PrivateIpAddress "10.0.2.4" `
        -SubnetId $vnet1.Subnets[1].Id

# Provision VNET1 Gateway

$vnet1Gateway = New-AzureRmVirtualNetworkGateway `
    -Name $vnet1GatewayName `
    -ResourceGroupName $rgName `
    -Location $location `
    -GatewayType Vpn `
    -VpnType RouteBased `
    -IpConfigurations $vnet1GatewayIpConfig `
    -Tag $tags 

# Create IP Config to attach VNET2 Gateway to VIP & Subnet

$vnet2GatewayIpConfigName = "${prefix}-gw2ip"

$vnet2GatewayIpConfig = `
    New-AzureRmVirtualNetworkGatewayIpConfig `
        -Name $vnet2GatewayIpConfigName `
        -PublicIpAddressId $vnet2PublicGatewayVip.Id `
        -PrivateIpAddress "10.1.2.4" `
        -SubnetId $vnet2.Subnets[1].Id

# Provision VNET2 Gateway

$vnet2Gateway = New-AzureRmVirtualNetworkGateway `
    -Name $vnet2GatewayName `
    -ResourceGroupName $rgName `
    -Location $location `
    -GatewayType Vpn `
    -VpnType RouteBased `
    -IpConfigurations $vnet2GatewayIpConfig `
    -Tag $tags 

# Create VNET1-to-VNET2 connection

$vnet12ConnectionName = "${prefix}-vnet-1-to-2-con"

$vnet12Connection = `
    New-AzureRmVirtualNetworkGatewayConnection `
        -Name $vnet12ConnectionName `
        -ResourceGroupName $rgName `
        -Location $location `
        -ConnectionType Vnet2Vnet `
        -Tag $tags `
        -VirtualNetworkGateway1 $vnet1Gateway `
        -VirtualNetworkGateway2 $vnet2Gateway

# Create VNET2-to-VNET1 connection

$vnet21ConnectionName = "${prefix}-vnet-2-to-1-con"

$vnet21Connection = `
    New-AzureRmVirtualNetworkGatewayConnection `
        -Name $vnet21ConnectionName `
        -ResourceGroupName $rgName `
        -Location $location `
        -ConnectionType Vnet2Vnet `
        -SharedKey $vnetConnectionKey `
        -Tag $tags `
        -VirtualNetworkGateway1 $vnet2Gateway `
        -VirtualNetworkGateway2 $vnet1Gateway

