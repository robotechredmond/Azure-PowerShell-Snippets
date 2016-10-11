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

# PowerShell Snippet for calling Azure Resource Health REST API

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Login-AzureRmAccount

# Select Azure Subscription - can automate with specific Azure subscriptionId

    $subscriptionId = 
        (Get-AzureRmSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

# Set Azure AD Tenant for selected Azure Subscription

    $adTenant = 
        (Get-AzureRmSubscription `
            -SubscriptionId $subscriptionId).TenantId

# Set parameter values for Azure AD auth to REST API

    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2" # Well-known client ID for Azure PowerShell

    $redirectUri = "urn:ietf:wg:oauth:2.0:oob" # Redirect URI for Azure PowerShell

    $resourceAppIdURI = "https://management.core.windows.net/" # Resource URI for REST API

    $authority = "https://login.windows.net/$adTenant" # Azure AD Tenant Authority

# Load ADAL Assemblies

    $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

    $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    Add-Type -Path $adal

    Add-Type -Path $adalforms

# Create Authentication Context tied to Azure AD Tenant

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

# Acquire token

    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

# Create Authorization Header

    $authHeader = $authResult.CreateAuthorizationHeader()

# Set REST API parameters

    $apiVersion = "2015-01-01"

    $contentType = "application/json;charset=utf-8"

# Set HTTP request headers to include Authorization header

    $requestHeader = @{"Authorization" = $authHeader}

# Set initial URI for calling Resource Health REST API

    $uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=$apiVersion"

# Call Resource Health REST API

    $healthData = Invoke-RestMethod `
        -Uri $Uri `
        -Method Get `
        -Headers $requestHeader `
        -ContentType $contentType

# Display Health Data for Azure resources in selected subscription

    $healthData.value | 
        Select-Object `
           @{n='subscriptionId';e={$_.id.Split("/")[2]}},
           location,
           @{n='resourceGroup';e={$_.id.Split("/")[4]}},
           @{n='resource';e={$_.id.Split("/")[8]}},
           @{n='status';e={$_.properties.availabilityState}}, # ie., Available or Unavailable
           @{n='summary';e={$_.properties.summary}},
           @{n='reason';e={$_.properties.reasonType}},
           @{n='occuredTime';e={$_.properties.occuredTime}},
           @{n='reportedTime';e={$_.properties.reportedTime}} |
        Format-List
