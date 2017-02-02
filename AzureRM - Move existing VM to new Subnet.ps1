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

# TECHNICAL NOTES:
#
# - This script is intended to move an Azure VM with ONLY a single attached
#   NIC with a single IP configuration to a new subnet in the same VNET
#
# - This script snippet is provided as a sample demo, and as such, robust
#   error handling that is common to a production script is not inclued.
#
# - This script snippet was tested using Azure PowerShell 2.x

# STEP 1 - Sign-in with Azure account

    $Error.Clear()

    Login-AzureRmAccount

# STEP 2 - Select Azure Subscription

    $subscriptionId = 
        ( Get-AzureRmSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Select-AzureRmSubscription `
        -SubscriptionId $subscriptionId

# STEP 3 - If needed, register ARM core resource providers

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Compute

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Storage

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Network

    Get-AzureRmResourceProvider | 
        Select-Object `
        -Property ProviderNamespace `
        -ExpandProperty ResourceTypes

# STEP 4 - Select Azure Resource Group in which existing VM is provisioned

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select Azure Resource Group in which VM is provisioned ..." `
              -PassThru
        ).ResourceGroupName

# STEP 5 - Select VM to move

    $vmName = 
        ( Get-AzureRmVm `
            -ResourceGroupName $rgName 
        ).Name | 
        Out-GridView `
            -Title "Select a VM ..." `
            -PassThru

    $vm = 
        Get-AzureRmVm `
            -ResourceGroupName $rgName `
            -Name $vmName

    $location = 
        $vm.Location
		
# STEP 6 - Select new subnet to which VM should be moved

    $nicId = 
        $vm.NetworkInterfaceIDs[0]

    $nicName = 
        (Get-AzureRmResource -ResourceId $nicId).Name

    $nic = 
        Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName

    $subnetId = 
        $nic.IpConfigurations[0].Subnet.Id

    $vnetName = 
        $subnetId.Split('/')[8]

    $vnetRgName = 
        $subnetId.Split('/')[4]
    
    $vnet = 
        Get-AzureRmVirtualNetwork `
            -ResourceGroupName $vnetRgName `
            -Name $vnetName
			
    $subnetName = 
        ( Get-AzureRmVirtualNetworkSubnetConfig `
            -VirtualNetwork $vnet
        ).Name | 
        Out-GridView `
            -Title "Select a Subnet to which VM should be moved ..." `
            -PassThru

    $subnet =
        Get-AzureRmVirtualNetworkSubnetConfig `
          -VirtualNetwork $vnet `
          -Name $subnetName

# STEP 7 - Move VM to new subnet 

    Stop-AzureRmVM -Name $vmName -ResourceGroupName $rgName -Confirm:$true

    $nic.IpConfigurations[0].Subnet.Id = $subnet.Id

    $origPrivateIpAllocationMethod = 
        $nic.IpConfigurations[0].PrivateIpAllocationMethod

    $nic.IpConfigurations[0].PrivateIpAllocationMethod = 'Dynamic'

    Set-AzureRmNetworkInterface `
        -NetworkInterface $nic

    if ($origPrivateIpAllocationMethod -eq 'Static') {

        $nic = 
            Get-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName

        $nic.IpConfigurations[0].PrivateIpAllocationMethod = 'Static'

        Set-AzureRmNetworkInterface `
            -NetworkInterface $nic
        
    }

    Start-AzureRmVM -Name $vmName -ResourceGroupName $rgName
