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

$cred = Get-Credential

New-AzureRmSqlServer -ResourceGroupName $rgName -ServerName "sqldwsrv01" -Location "southeastasia" -ServerVersion "12.0" -SqlAdministratorCredentials $cred -Debug

New-AzureRmSqlDatabase -ResourceGroupName $rgName -RequestedServiceObjectiveName "DW400" -DatabaseName "sqldwdb01" -ServerName "sqldwsrv01"  -Edition "DataWarehouse" -CollationName "SQL_Latin1_General_CP1_CI_AS" -MaxSizeBytes 10995116277760 -Debug

New-AzureRmSqlServerFirewallRule -ResourceGroupName $rgName -ServerName "sqldwsrv01" -AllowAllAzureIPs -Debug