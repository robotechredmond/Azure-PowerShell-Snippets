# Login to Azure Account

Login-AzureRmAccount

# Select Azure subscription

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# Select actions to allow in new custom role

$actions = Get-AzureRmProviderOperation `
    -ActionString "*" | 
    Out-GridView `
        -Title "Select Actions to Permit ..." `
        -OutputMode Multiple 

# Prompt for name of new custom role

$roleName = Read-Host `
    -Prompt "Enter name for new role"

# Prompt for description of new custom role

$roleDesc = Read-Host `
    -Prompt "Enter description for new role"

# Define custom role object, based on Reader role

$roleDef = Get-AzureRmRoleDefinition "Reader"

$roleDef.Id = $null

$roleDef.Name = $roleName

$roleDef.Description = $roleDesc

$roleDef.AssignableScopes = @("/subscriptions/$subscriptionId")

ForEach ($action in $actions) {

    $roleDef.Actions.Add("$($action.Operation)")

}

# Create new custom role based on defined role object

New-AzureRmRoleDefinition -Role $roleDef
