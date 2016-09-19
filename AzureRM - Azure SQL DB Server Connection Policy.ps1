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


# Select Azure SQL Database Server

    $sqlServerName =
        ( Get-AzureRmSqlServer `
            -ResourceGroupName $rgName |
            Out-GridView `
              -Title "Select an Azure SQL Server ..." `
              -PassThru
        ).ServerName

    $sqlServer = Get-AzureRmSqlServer `
        -ResourceGroupName $rgName `
        -ServerName $sqlServerName

# Set Azure SQL Database Server Default Connection Policy to Proxy

    $sqlServerResourceId = "/subscriptions/$subscriptionId/resourceGroups/$rgName/providers/Microsoft.Sql/servers/$sqlServerName"

    $location = $sqlServer.Location

    $sqlConnectionPolicyId = "$sqlServerResourceId/connectionPolicies/Default"

    New-AzureRmResource `
        -ResourceId $sqlConnectionPolicyId `
        -Location $location `
        -Properties @{"connectionType"="Proxy"}

# Confirm configuration of Azure SQL Database Server Default Connection Policy

    Get-AzureRmResource `
        -ResourceId $sqlConnectionPolicyId
