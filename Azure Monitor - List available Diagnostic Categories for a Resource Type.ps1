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

# PowerShell Snippet for calling Azure Monitor REST API to list diagnostic settings categories for resource types provisioned in a subscription

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Connect-AzAccount 

# Select Azure Subscription - can automate with specific Azure subscriptionId

    $subscriptionId = 
        (Get-AzSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

# Select Azure resource types for which to determine available Log Categories

    $resourceTypes = 
        Get-AzResource | Sort-Object -Property ResourceType -Unique

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

# Determine available Diagnostic Settings categories for the selected resource type

    $resourceTypes | ForEach-Object {

        $uri = $uriPrefix + $_.ResourceId + $uriSuffix

        $resourceType = $_.ResourceType

        $results = $null

        try {

            $results = 
                Invoke-RestMethod `
                    -ContentType $contentType `
                    -Uri $uri `
                    -Method $action `
                    -Headers $authHeader 

        } catch { 

            if ( 
            
                ($error[0].ErrorDetails.Message | ConvertFrom-Json).Code `
                -notin 
                @("InvalidResourceType","ResourceNotSupported") 

            ) 
            {
                
                Write-Error $error[0].ErrorDetails.Message

            }

        }

        $results.value | 
            Select-Object `
                @{n='resourceType';e={$resourceType}},
                name, 
                properties | 
            Format-Table

    }
