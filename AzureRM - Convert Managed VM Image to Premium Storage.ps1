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

# Sign-in with Azure AD account

    $Error.Clear()

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

# Select Azure Resource Group in which existing VM is provisioned

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select Azure Resource Group in which VM is provisioned ..." `
              -PassThru
        ).ResourceGroupName

# Select Managed VM Image to convert to Premium storage disks

    $imageName = 
        ( Get-AzureRmImage `
            -ResourceGroupName $rgName 
        ).Name | 
        Out-GridView `
            -Title "Select an existing Image to convert ..." `
            -PassThru

    $image = 
        Get-AzureRmImage `
            -ResourceGroupName $rgName `
            -Name $imageName

    $location = 
        $image.Location

# Convert OS disk to default to Premium storage

    $osDisk = $image.StorageProfile.OsDisk
    $osDisk.StorageAccountType = "PremiumLRS"

# Convert Data disks to default to Premium Storage

    $dataDisks = $image.StorageProfile.DataDisks
    for ($i = 0; $i -lt $dataDisks.Count; $i++)
    { 
        $dataDisks[0].StorageAccountType = "PremiumLRS" 
    }

# Enter new name for converted image

    $newImageName = Read-Host -Prompt "Enter new name for converted VM image [Enter = ${imageName}-ssd]"
    if ($newImageName -eq "") { $newImageName = "${imageName}-ssd" }

# Define new config for converted image

    $newImageConfig = New-AzureRmImageConfig -Location $location -OsDisk $osDisk -DataDisk $dataDisks

# Create new image based on converted image config 

    New-AzureRmImage -ResourceGroupName $rgName -ImageName $newImageName -Image $newImageConfig
