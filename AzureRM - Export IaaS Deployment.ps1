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
# Note: Requires minimum of "Reader" RBAC permissions to resource group and resources being exported

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

# Select Azure Resource Group from which to export VM configurations

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Enter filename for export

    $reportDate = Get-Date -Format yyyyMMdd
    $defaultExportFile = ".\export_${subscriptionId}_${rgName}_${reportDate}.csv"
    $exportFile = Read-Host -Prompt "Export Filename (default=${defaultExportFile})"

    if (!$exportFile) {
        $exportFile = $defaultExportFile
    }

# Export VM deployment configuration

    Write-Output "rgName,vmName,vmLocation,vmSize,asName,vmFd,vmUd,vmZone,vmAgentVersion,numDataDisks,vmStorageAccountName,vmStorageAccountHost,vmVnet,vmSubnet,vmNicPrivateIp,vmNicPrivateIpAlloc,vmNicNsgName,vmNicPublicIp,vmNicPublicIpAlloc" >$exportFile

    [array]$vms = Get-AzureRmVM -ResourceGroupName $rgName -ErrorAction Stop

    $vmCount = $vms.Count
    $vmCurrent = 0

    $vms | % { 

        $vmCurrent++
        $vmRgName = $_.ResourceGroupName
        $vmName = $_.Name

        Write-Progress -Activity "Export VM configurations ..." -CurrentOperation "$vmName ..." -PercentComplete ($vmCurrent/$vmCount*100) -SecondsRemaining -1

        $vmLocation = $_.Location
        $vmSize = $_.HardwareProfile.VmSize
        $asName = $null

        if ($_.AvailabilitySetReference.Id) {
            $asName = (Get-AzureRmResource -ResourceId $_.AvailabilitySetReference.Id).Name
        }

        $vmZone = $_.Zones

        $vmStatus = Get-AzureRmVM -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Status
        $vmFd = $vmStatus.PlatformFaultDomain
        $vmUd = $vmStatus.PlatformUpdateDomain
        $vmAgentVersion = $vmStatus.VMAgent.VmAgentVersion
        $vmNic = Get-AzureRmResource -ResourceId $_.NetworkProfile.NetworkInterfaces[0].Id
        $vmNicIpCfg = (Get-AzureRmResource -ResourceId $vmNic.Properties.IpConfigurations[0].Id -ApiVersion '2016-09-01')
        $vmVnet = $vmNicIpCfg.Properties.Subnet.Id.Split('/')[8]
        $vmSubnet = $vmNicIpCfg.Properties.Subnet.Id.Split('/')[10]
        $vmNicPrivateIp = $vmNicIpCfg.Properties.PrivateIPAddress
        $vmNicPrivateIpAlloc = $vmNicIpCfg.Properties.PrivateIPAllocationMethod
        $vmNicPublicIp = $null
        $vmNicPublicIpAlloc = $null
    
        if ($vmNicIpCfg.Properties.PublicIpAddress) {
            $vmNicPublicIpCfg = Get-AzureRmResource -ResourceId $vmNicIpCfg.Properties.PublicIPAddress.Id
            $vmNicPublicIp = $vmNicPublicIpCfg.Properties.IpAddress
            $vmNicPublicIpAlloc = $vmNicPublicIpCfg.Properties.PublicIpAllocationMethod
        }

        $vmNicNsgName = $null

        if ($vmNic.Properties.NetworkSecurityGroup) {
            $vmNicNsgName = (Get-AzureRmResource -ResourceId $vmNic.Properties.NetworkSecurityGroup.Id).Name
        }

        $vmStorageAccountName = $null
        $vmStorageAccountHost = $null
        $vmStorageAccountFqdn = $null

        if ($_.StorageProfile.OSDisk.Vhd.Uri) {
            $vmStorageAccountName = $_.StorageProfile.OSDisk.Vhd.Uri.Split('/.')[2]
            $vmStorageAccountFqdn = $_.StorageProfile.OSDisk.Vhd.Uri.Split('/')[2]
            $vmStorageAccountHost = (Resolve-DnsName $vmStorageAccountFqdn).NameHost.Split('.')[1]
        }

        $numDataDisks = $_.DataDiskNames.Count

        Write-Output "$vmRgName,$vmName,$vmLocation,$vmSize,$asName,$vmFd,$vmUd,$vmZone,$vmAgentVersion,$numDataDisks,$vmStorageAccountName,$vmStorageAccountHost,$vmVnet,$vmSubnet,$vmNicPrivateIp,$vmNicPrivateIpAlloc,$vmNicNsgName,$vmNicPublicIp,$vmNicPublicIpAlloc" -ErrorAction Stop >>$exportFile
    
    }
