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

# If needed, register ARM core resource providers

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Sql

    Get-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Sql | 
            Select-Object `
            -Property ProviderNamespace `
            -ExpandProperty ResourceTypes

# Select Azure Resource Group in which existing Azure SQL Server resource is provisioned

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select existing Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Select Azure SQL Server resource to reconfigure

    $sqlSrvName = 
        ( Get-AzureRmSqlServer `
            -ResourceGroupName $rgName 
        ).ServerName | 
        Out-GridView `
            -Title "Select a VM ..." `
            -PassThru

# Reconfigure Azure SQL Server connection policy type 

    $sqlConnectionPolicyId = "/subscriptions/${subscriptionId}/resourceGroups/${rgName}/providers/Microsoft.Sql/servers/${sqlSrvName}/connectionPolicies/Default"

    $apiVersion = "2014-04-01-preview"

    $sqlCurrentConnectionPolicyType = 
        (Get-AzureRmResource `
            -ResourceId $sqlConnectionPolicyId `
            -ApiVersion $apiVersion 
        ).Properties.connectionType

    Write-Output "Current SQL Connection Policy Type = ${sqlCurrentConnectionPolicyType}"

    $sqlNewConnectionPolicyType = "Proxy" # Valid values are "Default", "Proxy" and "Redirect"

    Write-Output "New SQL Connection Policy Type = ${sqlNewConnectionPolicyType}"

    Set-AzureRmResource -ResourceId $sqlConnectionPolicyId -ApiVersion $apiVersion -Properties @{"connectionType" = "${sqlNewConnectionPolicyType}"}
    