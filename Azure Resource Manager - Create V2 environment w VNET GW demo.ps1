# Authenticate to Azure Account

Add-AzureAccount 

# Authenticate to Azure Account with Azure AD credentials

$cred = Get-Credential

Add-AzureAccount `
    -Credential $cred

# Switch to Azure Resource Manager mode - deprecated, and will be removed in future versions of Azure PowerShell module

Switch-AzureMode `
    -Name AzureResourceManager

# Select an Azure subscription 

$subscriptionId = 
    (Get-AzureSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureSubscription `
    -SubscriptionId $subscriptionId

# Select an Azure Datacenter Region

$location = `
    ( Get-AzureLocation | `
        ? Name -eq "ResourceGroup" ).Locations | ` 
    Out-GridView `
        -Title "Select an Azure Datacenter  Region ..." `
        -PassThru

# Show the available Providers and Resource Types in selected Datacenter Region

( Get-AzureLocation | `
    ? Locations -Contains $location ).Name

# If needed, register ARM core resource providers

Register-AzureProvider -ProviderNamespace Microsoft.Compute

Register-AzureProvider -ProviderNamespace Microsoft.Storage

Register-AzureProvider -ProviderNamespace Microsoft.Network

Get-AzureProvider | Select-Object -Property ProviderNamespace -ExpandProperty ResourceTypes

# Define custom Tags to be used for new deployment

$tags = New-Object System.Collections.ArrayList
$tags.Add( @{ Name = "project"; Value = "demo" } )
$tags.Add( @{ Name = "costCenter"; Value = "0001" } )

# Define a unique prefix for this deployment - used to generate unique names for provisioned resources

$prefix = "kemarmdemo5"

# Define number of VMs to provision

$vmInstances = 2

# Create Resource Group if it doesn't already exist

$rgName = "${prefix}-rg"

If (!(Test-AzureResourceGroup `
    -ResourceGroupName $rgName)) {

    $rg = New-AzureResourceGroup `
        -Name $rgName `
        -Location $location `
        -Tag $tags

} Else {

    $rg = Get-AzureResourceGroup `
        -Name $rgName 

}

# Create Storage Account if it doesn't exist

$storageAccountName = "${prefix}stor01"

$storageAccountType = 
    (Get-Command `
        -Name New-AzureStorageAccount). 
            Parameters["Type"].
            Attributes.
            ValidValues |
    Out-GridView `
        -Title "Select Storage Account Type" `
        -PassThru

if (!(Test-AzureResource `
    -ResourceName $storageAccountName `
    -ResourceType "Microsoft.Storage/storageAccounts" `
    -ResourceGroupName $rgName)) {

    $storageAccount = New-AzureStorageAccount `
        -Name $storageAccountName `
        -ResourceGroupName $rgName `
        -Location $location `
        -Type $storageAccountType

} else {

    $storageAccount = Get-AzureStorageAccount `
        -ResourceGroupName $rgname `
        -Name $storageAccountName

}

Set-AzureSubscription `
    -SubscriptionId $subscriptionId `
    -CurrentStorageAccountName $storageAccountName

# Create Virtual Network if it doesn't exist

$vnetName = "${prefix}-vnet"

$subnet1Name = "${prefix}-subnet01"

$subnet2Name = "GatewaySubnet"

if (!(Test-AzureResource `
    -ResourceName $vnetName `
    -ResourceType "Microsoft.Network/virtualNetworks" `
    -ResourceGroupName $rgName)) {

    $subnet1 = New-AzureVirtualNetworkSubnetConfig `
        -Name $subnet1Name `
        -AddressPrefix "10.0.1.0/24"

    $subnet2 = New-AzureVirtualNetworkSubnetConfig `
        -Name $subnet2Name `
        -AddressPrefix "10.0.2.0/28"

    $vnet = New-AzureVirtualNetwork `
        -Name $vnetName `
        -ResourceGroupName $rgName `
        -Location $location `
        -AddressPrefix "10.0.0.0/16" `
        -Subnet $subnet1, $subnet2 `
        -Tag $tags

} else {

    $vnet = Get-AzureVirtualNetwork `
        -Name $vnetName `
        -ResourceGroupName $rgName

}


# Create Network Security Group if it doesn't exist - Rules below are example placeholders that allow selected traffic from all sources

$nsgName = "${prefix}-nsg"

if (!(Test-AzureResource `
    -ResourceName $nsgName `
    -ResourceType "Microsoft.Network/networkSecurityGroups" `
    -ResourceGroupName $rgName)) {

    $nsgRule1 = New-AzureNetworkSecurityRuleConfig `
        -Name "allow-rdp-inbound" `
        -Description "Allow Inbound RDP" `
        -SourceAddressPrefix * `
        -DestinationAddressPrefix * `
        -Protocol Tcp `
        -SourcePortRange * `
        -DestinationPortRange 3389 `
        -Direction Inbound `
        -Access Allow `
        -Priority 100

    $nsgRule2 = New-AzureNetworkSecurityRuleConfig `
        -Name "allow-http-inbound" `
        -Description "Allow Inbound HTTP" `
        -SourceAddressPrefix * `
        -DestinationAddressPrefix * `
        -Protocol Tcp `
        -SourcePortRange * `
        -DestinationPortRange 80 `
        -Direction Inbound `
        -Access Allow `
        -Priority 110

    $nsg = New-AzureNetworkSecurityGroup `
        -Name $nsgName `
        -ResourceGroupName $rgName `
        -Location $location `
        -SecurityRules $nsgRule1, $nsgRule2 `
        -Tag $tags

} else {

    $nsg = Get-AzureNetworkSecurityGroup ` 
        -Name $nsgName `
        -ResourceGroupName $rgName

}

# Define Public VIP Address, if not created

$publicVipName = "${prefix}-vip"

$domainName = "${prefix}app"

if (!(Test-AzureResource `
    -ResourceName $publicVipName `
    -ResourceType "Microsoft.Network/publicIPAddresses" `
    -ResourceGroupName $rgName)) {

    $publicVip = New-AzurePublicIpAddress `
        -Name $publicVipName `
        -ResourceGroupName $rgName `
        -Location $location `
        -AllocationMethod Dynamic `
        -DomainNameLabel $domainName `
        -Tag $tags

} else {

    $publicVip = Get-AzurePublicIpAddress `
        -Name $publicVipName `
        -ResourceGroupName $rgName

}

# Define Azure Load Balancer configuration

$lbName = "${prefix}-lb"

if (!(Test-AzureResource `
    -ResourceName $lbName `
    -ResourceType "Microsoft.Network/loadBalancers" `
    -ResourceGroupName $rgName)) {

    $lbFeIpConfigName = "lb-feip"

    $lbFeIpConfig = New-AzureLoadBalancerFrontendIpConfig `
        -Name $lbFeIpConfigName `
        -PublicIpAddress $publicVIP

    $lbInboundNatRules = @()

    for ($count = 1; $count -le $vmInstances; $count++) {

        $ruleName = "nat-rdp-${count}"

        $frontEndPort = 3389 + $count

        $backEndPort = 3389

        $lbInboundNatRules += New-AzureLoadBalancerInboundNatRuleConfig `
            -Name $ruleName `
            -FrontendIpConfigurationId $lbFeIpConfig.Id `
            -Protocol Tcp `
            -FrontendPort $frontEndPort `
            -BackendPort $backEndPort

    }

    $lbBeIpPoolName = "lb-be-ip-pool"

    $lbBeIpPool = New-AzureLoadBalancerBackendAddressPoolConfig `
        -Name $lbBeIpPoolName

    $lbProbeName = "lb-probe"

    $lbProbe = New-AzureLoadBalancerProbeConfig `
        -Name $lbProbeName `
        -RequestPath "/" `
        -Protocol Http `
        -Port 80 `
        -IntervalInSeconds 15 `
        -ProbeCount 2

    $lbRuleName = "lb-http"

    $lbRule = New-AzureLoadBalancerRuleConfig `
        -Name $lbRuleName `
        -FrontendIpConfigurationId $lbFeIpConfig.Id `
        -BackendAddressPoolId $lbBeIpPool.Id `
        -ProbeId $lbProbe.Id `
        -Protocol Tcp `
        -FrontendPort 80 `
        -BackendPort 80 `
        -LoadDistribution Default

    $lb = New-AzureLoadBalancer `
        -Name $lbName `
        -ResourceGroupName $rgName `
        -Location $location `
        -FrontendIpConfiguration $lbFeIpConfig `
        -BackendAddressPool $lbBeIpPool `
        -Probe $lbProbe `
        -InboundNatRule $lbInboundNatRules `
        -LoadBalancingRule $lbRule

} else {

    $lb = Get-AzureLoadBalancer `
        -Name $lbName `
        -ResourceGroupName $rgName

}

# Create an Azure Availability Set for VM high availability, if it doesn't exist

$avSetName = "${prefix}-as"

if (!(Test-AzureResource `
    -ResourceName $avSetName `
    -ResourceType "Microsoft.Compute/availabilitySets" `
    -ResourceGroupName $rgName)) {

    $avSet = New-AzureAvailabilitySet `
        -Name $avSetName `
        -ResourceGroupName $rgName `
        -Location $location

} else {

    $avSet = Get-AzureAvailabilitySet `
        -Name $avSetName `
        -ResourceGroupName $rgName

}

# Define NICs for each VM

$nics = @()

for ($count = 1; $count -le $vmInstances; $count++) {

    $nicName = "${prefix}-nic${count}"

    if (!(Test-AzureResource `
        -ResourceName $nicName `
        -ResourceType "Microsoft.Network/networkInterfaces" `
        -ResourceGroupName $rgName)) {

        $nicIndex = $count - 1
        
        $nics += New-AzureNetworkInterface `
            -Name $nicName `
            -ResourceGroupName $rgName `
            -Location $location `
            -SubnetId $vnet.Subnets[0].Id `
            -NetworkSecurityGroupId $nsg.Id `
            -LoadBalancerInboundNatRuleId $lb.InboundNatRules[$nicIndex].Id `
            -LoadBalancerBackendAddressPoolId $lb.BackendAddressPools[0].Id

    } else {

        $nics += Get-AzureNetworkInterface `
            -Name $nicName `
            -ResourceGroupName $rgName

    }

}

# Select the VM Image Publisher - ex. MicrosoftWindowsServer

$publisherName = `
    ( Get-AzureVMImagePublisher `
        -Location $location ).PublisherName | 
    Out-GridView `
        -Title "Select a VM Image Publisher ..." `
        -PassThru

# Select the VM Image Offer - ex. WindowsServer

$offerName = `
    ( Get-AzureVMImageOffer `
        -PublisherName $publisherName `
        -Location $location ).Offer | 
    Out-GridView `
        -Title "Select a VM Image Offer ..." `
        -PassThru

# Select the VM Image SKU - ex. 2012-R2-Datacenter

$skuName = `
    ( Get-AzureVMImageSku `
        -PublisherName $publisherName `
        -Offer $offerName `
        -Location $location ).Skus |
    Out-GridView `
        -Title "Select a VM Image SKU" `
        -PassThru

# Select the VM Image Version - ex. latest

$version = "latest"

# Select an Azure VM Instance Size - ex. Standard_A3

$vmSize = `
    ( Get-AzureVMSize `
        -Location $location | 
    Select-Object `
        Name, `
        NumberOfCores, `
        MemoryInMB, `
        MaxDataDiskCount | 
    Out-GridView `
        -Title "Select a VM Instance Size" `
        -PassThru ).Name

# Specify VM local Admin credentials

$vmAdminCreds = Get-Credential `
    -Message "Enter Local Admin credentials for new VMs ..." 

# Build the configuration for each VM and provision each VM

$vm = @()

for ($count = 1; $count -le $vmInstances; $count++) { 
    
    $vmName = "vm${count}"

    if (!(Test-AzureResource `
        -ResourceName $vmName `
        -ResourceType "Microsoft.Compute/virtualMachines" `
        -ResourceGroupName $rgName)) {

        $vmIndex = $count - 1

        $osDiskLabel = "OSDisk"
    
        $osDiskName = "${prefix}-${vmName}-osdisk"

        $osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() `
            + "vhds/${osDiskName}.vhd"

        $dataDiskSize = 200 # Size in GB

        $dataDiskLabel = "DataDisk01"

        $dataDiskName = "${prefix}-${vmName}-datadisk01"

        $dataDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() `
            + "vhds/${dataDiskName}.vhd"

        $vmConfig = `
            New-AzureVMConfig `
                -VMName $vmName `
                -VMSize $vmSize `
                -AvailabilitySetId $avSet.Id |
            Set-AzureVMOperatingSystem `
                -Windows `
                -ComputerName $vmName `
                -Credential $vmAdminCreds `
                -ProvisionVMAgent `
                -EnableAutoUpdate |
            Set-AzureVMSourceImage `
                -PublisherName $publisherName `
                -Offer $offerName `
                -Skus $skuName `
                -Version $version |
            Set-AzureVMOSDisk `
                -Name $osDiskLabel `
                -VhdUri $osDiskUri `
                -CreateOption fromImage |
            Add-AzureVMDataDisk `
                -Name $dataDiskLabel `
                -DiskSizeInGB $dataDiskSize `
                -VhdUri $dataDiskURI `
                -CreateOption empty |
            Add-AzureVMNetworkInterface `
                -Id $nics[$vmIndex].Id `
                -Primary 

        New-AzureVM `
            -VM $vmConfig `
            -ResourceGroupName $rgName `
            -Location $location `
            -Tags $tags

    } 

    # Get the VM if already provisioned

    $vm += Get-AzureVM `
        -Name $vmName `
        -ResourceGroupName $rgName

}

# Set DSC archive and configuration values

$dscStorageAccountName = "keith02"

$dscArchiveName = "dscWebSiteConfig.ps1.zip"

$dscConfigFunction = "dscWebSiteConfig.ps1\WebSiteConfig"

$dscConfig = ConvertTo-Json -Depth 8 `
@{

    SasToken = ""

    ModulesUrl = "https://${dscStorageAccountName}.blob.core.windows.net/windows-powershell-dsc/${dscArchiveName}"

    ConfigurationFunction = "$dscConfigFunction"

} 

# Apply DSC Configuration to each VM

$vm | ForEach-Object {

    $extensionName = $_.Name + "-dscExtension"

    Set-AzureVMExtension `
        -VMName $_.Name `
        -ResourceGroupName $_.ResourceGroupName `
        -Name $extensionName `
        -Location $location `
        -Publisher "Microsoft.PowerShell" `
        -ExtensionType "DSC" `
        -Version 2.0 `
        -SettingString $dscConfig

}

# Check status of DSC extension

$vm | ForEach-Object {

    $extensionName = $_.Name + "-dscExtension"

    Get-AzureVMExtension `
        -VMName $_.Name `
        -ResourceGroupName $_.ResourceGroupName `
        -Name $extensionName 

}

# Define values for VNET Gateway

$vnetGatewayName = "${prefix}-gw"
$vnetGatewayIpConfigName = "${prefix}-gwip"
$vnetConnectionName = "${prefix}-gwcon"
$vnetConnectionKey = "abcd1234"
$publicGatewayVipName = "${prefix}-vip"
$localGatewayName = "${prefix}-corpgw"
$localGatewayIP = "131.105.2.5"
$localNetworkPrefix = @( "10.1.0.0/24", "10.2.0.0/24" )

# Create a Public VIP for the Gateway

if (!(Test-AzureResource `
    -ResourceName $publicGatewayVipName `
    -ResourceType "Microsoft.Network/publicIPAddresses" `
    -ResourceGroupName $rgName)) {

    $publicGatewayVip = New-AzurePublicIpAddress `
        -Name $publicGatewayVipName `
        -ResourceGroupName $rgName `
        -Location $location `
        -AllocationMethod Dynamic `
        -DomainNameLabel $vNetGatewayName `
        -Tag $tags

} else {

    $publicGatewayVip = Get-AzurePublicIpAddress `
        -Name $publicGatewayVipName `
        -ResourceGroupName $rgName

}

# Create IP Config to attach Gateway to VIP & Subnet

$vnetGatewayIpConfig = `
    New-AzureVirtualNetworkGatewayIpConfig `
        -Name $vnetGatewayIpConfigName `
        -PublicIpAddressId $publicGatewayVip.Id `
        -SubnetId $vnet.Subnets[1].Id

# Provision VNET Gateway

$vnetGateway = New-AzureVirtualNetworkGateway `
    -Name $vnetGatewayName `
    -ResourceGroupName $rgName `
    -Location $location `
    -GatewayType Vpn `
    -VpnType RouteBased `
    -IpConfigurations $vnetGatewayIpConfig `
    -Tag $tags 

# Define Local Network

$localGateway = New-AzureLocalNetworkGateway `
    -Name $localGatewayName `
    -ResourceGroupName $rgName `
    -Location $location `
    -GatewayIpAddress $localGatewayIP `
    -AddressPrefix $localNetworkPrefix `
    -Tag $tags

# Define Site-to-Site Tunnel for Gateway

$vnetConnection = `
    New-AzureVirtualNetworkGatewayConnection `
        -Name $vnetConnectionName `
        -ResourceGroupName $rgName `
        -Location $location `
        -ConnectionType IPsec `
        -SharedKey $vnetConnectionKey `
        -Tag $tags `
        -VirtualNetworkGateway1 $vnetGateway `
        -LocalNetworkGateway2 $localGateway

# Get all Azure Resources within Resource Group

Get-AzureResource `
    -ResourceGroupName $rgName `
    -OutputObjectFormat New

# Get Azure Resources by Tag

Get-AzureResource `
    -TagName "project" `
    -TagValue "demo" `
    -OutputObjectFormat New

Get-AzureResource `
    -TagName "costCenter" `
    -TagValue "0001" `
    -OutputObjectFormat New

# Get the properties of all resources of a particular type within a Resource Group

(Get-AzureResource `
    -ResourceGroupName $rgName `
    -ResourceType "Microsoft.Compute/virtualMachines" `
    -OutputObjectFormat New `
    -ExpandProperties).Properties

# Check the status of all VMs within a Resource Group

Get-AzureResource `
    -ResourceGroupName $rgName `
    -ResourceType "Microsoft.Compute/virtualMachines" `
    -OutputObjectFormat New | 
Get-AzureVM `
    -Status | 
Select-Object `
    Name, `
    @{n="Status";e={$_.Statuses[-1].DisplayStatus}}

# Stop all VMs within a Resource Group

Get-AzureResource `
    -ResourceGroupName $rgName `
    -ResourceType "Microsoft.Compute/virtualMachines" `
    -OutputObjectFormat New | 
Stop-AzureVM -Force

# Start all VMs within a Resource Group

Get-AzureResource `
    -ResourceGroupName $rgName `
    -ResourceType "Microsoft.Compute/virtualMachines" `
    -OutputObjectFormat New | 
Start-AzureVM
