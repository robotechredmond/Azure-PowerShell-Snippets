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

# Select Azure Resource Group in which existing VNET is provisioned

$rgName =
    (Get-AzureRmResourceGroup |
     Out-GridView `
        -Title "Select an Azure Resource Group ..." `
        -PassThru).ResourceGroupName

# Select Azure VNET on which to enable a user-defined route

$vnetName = 
    (Get-AzureRmVirtualNetwork `
        -ResourceGroupName $rgName).Name |
     Out-GridView `
        -Title "Select an Azure VNET ..." `
        -PassThru

$vnet = Get-AzureRmVirtualNetwork `
    -ResourceGroupName $rgName `
    -Name $vnetName

$location = $vnet.Location

# Select Azure Subnet on which to enable a user-defined route

$subnetName = 
    $vnet.Subnets.Name |
    Out-GridView `
        -Title "Select an Azure Subnet ..." `
        -PassThru

$subnet = $vnet.Subnets | 
    Where-Object Name -eq $subnetName

# Create new User-defined Routing Table

$routeTableName = "demoroutetable"

$routeTable = New-AzureRmRouteTable `
    -Name $routeTableName `
    -ResourceGroupName $rgName `
    -Location $location

# Add a user-defined route to the Routing Table

$routeName = "demoroute"

$routeTable | 
    Add-AzureRmRouteConfig `
        -Name $routeName `
        -AddressPrefix "10.2.0.0/24" `
        -NextHopType VirtualAppliance `
        -NextHopIpAddress "10.1.1.10" | 
    Set-AzureRmRouteTable

# Assign User-defined Routing Table to selected subnet

Set-AzureRmVirtualNetworkSubnetConfig `
    -VirtualNetwork $vnet `
    -Name $subnetName `
    -AddressPrefix $subnet.AddressPrefix `
    -RouteTableId $routeTable.Id |
    Set-AzureRmVirtualNetwork

# Confirm User-defined Routing Table is provisioned and assigned to subnet

Get-AzureRmRouteTable `
    -ResourceGroupName $rgName `
    -Name $routeTableName

# Configure Appliance VM for IP Forwarding

$vmName = 
    (Get-AzureRmVM -ResourceGroupName $rgName).Name |
        Out-GridView `
            -Title "Select a VM to configure forwarding ..." `
            -PassThru

$nicName = 
    ((Get-AzureRmVM `
        -ResourceGroupName $rgName `
        -Name $vmName).NetworkInterfaceIDs).Split("/")[-1] |
            Out-GridView `
                -Title "Select a NIC to configure forwarding ..." `
                -PassThru

$nicConfig = 
    Get-AzureRmNetworkInterface `
        -ResourceGroupName $rgName `
        -Name $nicName

$nicConfig.EnableIPForwarding = $true

$nicConfig | Set-AzureRmNetworkInterface
