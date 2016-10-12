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
#   NIC to a new VNET
#
# - This script expects that the existing VNET, new VNET and VM to be moved 
#   are all located in the same Azure Resource Group
#
# - VMs attached to an Azure Load Balancer will need to be manually 
#   re-attached to a new Azure Load Balancer resource after all VMs in the 
#   Availability Set are moved.
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

# STEP 4 - Select Azure Resource Group in which existing VNET is provisioned

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

# STEP 5 - Select VM to re-provision

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

# STEP 6 - Select VNET to which VM should be moved

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

# STEP 7 - Select Subnet to which VM should be moved

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

# STEP 8 - Get VM NIC properties for primary NIC

    $nicId = 
        $vm.NetworkInterfaceIDs[0]

    $nicName = 
        $nicId.Split("/")[-1]

    $nic = 
        Get-AzureRmNetworkInterface `
            -ResourceGroupName $rgName `
            -Name $nicName

# STEP 9 - Detach VM NIC from Azure Load Balancer, if currently assigned.
#          After all VMs in Availability Set are moved, Azure Load Balancer
#          will need to be reconfigured for moved VMs.

    if ( $nic.IpConfigurations[0].LoadBalancerBackendAddressPools ) {

        $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = $null
    }

    if ( $nic.IpConfigurations[0].LoadBalancerInboundNatRules ) {

        $nic.IpConfigurations[0].LoadBalancerInboundNatRules = $null

    }

# STEP 10 - Set new properties for VM NIC

    $nicIpConfigName = 
        $nic.IpConfigurations[0].Name

    $nicNew = 
        Set-AzureRmNetworkInterfaceIpConfig `
            -NetworkInterface $nic `
            -Name $nicIpConfigName `
            -Subnet $subnet

# STEP 11 - Clean-up VM config to reflect deployment from attached disks

    $vm.StorageProfile.OSDisk.Name = $vmName

    $vm.StorageProfile.OSDisk.CreateOption = "Attach"

    $vm.StorageProfile.DataDisks | 
        ForEach-Object { $_.CreateOption = "Attach" }

    $vm.StorageProfile.ImageReference = $null

    $vm.OSProfile = $null

# STEP 12 - If VM is in an availability set, move to new availabity set

    if ( $vm.AvailabilitySetReference ) {

        $asName = $vm.AvailabilitySetReference.Id.Split("/")[-1]

        # Define new Availability Set name for VMs in new VNET
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

        $asRef = New-Object Microsoft.Azure.Management.Compute.Models.SubResource

        $asRef.id = $as.id

        $vm.AvailabilitySetReference = $asRef

    }

# STEP 13 - Re-provision VM with new configuration settings

    If ( !$Error ) {

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

    }
    

