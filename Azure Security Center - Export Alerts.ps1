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

# PowerShell Snippet for exporting list of Azure Security Center alerts

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    Connect-AzAccount 

# Select Azure subscriptions to include in alert export scope

    $subscriptionIds = 
        (Get-AzSubscription |
         Out-GridView `
            -Title "Select Azure subscriptions to include in alert export scope ..." `
            -PassThru).SubscriptionId

# Enter filename for export

    $reportDate = Get-Date -Format yyyyMMdd
    $defaultExportFile = ".\export_alerts_${reportDate}.csv"
    $exportFile = Read-Host -Prompt "Export Filename (default=${defaultExportFile})"

    if (!$exportFile) {
        $exportFile = $defaultExportFile
    }

# Export list of Security Center alerts

    $subscriptionIds | % {

    Select-AzSubscription -Subscription $_ 
    Get-AzSecurityAlert | 
    Select-Object `
        -Property SubscriptionId, `
                  AlertName, `
                  AlertDisplayName, `
                  ReportedSeverity, `
                  @{n='ResourceType';e={$_.ExtendedProperties.resourceType}} | 
    ConvertTo-Csv -NoTypeInformation | 
    Out-File -Append -FilePath $exportFile

    }
