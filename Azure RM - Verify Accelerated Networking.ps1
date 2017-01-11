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

# Sample script for confirming Accelerated Networking for NICs in a selected Resource Group

# Authenticate to Azure - can automate with Azure AD Service Principal credentials

    $azureContext = Login-AzureRmAccount

# Select Azure Subscription - can automate with specific Azure subscriptionId

    $subscriptionId = 
        (Get-AzureRmSubscription |
         Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru).SubscriptionId

    $subscription = Select-AzureRmSubscription -SubscriptionId $subscriptionId

# Select Azure Resource Group to report on

    $rgName =
        (Get-AzureRmResourceGroup |
         Out-GridView `
            -Title "Select an Azure Resource Group ..." `
            -PassThru).ResourceGroupName

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

    $adal = "${env:ProgramFiles}\WindowsPowerShell\Modules\AzureRM.Resources\3.3.0\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

    $adalforms = "${env:ProgramFiles}\WindowsPowerShell\Modules\AzureRM.Resources\3.3.0\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"

    Add-Type -Path $adal

    Add-Type -Path $adalforms

# Create Authentication Context tied to Azure AD Tenant

    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority

# Acquire token

    $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")

# Create Authorization Header

    $authHeader = $authResult.CreateAuthorizationHeader()

# Set REST API parameters

    $contentType = "application/json;charset=utf-8"

    $apiVersion = "2016-09-01"

    $resourceType = "Microsoft.Network/networkInterfaces"

    $requestHeader = @{"Authorization" = $authHeader}

# Call REST API to determine properties for each deployed NIC in selected Resource Group

    Get-AzureRmResource -ResourceGroupName $rgName -ResourceType $resourceType |

        ForEach-Object {

            $resourceName = $_.Name

            $uri = "https://management.azure.com/subscriptions/${subscriptionId}/resourceGroups/${rgName}/providers/${resourceType}/${resourceName}?api-version=${apiVersion}"

            $response = Invoke-RestMethod `
                -Uri $Uri `
                -Method Get `
                -Headers $requestHeader `
                -ContentType $contentType

            Write-Output "NIC: $($response.name); Accelerated Networking Enabled: $($response.properties.enableAcceleratedNetworking)"

        }

# Download Network Tools
New-Item -Path C:\WindowsAzure\Network -ItemType Directory
Invoke-WebRequest -Uri 'https://gallery.technet.microsoft.com/NTttcp-Version-528-Now-f8b12769/file/159655/1/NTttcp-v5.33.zip' -OutFile 'C:\WindowsAzure\Network\NTttcp-v5.33.zip'
# Invoke-WebRequest -Uri 'https://gallery.technet.microsoft.com/Azure-Accelerated-471b5d84/file/160835/1/MLNX_VPI_WinOF-5_20_All_Win2012R2_and_2016_x64.exe' -OutFile 'C:\WindowsAzure\Network\MLNX_VPI_WinOF-5_20_All_Win2012R2_and_2016_x64.exe'

# Download Storage tools
New-Item -Path C:\WindowsAzure\Storage -ItemType Directory
Invoke-WebRequest -Uri 'https://osdn.net/frs/redir.php?m=pumath&f=%2Fcrystaldiskmark%2F66553%2FCrystalDiskMark5_2_1.exe' -OutFile 'C:\WindowsAzure\Storage\CrystalDiskMark5_2_1.exe'

# Install Network Driver - not needed for Windows Server 2016 RTM
# $setupProc = Start-Process -FilePath 'C:\WindowsAzure\Network\MLNX_VPI_WinOF-5_20_All_Win2012R2_and_2016_x64.exe' -Wait -ArgumentList '/S /v"/qn REBOOT=Force"'

# Start network receiver on VM 1
ntttcp -r –m 32,*,10.0.0.4 -t 300

# Start network sender on VM 2
ntttcp -s –m 32,*,10.0.0.4 -t 300
