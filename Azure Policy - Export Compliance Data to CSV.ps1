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

# PowerShell Snippet for calling Azure Policy Compliance REST API to export policy compliance status

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Login-AzAccount 

# Select Azure subscriptions to include in compliance reporting scope

    $subscriptionIds = 
        (Get-AzSubscription |
         Out-GridView `
            -Title "Select Azure subscriptions to include in compliance reporting scope ..." `
            -PassThru).SubscriptionId

# Enter filename for export

    $reportDate = Get-Date -Format yyyyMMdd
    $defaultExportFile = ".\export_policy_${reportDate}.csv"
    $exportFile = Read-Host -Prompt "Export Filename (default=${defaultExportFile})"

    if (!$exportFile) {
        $exportFile = $defaultExportFile
    }

# Get token and create authorization header

    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
        'Authorization'='Bearer ' + $token.AccessToken
    }

# Set other REST API parameters

    $apiVersion = "2018-04-04"
    $action = "POST"
    $contentType = "application/json"
    $uriPrefix = "https://management.azure.com/subscriptions/"
    $uriSuffix = "/providers/Microsoft.PolicyInsights/policyStates/latest/summarize?api-version=${apiVersion}"

# Export non-compliant policy results

    $subscriptionIds | % {

        $uri = $uriPrefix + $_ + $uriSuffix

        $summaryResults = 
            Invoke-RestMethod `
                -ContentType $contentType `
                -Uri $uri `
                -Method $action `
                -Headers $authHeader

        $nonCompliantResults =
            Invoke-RestMethod `
                -ContentType $contentType `
                -Uri $summaryResults.value.results.queryResultsUri `
                -Method $action `
                -Headers $authHeader

        $nonCompliantResults.value | ConvertTo-Csv -NoTypeInformation | Out-File -Append -FilePath $exportFile

    }
