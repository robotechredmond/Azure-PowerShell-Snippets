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

# Sign-in with Azure account credentials

    Login-AzureRmAccount

# Select Azure Subscription

    $subscriptionId = 
        (Get-AzureRmSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId    

 # Pull Activity Log History

    $auditLog = $null

    $currentTime = Get-Date

    $endTime = $currentTime

    $startTime = $endTime.AddDays(-15)

    do {

        $auditLog += Get-AzureRmLog -StartTime $startTime -EndTime $endTime -DetailedOutput

        $endTime = $endTime.AddDays(-15)

        $startTime = $startTime.AddDays(-15)

    }

    until ( $startTime -lt $currentTime.AddDays(-90) )

# Filter Activity Log for "Created" events

    $auditLog | 
        ? Caller -like "*@*" | 
        ? ResourceGroupName -notlike "" | 
        ? { $_.Properties.Content.Value -Contains "Created" } |
        Sort-Object -Property ResourceGroupName, ResourceId | 
        Select-Object -Property ResourceGroupName, Caller, ResourceId -Unique | 
        Format-Table -Wrap

