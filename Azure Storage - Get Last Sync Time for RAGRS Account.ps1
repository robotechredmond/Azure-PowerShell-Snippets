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

# PowerShell Snippet for calling Storage REST API to determine Last Sync Time for RA-GRS Storage Account

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Login-AzureRmAccount

# Select Azure Subscription - can automate with specific Azure subscriptionId

    $subscriptionId = 
        (Get-AzureRmSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# Select Azure Resource Group

    $rgName =
        (Get-AzureRmResourceGroup |
         Out-GridView `
            -Title "Select an Azure Resource Group ..." `
            -PassThru).ResourceGroupName

# Select Azure RA-GRS Storage Account

    $saName =
        (Get-AzureRmStorageAccount `
            -ResourceGroupName $rgName |
        Where-Object SecondaryEndpoints -ne $null |
        Out-GridView `
            -Title "Select an Azure Storage Account ..." `
            -PassThru).StorageAccountName

# Get Secondary Endpoint for Blob Service on RA-GRS Storage Account

    $saEndpoint =
        (Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName).SecondaryEndpoints.Blob

# Get Primary Access Key for RA-GRS Storage account

    $saKey = 
        (Get-AzureRmStorageAccountKey -ResourceGroupName $rgName -Name $saName).Value[0]

# Set REST API parameters

    $apiVersion = "2015-02-21"

    $requestDate = Get-Date
    $requestDate = $requestDate.ToUniversalTime()
    $requestDate = $requestDate.ToString('R')

    $contentType="application/xml"

    $action = "GET"

    $newLine = "`n";
    $message = $action + $newLine + $newLine + $contentType+ $newLine + $newLine + "x-ms-date:" + $requestDate + $newLine + "x-ms-version:" + $apiVersion + $newLine + "/" + $saName + "/?comp=stats"

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Convert]::FromBase64String($saKey)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::UTF8.GetBytes($message))
    $signature = [Convert]::ToBase64String($signature)

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"

    $headers.Add("x-ms-date", $requestDate)
    $headers.Add("x-ms-version", "$apiVersion")
    $headers.Add("Authorization", "SharedKeyLite " + $saName + ":" + $signature)

# Set initial URI for calling Storage REST API

    $uri = $saEndPoint + "?comp=stats&restype=service"

# Call Storage REST API

    $saResponse = 
        Invoke-RestMethod `
            -ContentType $contentType `
            -Uri $Uri `
            -Method Get `
            -Headers $headers

    [xml]$saResponseXml = $saResponse.Substring(3)

# Display Last Sync Time

    $saResponseXml.StorageServiceStats.GeoReplication.LastSyncTime

