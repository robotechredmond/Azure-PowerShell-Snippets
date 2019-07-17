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

# Enable and configure Azure Security Center 

# Install Security Center PowerShell module

    Set-ExecutionPolicy `
        -Scope CurrentUser `
        -ExecutionPolicy AllSigned `
        -Force
    
    Set-ExecutionPolicy `
        -Scope LocalMachine `
        -ExecutionPolicy AllSigned `
        -Force

    Install-Module `
        -Name Az.Security `
        -Force

    Import-Module `
        -Name Az.Security

# Authenticate to Azure AD as Service Principal with "Security Admin" RBAC role assigned
    
    $tenantId = 
        Read-Host -Prompt "AAD Tenant ID"

    $cred = 
        Get-Credential -Message "Service Principal Credentials"

    Login-AzAccount `
        -Tenant $tenantId `
        -ServicePrincipal `
        -Credential $cred

# Select Azure subscription

    $subscriptionId = 
        (Get-AzSubscription |
         Out-GridView `
            -Title "Select Azure subscription ..." `
            -PassThru).SubscriptionId

    Set-AzContext `
        -Subscription $subscriptionId

# Register Security Center Resource Provider

    Register-AzResourceProvider `
        -ProviderNamespace 'Microsoft.Security' 

# Set Log Analytics Workspace for Security Center (Workspace must already exist)

    $workspaceId = 
        Read-Host -Prompt "Log Analytics Workspace ID"

    Set-AzSecurityWorkspaceSetting `
        -Name "default" `
        -Scope "/subscriptions/${subscriptionId}" `
        -WorkspaceId $workspaceId

# Set Security Center Pricing Tier

    $pricing = "Standard"

    Set-AzSecurityPricing `
        -Name "VirtualMachines" `
        -PricingTier $pricing

    Set-AzSecurityPricing `
        -Name "SqlServers" `
        -PricingTier $pricing

    Set-AzSecurityPricing `
        -Name "AppServices" `
        -PricingTier $pricing

    Set-AzSecurityPricing `
        -Name "StorageAccounts" `
        -PricingTier $pricing

# Confirm Pricing Tier

    Get-AzSecurityPricing | 
        Select-Object `
            -Property Name, PricingTier

# Enable Security Center Auto-Provisioning

    Set-AzSecurityAutoProvisioningSetting `
        -Name "default" `
        -EnableAutoProvision

# Confirm Security Center Auto-Provisioning setting

    Get-AzSecurityAutoProvisioningSetting |
        Select-Object `
            -Property Name, AutoProvision
