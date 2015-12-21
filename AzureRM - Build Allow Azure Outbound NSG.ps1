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

# Select Azure Resource Group 

$rgName =
    (Get-AzureRmResourceGroup |
     Out-GridView `
        -Title "Select an Azure Resource Group ..." `
        -PassThru).ResourceGroupName

# Download currently list of Azure Public IP addresses
# See this link for latest list: https://www.microsoft.com/en-in/download/confirmation.aspx?id=41653

    $uri = "https://download.microsoft.com/download/0/1/8/018E208D-54F8-44CD-AA26-CD7BC9524A8C/PublicIPs_20151214.xml"

    $response = Invoke-WebRequest -Uri $uri

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

# Build Network Security Group

    $rules = @()

    $rulePriority = 100

    ForEach ($subnet in $ipRange.Subnet) {

        $ruleName = "Allow_Azure_Out_" + $subnet.Replace("/","-")
    
        $rules += 
            New-AzureRmNetworkSecurityRuleConfig `
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
        New-AzureRmNetworkSecurityRuleConfig `
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
        New-AzureRmNetworkSecurityGroup `
            -Name "$nsgName" `
            -ResourceGroupName $rgName `
            -Location $location `
            -SecurityRules $rules
