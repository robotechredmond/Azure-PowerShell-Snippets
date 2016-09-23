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

# Select Azure Resource Group

    $rgName =
        ( Get-AzureRmResourceGroup |
            Out-GridView `
              -Title "Select an Azure Resource Group ..." `
              -PassThru
        ).ResourceGroupName

    $vms = Get-AzureRMVM -ResourceGroupName $rgName 

    $vms | % { 

        $vmName = $_.Name
        $vmLocation = $_.Location
        $vmSize = $_.HardwareProfile.VirtualMachineSize
        $asName = (Get-AzureRmResource -ResourceId $_.AvailabilitySetReference.ReferenceUri).Name
        $vmNic = Get-AzureRmResource -ResourceId $_.NetworkInterfaceIDs[0]
        $vmNicName = $vmNic.Name
        $vmNicIpCfg = (Get-AzureRmResource -ResourceId $vmNic.Properties.IpConfigurations[0].Id -ApiVersion '2016-09-01')
        $vmVnet = $vmNicIpCfg.Properties.Subnet.Id.Split('/')[8]
        $vmSubnet = $vmNicIpCfg.Properties.Subnet.Id.Split('/')[10]
    
        $vmNicPrivateIp = $vmNicIpCfg.Properties.PrivateIPAddress
        $vmNicPrivateIpAlloc = $vmNicIpCfg.Properties.PrivateIPAllocationMethod

        $vmNicPublicIp = $null
        $vmNicPublicIpAlloc = $null
    
        If ($vmNicIpCfg.Properties.PublicIpAddress) {

            $vmNicPublicIpCfg = Get-AzureRmResource -ResourceId $vmNicIpCfg.Properties.PublicIPAddress.Id
            $vmNicPublicIp = $vmNicPublicIpCfg.Properties.IpAddress
            $vmNicPublicIpAlloc = $vmNicPublicIpCfg.Properties.PublicIpAllocationMethod

        }

        $vmNicNsgName = (Get-AzureRmResource -ResourceId $vmNic.Properties.NetworkSecurityGroup.Id).Name

        $vmStorageAccountName = $_.StorageProfile.OSDisk.VirtualHardDisk[0].Uri.Split('/.')[2]
        $vmStorageAccountFqdn = $_.StorageProfile.OSDisk.VirtualHardDisk[0].Uri.Split('/')[2]
        $vmStorageAccountHost = (Resolve-DnsName $vmStorageAccountFqdn).NameHost.Split('.')[1]

        Write-Output "$rgName,$vmName,$vmLocation,$vmSize,$asName,$vmStorageAccountName,$vmStorageAccountHost,$vmVnet,$vmSubnet,$vmNicPrivateIp,$vmNicPrivateIpAlloc,$vmNicNsgName,$vmNicPublicIp,$vmNicPublicIpAlloc" >>export.csv
    
    }

    # Get-AzureRmLoadBalancer -ResourceGroupName $rgName | %{ $_.BackendAddressPools.BackendIpConfigurations.Id, $_.Name }

    # Get-AzureRmLoadBalancerBackendAddressPoolConfig