<#
 # Enable existing ARM-provisoned ExpressRoute circuit for Classic operations
#>

# Select Azure Cloud Environment

    $azureEnv = 
        (Get-AzureEnvironment).Name |
        Out-GridView `
            -Title "Select Azure Environment ..." `
            -PassThru

# Sign-in to ARM with Azure account credentials

    Login-AzureRmAccount `
        -EnvironmentName $azureEnv

# Select Azure Subscription

    $subscriptionId = 
        (Get-AzureRmSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# Select Azure Resource Group that contains existing ExpressRoute circuit

    $rgName =
        (Get-AzureRmResourceGroup |
         Out-GridView `
            -Title "Select an Azure Resource Group ..." `
            -PassThru).ResourceGroupName

# Select existing ExpressRoute circuit

    $cktName =
        (Get-AzureRmExpressRouteCircuit | 
         Out-GridView `
            -Title "Select an ExpressRoute circuit ..." `
            -PassThru).Name

# Enable Classic Operations for ARM-provisioned ExpressRoute circuit

    $ckt = 
        Get-AzureRmExpressRouteCircuit `
            -Name $cktName `
            -ResourceGroupName $rgName

    $ckt.AllowClassicOperations = $true 

    Set-AzureRmExpressRouteCircuit `
        -ExpressRouteCircuit $ckt 

<#
 # Authorize ExpressRoute circuit for linking to Classic VNET in separate subscription
#>

# Import ExpressRoute PowerShell Module for Classic operations

    Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\ExpressRoute\ExpressRoute.psd1"

# Sign-in to ASM with Azure AD credentials

    Add-AzureAccount `
        -Environment $azureEnv

# Select same Azure subscription for use with ASM

    Select-AzureSubscription `
        -SubscriptionId $subscriptionId

    $authIds = 
        Read-Host -Prompt "Enter comma-separated list of Microsoft Ids to authorize"

    $authDesc = 
        Read-Host -Prompt "Enter description for this circuit authorization"

    $authLimit = 
        Read-Host -Prompt "Enter a limit on # of VNETs that can be connected for this authorization"

    New-AzureDedicatedCircuitLinkAuthorization `
        -ServiceKey $ckt.ServiceKey `
        -MicrosoftIds $authIds `
        -Description "$authDesc" `
        -Limit $authLimit

<#
 # Link ExpressRoute Circuit to Classic VNET in different subscription
#>

# Import ExpressRoute PowerShell Module for Classic operations

    Import-Module "C:\Program Files (x86)\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\ExpressRoute\ExpressRoute.psd1"

# Select Azure Cloud Environment

    $azureEnv = 
        (Get-AzureEnvironment).Name |
        Out-GridView `
            -Title "Select Azure Environment ..." `
            -PassThru

# Sign-in to ASM as Authorized User

    Add-AzureAccount `
        -Environment $azureEnv

# Select Azure Subscription to connect to shared ExpressRoute circuit

    $authSubscriptionId = 
        (Get-AzureSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

    Select-AzureSubscription `
        -SubscriptionId $authSubscriptionId

# Get circuit properties for authorized ExpressRoute circuit

    $ckt = Get-AzureAuthorizedDedicatedCircuit

# Connect authorized ExpressRoute circuit to Classic VNET with GatewaySubnet and VNET Gateway already provisioned
# See this link for steps to provision GatewaySubnet and VNET Gateway: https://docs.microsoft.com/en-us/azure/expressroute/expressroute-howto-vnet-portal-classic

    $vnetName = "classic-vnet-name"

    New-AzureDedicatedCircuitLink -ServiceKey $ckt.ServiceKey -VNetName $vnetName