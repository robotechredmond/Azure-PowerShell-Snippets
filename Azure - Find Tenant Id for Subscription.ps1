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

# PURPOSE: Helper function returns Azure AD Tenant ID for an Azure subscription without 
#          requiring authentication and authorization on subscription

function Get-AzureSubscriptionTenantId ( $subscriptionId )

{

    $uri = "https://management.azure.com/subscriptions/${subscriptionId}?api-version=2015-01-01"

    try 
    {
        $response = Invoke-RestMethod -Method Get -Uri $uri 
    }
    catch 
    {
        $header = $_.Exception.Response.Headers["WWW-Authenticate"]
    }

    $header.Split("/`"")[4]

}

$subId = Read-Host -Prompt "Enter Azure subscription Id"

Get-AzureSubscriptionTenantId -subscriptionId $subId