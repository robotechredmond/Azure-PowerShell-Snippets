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

# Select Azure VNET on which to deploy App Gateway

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

# Select empty Azure subnet on which to deploy App Gateway

$subnetName = 
    $vnet.Subnets.Name |
    Out-GridView `
        -Title "Select an empty Azure Subnet ..." `
        -PassThru

$subnet = $vnet.Subnets | 
    Where-Object Name -eq $subnetName

# Define name for App Gateway

$agwName = "kemagw01"

# Create App Gateway IP configuration object

$agwIpConfigName = "$agwName-ip"

$agwIpConfig = New-AzureRmApplicationGatewayIPConfiguration `
    -Name $agwIPConfigName `
    -Subnet $subnet

# Define back-end IP address pool

$agwBePoolName = "$agwName-be-pool"

$agwBePoolIps = @( "10.1.0.4", "10.1.0.5")

$agwBePool = New-AzureRmApplicationGatewayBackendAddressPool `
    -Name $agwBePoolName `
    -BackendIPAddresses $agwBePoolIps

# Define back-end ports 

$agwBePort = 80

$agwBeSettingsName = "$agwName-be-$agwBePort"

$agwBeSet = New-AzureRmApplicationGatewayBackendHttpSettings `
    -Name $agwBeSettingsName `
    -Port $agwBePort `
    -Protocol Http `
    -CookieBasedAffinity Enabled

# Create front-end public IP address resource

$agwFeIpName = "$agwName-pip"

$agwFeIp = New-AzureRmPublicIpAddress `
    -ResourceGroupName $rgName `
    -name $agwFeIpName `
    -location $location `
    -AllocationMethod Dynamic

# Define front-end IP configurations for each public IP address

$agwFeIpConfigName = "$($agwFeIp.Name)-feipconfig"

$agwFeIpConfig = New-AzureRmApplicationGatewayFrontendIPConfig `
    -Name $agwFeIpConfigName `
    -PublicIPAddress $agwFeIp

# Define front-end ports

$agwFePortNum = 80

$agwFePortName = "$agwName-feport-$agwFePortNum"

$agwFePort = New-AzureRmApplicationGatewayFrontendPort `
    -Name $agwFePortName `
    -Port $agwFePortNum

# Define a front-end listener

$agwFeListenerName = "$($agwFeIp.Name)-felistener-$agwFePortNum"

$agwFeListener = New-AzureRmApplicationGatewayHttpListener `
    -Name $agwFeListenerName `
    -Protocol Http `
    -FrontendIPConfiguration $agwFeIpConfig `
    -FrontendPort $agwFePort

# Define a rule

$agwRuleName = "$($agwFeIp.Name)-rule-$agwFePortNum"

$agwRule = New-AzureRmApplicationGatewayRequestRoutingRule `
    -Name $agwRuleName `
    -RuleType Basic `
    -HttpListener $agwFeListener `
    -BackendHttpSettings $agwBeSet `
    -BackendAddressPool $agwBePool

# Specify App Gateway SKU

$agwSkuName = "Standard_Small"

$agwSku = New-AzureRmApplicationGatewaySku `
    -Name $agwSkuName `
    -Tier Standard `
    -Capacity 2

# Create App Gateway

$agw = New-AzureRmApplicationGateway `
    -Name $agwName `
    -ResourceGroupName $rgName `
    -Location $location `
    -Sku $agwSku `
    -GatewayIpConfigurations $agwIPConfig `
    -FrontendIpConfigurations $agwFeIpConfig `
    -FrontendPorts $agwFePort `
    -HttpListeners $agwFeListener `
    -BackendAddressPools $agwBePool `
    -BackendHttpSettingsCollection $agwBeSet `
    -RequestRoutingRules $agwRule `
    -Debug

# Start App Gateway

$agw = Remove-AzureRmApplicationGateway `
    -Name $agwName `
    -ResourceGroupName $rgName

Start-AzureRmApplicationGateway `
    -ApplicationGateway $agw

Remove-AzureRM