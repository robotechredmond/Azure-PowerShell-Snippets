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

# SCRIPT: Sample provisioning flow to create Azure user-assigned managed identity
#         and assign Azure AD API App Role permissions

# PREREQ: Install required PowerShell Modules (requires latest version of PowerShellGet)

    Install-Module `
        -Name Az.ManagedServiceIdentity `
        -AllowPrerelease

# FUNCTION: Main code block

function Main
{

    # Authenticate to Azure Resource Manager as Subscription Owner or Contributor

        Connect-AzAccount

    # Select Azure Subscription in which to create Managed Identity

        $subscriptionId = 
            ( Get-AzSubscription |
                Out-GridView `
                  -Title "Select an Azure Subscription ..." `
                  -PassThru
            ).SubscriptionId

        Select-AzSubscription `
            -SubscriptionId $subscriptionId

    # Select Azure Resource Group in which to create Managed Identity

        $rgName =
            ( Get-AzResourceGroup |
                Out-GridView `
                  -Title "Select an Azure Resource Group ..." `
                  -PassThru
            ).ResourceGroupName

    # Create user-assigned Managed Identity

        $identityName = 
            Read-Host `
                -Prompt "Name of user-assigned managed identity to be created"

        $identity = 
            New-AzUserAssignedIdentity `
                -ResourceGroupName $rgName `
                -Name $identityName

    # Authenticate to Azure AD with Global Admin or App Admin role permissions

        Connect-AzureAD

    # Get ServicePrincipal for API 

        $apiSpn = 
            Get-AzureAdServicePrincipal |
                Where-Object {$_.AppRoles.Length -gt 0} |
                Out-GridView `
                    -Title "Select an API" `
                    -PassThru

    # Get API Application Role Permission

        $apiAppPerm = 
            $apiSpn.AppRoles | 
                Where-Object AllowedMemberTypes -contains "Application" |
                Out-GridView `
                    -Title "Select an Application Permission to assign" `
                    -PassThru

    # Grant API Application Role Permission to Managed Identity

        $roleAssignment = 
            New-AzureADManagedIdentityAppRoleAssignment `
                -identityPrincipalId $identity.PrincipalId `
                -apiSpnObjectId $apiSpn.ObjectId `
                -apiAppRolePermId $apiAppPerm.Id

        Write-Output $roleAssignment
}

# FUNCTION: Assign API App Role Permissions to Managed Identity

function New-AzureADManagedIdentityAppRoleAssignment ($identityPrincipalId, $apiSpnObjectId, $apiAppRolePermId)
{
    try 
    {
        New-AzureADServiceAppRoleAssignment `
            -ObjectId $identityPrincipalId `
            -PrincipalId $identityPrincipalId `
            -ResourceId $apiSpnObjectId `
            -Id $apiAppRolePermId 
    }
    catch 
    {
        # Error is expected from current API, so catch and ignore it. Operation will still succeed.
    }

    Get-AzureADServiceAppRoleAssignment `
        -ObjectId $apiSpnObjectId | 
        Where-Object { 
            $_.Id -eq $apiAppRolePermId `
            -and `
            $_.PrincipalId -eq $identityPrincipalId
        }

}

# Entry point

Main
