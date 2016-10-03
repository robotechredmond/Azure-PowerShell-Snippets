# Sign-in to Azure via Azure Resource Manager

    Login-AzureRmAccount

# Select Azure Subscription

    $subscriptionId = 
        ( Get-AzureRmSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# Select Azure Resource Group

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Select Azure Resource

     $resourceId =
        ( Get-AzureRmLoadBalancer -ResourceGroupName $rgName |
            Select-Object Name, Id |
            Out-GridView `
              -Title "Select an Azure Load Balancer ..." `
              -PassThru
        ).Id

     $resourceId =
        ( Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgName |
            Select-Object Name, Id |
            Out-GridView `
              -Title "Select an Azure NSG ..." `
              -PassThru
        ).Id

     $resourceId =
        ( Get-AzureRmVM -ResourceGroupName $rgName |
            Select-Object Name, Id |
            Out-GridView `
              -Title "Select an Azure VM ..." `
              -PassThru
        ).Id

# Get Metric Definitions for Resource

    Get-MetricDefinitions -ResourceId $resourceId -DetailedOutput
