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

# LIMITATIONS:
# - This script is intended to move an Azure VM with ONLY a single attached NIC to a new VNET
# - This script does not currently support moving VMs that are assigned to an Azure load balancer

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
        -ProviderNamespace Microsoft.Compute

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Storage

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Network

    Get-AzureRmResourceProvider | 
        Select-Object `
        -Property ProviderNamespace `
        -ExpandProperty ResourceTypes

# Select Azure Resource Group in which existing VNET is provisioned

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# Select VM to re-provision

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

# Select VNET to which VM should be moved

    $vnetName = 
        ( Get-AzureRmVirtualNetwork `
            -ResourceGroupName $rgName 
        ).Name | 
        Out-GridView `
            -Title "Select a VNET to which VM should be moved ..." `
            -PassThru

    $vnet = 
        Get-AzureRmVirtualNetwork `
            -ResourceGroupName $rgName `
            -Name $vnetName

# Select Subnet to which VM should be moved

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

# Reconfigure NIC properties for new Subnet
# Note that this script only works for VMs with a single NIC attached

    $nicId = 
        $vm.NetworkInterfaceIDs[0]

    $nicName = 
        $nicId.Split("/")[-1]

    $nic = 
        Get-AzureRmNetworkInterface `
            -ResourceGroupName $rgName `
            -Name $nicName

    $nicIpConfigName = 
        $nic.IpConfigurations[0].Name

    $nicNew = 
        Set-AzureRmNetworkInterfaceIpConfiguration `
            -NetworkInterface $nic `
            -Name $nicIpConfigName `
            -Subnet $subnet

# Clean-up VM config to reflect deployment from attached disks

    $vm.StorageProfile.OSDisk.Name = $vmName

    $vm.StorageProfile.OSDisk.CreateOption = "Attach"

    $vm.StorageProfile.DataDisks | 
        ForEach-Object { $_.CreateOption = "Attach" }

    $vm.StorageProfile.ImageReference = $null

    $vm.OSProfile = $null

# If VM is in an availability set, move to new availabity set

    if ( $vm.AvailabilitySetReference ) {

        $asName = $vm.AvailabilitySetReference.ReferenceUri.Split("/")[-1]

        # Define new Availability Set name for VMs in new VNET - may wish to change naming convention used below to reflect your deployment
        $asNewName = "${asName}-${vnetName}"

        New-AzureRmAvailabilitySet `
            -ResourceGroupName $rgName `
            -Name $asNewName `
            -Location $location `
            -ErrorAction SilentlyContinue

        $as = 
            Get-AzureRmAvailabilitySet `
                -ResourceGroupName $rgName `
                -Name $asNewName

        $asRef = New-Object Microsoft.Azure.Management.Compute.Models.AvailabilitySetReference

        $asRef.ReferenceUri = $as.id

        $vm.AvailabilitySetReference = $asRef

    }

# Re-provision VM with new configuration settings

    $yn = @("Yes","No") | 
        Out-GridView `
            -Title "OK to reconfigure existing VM ${vmName}?" `
            -PassThru

    if ( $yn -eq "Yes" ) {

        # Stop and de-allocate existing VM
        
            Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName

        # Remove existing VM, but preserve virtual hard disks

            Remove-AzureRmVM -ResourceGroupName $rgName -Name $vmName

        # Reconfigure existing Network Interface for new Subnet

            Set-AzureRmNetworkInterface -NetworkInterface $nicNew

        # Re-provision VM from attached disks

            $vm | 
                New-AzureRmVm `
                    -ResourceGroupName $rgName `
                    -Location $location

    }
