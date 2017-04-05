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

# Sign-in to Azure via Azure Resource Manager

    Login-AzureRmAccount

# Select Azure Subscription

    $subscriptionId = 
        ( Get-AzureRmSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# If needed, register ARM core resource providers

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Sql

    Get-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Sql | 
            Select-Object `
            -Property ProviderNamespace `
            -ExpandProperty ResourceTypes

# Select Azure Resource Group in which existing Azure SQL Server resource is provisioned

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select existing Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Select Azure SQL Server resource to reconfigure

    $sqlSrvName = 
        ( Get-AzureRmSqlServer `
            -ResourceGroupName $rgName 
        ).ServerName | 
        Out-GridView `
            -Title "Select an Azure SQL Server instance ..." `
            -PassThru

# Reconfigure Azure SQL Server connection policy type 

    $sqlConnectionPolicyId = "/subscriptions/${subscriptionId}/resourceGroups/${rgName}/providers/Microsoft.Sql/servers/${sqlSrvName}/connectionPolicies/Default"

    $apiVersion = "2014-04-01-preview"

    $sqlCurrentConnectionPolicyType = 
        (Get-AzureRmResource `
            -ResourceId $sqlConnectionPolicyId `
            -ApiVersion $apiVersion 
        ).Properties.connectionType

    Write-Output "Current SQL Connection Policy Type = ${sqlCurrentConnectionPolicyType}"

    $sqlNewConnectionPolicyType = "Proxy" # Valid values are "Default", "Proxy" and "Redirect"

    Write-Output "New SQL Connection Policy Type = ${sqlNewConnectionPolicyType}"

    Set-AzureRmResource -ResourceId $sqlConnectionPolicyId -ApiVersion $apiVersion -Properties @{"connectionType" = "${sqlNewConnectionPolicyType}"}
    