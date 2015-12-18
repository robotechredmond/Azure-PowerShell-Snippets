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

# Assign Reader to subscription

$roleName = "Reader"

$adGroupName = "Demo Test"

$adGroup = Get-AzureRMADGroup -SearchString $adGroupName

$scope = "/subscriptions/$subscriptionId"

$roleAssignment = New-AzureRmRoleAssignment `
    -ObjectId $adGroup.Id `
    -RoleDefinitionName $roleName `
    -Scope $scope

Get-AzureRmRoleAssignment

# Select Azure Resource Group in which existing VNET is provisioned

$rgName =
    (Get-AzureRmResourceGroup |
     Out-GridView `
        -Title "Select an Azure Resource Group ..." `
        -PassThru).ResourceGroupName

# Select Azure VNET on which to enable a user-defined route

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

# Select Azure Subnet on which to enable a user-defined route

$subnetName = 
    $vnet.Subnets.Name |
    Out-GridView `
        -Title "Select an Azure Subnet ..." `
        -PassThru

$subnet = $vnet.Subnets | 
    Where-Object Name -eq $subnetName

# Assign Virtual Machine Contributor Role to a Subnet

$roleName = "Virtual Machine Contributor"

$adGroupName = "Demo Test"

$adGroup = Get-AzureRMADGroup -SearchString $adGroupName

$roleAssignment = New-AzureRmRoleAssignment `
    -ObjectId $adGroup.Id `
    -RoleDefinitionName $roleName `
    -Scope $subnet.Id

# Display Role Assignments

Get-AzureRmRoleAssignment

# Remove Role Assignments

Remove-AzureRmRoleAssignment `
    -ObjectId $roleAssignment.ObjectId `
    -RoleDefinitionName $roleName `
    -Scope $subnet.Id

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

New-AzureRmRoleDefinition `
    -Role $roleDef

# Remove custom role

$role = Get-AzureRmRoleDefinition `
    -Name $roleName

Remove-AzureRmRoleDefinition `
    -Id $role.Id

# Review Access Change History Report

Get-AzureRmAuthorizationChangeLog `
    -StartTime ([DateTime]::Now - [TimeSpan]::FromDays(7)) |
    Format-Table `
        Caller,
        Action,
        RoleName,
        PrincipalType,
        PrincipalName,
        ScopeType,
        ScopeName
