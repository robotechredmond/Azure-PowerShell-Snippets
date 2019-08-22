#-------------------------------------------------------------------------
# Copyright (c) Microsoft.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#--------------------------------------------------------------------------

# Install required PowerShell Modules (requires latest version of PowerShellGet)

    Install-Module `
        -Name Az.ManagedServiceIdentity `
        -AllowPrerelease

# Authenticate to Azure Resource Manager as Subscription Owner or Contributor

    Connect-AzAccount

# Select Azure Subscription

    $subscriptionId = 
        ( Get-AzSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Select-AzSubscription `
        -SubscriptionId $subscriptionId

# Select Azure Resource Group from which to export VM configurations

    $rgName =
        ( Get-AzResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Create user-assigned managed identity

    $identityName = 
        Read-Host `
            -Prompt "Name of user-assigned managed identity to be created"

    $identity = 
        New-AzUserAssignedIdentity `
            -ResourceGroupName $rgName `
            -Name $identityName

# Authenticate to Azure AD with Global Admin or App Admin permissions

    Connect-AzureAD

# Get ServicePrincipal for API

    $apiSpn = 
        Get-AzureAdServicePrincipal |
            Where-Object {$_.AppRoles.Length -gt 0} |
            Out-GridView `
                -Title "Select an API" `
                -PassThru

# Get API Application Permission

    $apiAppPerm = 
        $apiSpn.AppRoles | 
            Where-Object AllowedMemberTypes -contains "Application" |
            Out-GridView `
                -Title "Select an Application Permission to assign" `
                -PassThru

# Grant API Application Permission to Managed Identity

    try 
    {
        New-AzureADServiceAppRoleAssignment `
            -ObjectId $identity.PrincipalId `
            -PrincipalId $identity.PrincipalId `
            -ResourceId $ApiSpn.ObjectId `
            -Id $apiAppPerm.Id 
    }
    catch 
    {}

# Validate that Managed Identity has been assigned permission

    $identityAppRole = 
        Get-AzureADServiceAppRoleAssignment `
            -ObjectId $apiSpn.ObjectId | 
        Where-Object { 
            $_.Id -eq $apiAppPerm.Id `
            -and `
            $_.PrincipalId -eq $identity.PrincipalId 
        }

    if ($identityAppRole.PrincipalId -eq $identity.PrincipalId)
    {
        Write-Output "SUCCESS: Application Permission $($apiAppPerm.Value) assigned to $($identityName) successfully"
    }
    else
    {
        Write-Output "ERROR: Error assigning application permission $($apiAppPerm.Value) to $($identityName)"
    }