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
# - VMs attached to an Azure Load Balancer or Application Gateway will need 
#   to be manually re-attached to a new Azure Load Balancer resource after 
#   all VMs in the Availability Set are moved.
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
		
# STEP 6 - Select Resource Group in which target VNET is provisioned - VM will be moved to this Resource Group as well

    $rgName2 =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group in which target VNET is provisioned ..." `
              -PassThru
        ).ResourceGroupName

# STEP 7 - Select VNET to which VM should be moved

    $vnetName = 
        ( Get-AzureRmVirtualNetwork `
            -ResourceGroupName $rgName2 
        ).Name | 
        Out-GridView `
            -Title "Select a VNET to which VM should be moved ..." `
            -PassThru

    $vnet = 
        Get-AzureRmVirtualNetwork `
            -ResourceGroupName $rgName2 `
            -Name $vnetName
			
# STEP 8 - Select Subnet to which VM should be moved

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

# STEP 9a - Select Resource Group in which vNIC, Public IP and NSG are currently provisioned

    $rgName3 =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group in which the vNIC, Public IP and/or NSG is provisioned ..." `
              -PassThru
        ).ResourceGroupName

# STEP 9 - Get VM NIC properties for primary NIC

    $nicId = 
        $vm.NetworkInterfaceIDs[0]

    $nicName = 
        $nicId.Split("/")[-1]

    $nic = 
        Get-AzureRmNetworkInterface `
            -ResourceGroupName $rgName3 `
            -Name $nicName
  
# STEP 10 - Detach VM NIC from Azure Load Balancer, if currently assigned.
#           After all VMs in Availability Set are moved, Azure Load Balancer
#           will need to be reconfigured for moved VMs.

    if ( $nic.IpConfigurations[0].LoadBalancerBackendAddressPools ) {

        $nic.IpConfigurations[0].LoadBalancerBackendAddressPools = $null
    }

    if ( $nic.IpConfigurations[0].LoadBalancerInboundNatRules ) {

        $nic.IpConfigurations[0].LoadBalancerInboundNatRules = $null

    }

    if ( $nic.IpConfigurations[0].ApplicationGatewayBackendAddressPools ) {

        $nic.IpConfigurations[0].ApplicationGatewayBackendAddressPools = $null

    }

# STEP 11 - Set new properties for VM's primary NIC
#           VM NIC's private IP address will be set to Dynamic, 
#           because VNET IP address space could be different.
#           If using Static private IP address, will need to configure
#           manually after script completes.

    $nicIpConfigName = 
        $nic.IpConfigurations[0].Name

    $publicIpId = 
        $nic.IpConfigurations[0].PublicIpAddress.Id

    if ( !$publicIpId ) {

        $nicNew = 
            Set-AzureRmNetworkInterfaceIpConfig `
                -NetworkInterface $nic `
                -Name $nicIpConfigName `
                -Subnet $subnet

    } else {

        $publicIpName = $publicIpId.Split("/")[-1]
        
        $publicIp = Get-AzureRmPublicIpAddress -ResourceGroupName $rgName3 -Name $publicIpName
        
        $nicNew =
            Set-AzureRmNetworkInterfaceIpConfig `
                -NetworkInterface $nic `
                -Name $nicIpConfigName `
                -Subnet $subnet `
                -PublicIpAddress $publicIp

    }

# STEP 12 - Clean-up VM config to reflect deployment from attached disks

    $vm.StorageProfile.OSDisk.Name = $vmName

    $vm.StorageProfile.OSDisk.CreateOption = "Attach"

    $vm.StorageProfile.DataDisks | 
        ForEach-Object { $_.CreateOption = "Attach" }

    $vm.StorageProfile.ImageReference = $null

    $vm.OSProfile = $null

# STEP 13 - If VM is in an availability set, move to new availabity set

    if ( $vm.AvailabilitySetReference ) {

        $asName = $vm.AvailabilitySetReference.Id.Split("/")[-1]

        # Define new Availability Set name for VMs in new VNET
        $asNewName = "${asName}-${vnetName}"

        New-AzureRmAvailabilitySet `
            -ResourceGroupName $rgName2 `
            -Name $asNewName `
            -Location $location `
            -ErrorAction SilentlyContinue

        $as = 
            Get-AzureRmAvailabilitySet `
                -ResourceGroupName $rgName2 `
                -Name $asNewName

        $asRef = New-Object Microsoft.Azure.Management.Compute.Models.SubResource

        $asRef.id = $as.id

        $vm.AvailabilitySetReference = $asRef

    }

# STEP 14 - Re-provision VM with new configuration settings

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
                        -ResourceGroupName $rgName2 `
                        -Location $location

        }

    }

# STEP 15 - Move NIC, NSG and PublicIp to Resource Group with VM (if different)
#           Storage Accounts could be a shared resource across several VMs, so this
#           script doesn't attempt to move them.

    $nic = 
        Get-AzureRmNetworkInterface `
            -ResourceGroupName $rgName3 `
            -Name $nicName

    # Move NIC resource to new Resource Group, if needed
    
    $nicId = $nic.Id

    $nicRgName = $nic.ResourceGroupName

    if ( $nicRgName -ne $rgName2 ) {

        Move-AzureRmResource `
            -ResourceId $nicId `
            -DestinationResourceGroupName $rgName2

    }

    # Move NSG resource to new Resource Group, if needed

    $nsgId = $nic.NetworkSecurityGroup.Id

    if ( $nsgId ) {

        $nsgRgName = $nsgId.Split("/")[4]

        if ( $nsgRgName -ne $rgName2 ) {

            Move-AzureRmResource `
                -ResourceId $nsgId `
                -DestinationResourceGroupName $rgName2

        }

    }

    # Move Public IP resource to new Resource Group, if needed

    $publicIpId = $nic.IpConfigurations[0].PublicIpAddress.Id

    if ( $publicIpId ) {

        $publicIpRgName = $publicIpId.Split("/")[4]

        if ( $publicIpRgName -ne $rgName2 ) {

            Move-AzureRmResource `
                -ResourceId $publicIpId `
                -DestinationResourceGroupName $rgName2

        }

    }