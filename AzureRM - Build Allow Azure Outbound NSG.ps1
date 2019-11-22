# Sign-in with Azure account credentials

Connect-AZAccount

# Select Azure Subscription

    $subscriptionId = 
        (Get-AZSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId


    Select-AZSubscription `
        -SubscriptionId $subscriptionId

# Select Azure Resource Group 

    $rgName =
        (Get-AZResourceGroup |
         Out-GridView `
            -Title "Select an Azure Resource Group ..." `
            -PassThru).ResourceGroupName

# Download current list of Azure Public IP addresses
# See this link for latest list: https://www.microsoft.com/en-in/download/confirmation.aspx?id=41653

    $downloadUri = "https://www.microsoft.com/en-in/download/confirmation.aspx?id=41653"

    $downloadPage = Invoke-WebRequest -Uri $downloadUri

    $xmlFileUri = ($downloadPage.RawContent.Split('"') -like "https://*PublicIps*")[0]

    $response = Invoke-WebRequest -Uri $xmlFileUri

# Get list of Regions and corresponding public IP address ranges

    [xml]$xmlResponse = [System.Text.Encoding]::UTF8.GetString($response.Content)

    $regions = $xmlResponse.AzurePublicIpAddresses.Region

# Select Azure datacenter regions for which to build an outbound NSG rule configuration

    $selectedRegions =
        $regions.Name |
        Out-GridView `
            -Title "Select Azure Datacenter Regions ..." `
            -PassThru

    $ipRange = ( $regions | where-object Name -In $selectedRegions ).IpRange

# Build Network Security Group rules

    $rules = @()

    $rulePriority = 100

    ForEach ($subnet in $ipRange.Subnet) {

        $ruleName = "Allow_Azure_Out_" + $subnet.Replace("/","-")
    
        $rules += 
            New-AZNetworkSecurityRuleConfig `
                -Name $ruleName `
                -Description "Allow outbound to Azure $subnet" `
                -Access Allow `
                -Protocol * `
                -Direction Outbound `
                -Priority $rulePriority `
                -SourceAddressPrefix VirtualNetwork `
                -SourcePortRange * `
                -DestinationAddressPrefix "$subnet" `
                -DestinationPortRange *

        $rulePriority++

    }

    $rules += 
        New-AZNetworkSecurityRuleConfig `
            -Name "Deny_Internet_Out" `
            -Description "Deny outbound to Internet" `
            -Access Deny `
            -Protocol * `
            -Direction Outbound `
            -Priority 4001 `
            -SourceAddressPrefix VirtualNetwork `
            -SourcePortRange * `
            -DestinationAddressPrefix Internet `
            -DestinationPortRange *

# Set Azure Datacenter Region in which to create Network Security Group

    $location = "southeastasia"

# Create Network Security Group

    $nsgname = "Allow_Azure_Out"

    $nsg = 
        New-AZNetworkSecurityGroup `
            -Name "$nsgName" `
            -ResourceGroupName $rgName `
            -Location $location `
            -SecurityRules $rules

# Associate NSG to a VNET subnet

    # Select VNET

        $vnetName = 
            (Get-AZVirtualNetwork `
                -ResourceGroupName $rgName).Name |
             Out-GridView `
                -Title "Select an Azure VNET ..." `
                -PassThru

        $vnet = Get-AZVirtualNetwork `
            -ResourceGroupName $rgName `
            -Name $vnetName

    # Select Subnet 

        $subnetName = 
            $vnet.Subnets.Name |
            Out-GridView `
                -Title "Select an Azure Subnet ..." `
                -PassThru

        $subnet = $vnet.Subnets | 
            Where-Object Name -eq $subnetName

    # Associate NSG to selected Subnet

        Set-AZVirtualNetworkSubnetConfig `
            -VirtualNetwork $vnet `
            -Name $subnetName `
            -AddressPrefix $subnet.AddressPrefix `
            -NetworkSecurityGroup $nsg |
        Set-AZVirtualNetwork
