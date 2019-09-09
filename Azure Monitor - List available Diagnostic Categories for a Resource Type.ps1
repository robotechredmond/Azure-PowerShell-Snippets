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

# PowerShell Snippet for calling Azure Monitor REST API to list diagnostic settings categories for a resource type

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Connect-AzAccount 

# Select Azure Subscription - can automate with specific Azure subscriptionId

    $subscriptionId = 
        (Get-AzSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

# Select Azure Resource for which to determine available Log Categories

    $resourceId = 
        (Get-AzResource | 
         Sort-Object -Property ResourceType, ResourceName |
         Out-GridView `
            -Title "Select an Azure Resource ..." `
            -PassThru).ResourceId

# Get token and create authorization header

    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Authorization'='Bearer ' + $token.AccessToken
    }

# Set other REST API parameters

    $apiVersion = 
        ((Get-AzResourceProvider -ProviderNamespace Microsoft.Insights).ResourceTypes | 
        Where-Object ResourceTypeName -eq "diagnosticSettings").ApiVersions[0]
    $action = "GET"
    $contentType = "application/json"
    $uriPrefix = "https://management.azure.com"
    $uriSuffix = "/providers/microsoft.insights/diagnosticSettingsCategories?api-version=${apiVersion}"
    $uri = $uriPrefix + $resourceId + $uriSuffix

# Determine available Diagnostic Settings categories for the selected resource

    $results = 
        Invoke-RestMethod `
            -ContentType $contentType `
            -Uri $uri `
            -Method $action `
            -Headers $authHeader

    $results.value | 
        Select-Object name, properties