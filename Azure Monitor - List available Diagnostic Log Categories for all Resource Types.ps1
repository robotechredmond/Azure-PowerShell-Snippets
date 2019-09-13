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

# PowerShell Snippet for calling Azure Provider REST API to list diagnostic log categories for all supported resource types for all resource providers

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Connect-AzAccount 

# Get list of all Azure resource providers

    $providerNames = 
        (Get-AzResourceProvider).ProviderNamespace

# Get token and create authorization header

    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Authorization'='Bearer ' + $token.AccessToken
    }

# Set other REST API parameters

    $action = "GET"
    $contentType = "application/json"
    $uriPrefix = "https://management.azure.com/providers/"
    $uriSuffix = "/operations?api-version="

# Enumerate diagnostic log categories for supported resource types for all resource providers

    $providerNames | ForEach-Object {

        $providerName = $_

        $apiVersions = @()

        $apiVersions += 
           ((Get-AzResourceProvider -ProviderNamespace $providerName).ResourceTypes |
                Where-Object ResourceTypeName -eq "operations").ApiVersions

        $apiVersion = $apiVersions[0]

        if ($apiVersion -ne $null) {
                
           $uri = $uriPrefix + $providerName + $uriSuffix + $apiVersion

           $results = $null

           try {

                $results = 
                    Invoke-RestMethod `
                        -ContentType $contentType `
                        -Uri $uri `
                        -Method $action `
                        -Headers $authHeader 

            } catch [System.Net.WebException] { 

                if ( 
            
                    ($error[0].ErrorDetails.Message | ConvertFrom-Json).Error.Code `
                    -notin 
                    @("AuthorizationFailed","ResourceNotSupported") 

                ) 
                {
                
                    Write-Error $error[0].ErrorDetails.Message

                }

            }

            $results.value |
                Where-Object name -Like "*/logDefinitions/*" |
                Select-Object `
                    @{n='resourceType';e={%{ ($_.name.split("/") | ? {$_ -notIn @("providers", "Microsoft.Insights", "logDefinitions", "read") }) -join "/" }}},
                    @{n='logCategoryNames';e={$_.properties.serviceSpecification.logSpecifications.name}} 

        }

    } | ConvertTo-Json

    