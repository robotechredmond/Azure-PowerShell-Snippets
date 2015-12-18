$vm = New-AzureRmVMConfig -vmName $vmName -vmSize $vmSize

$nic = New-AzureRmNetworkInterface -Name $vnicName -ResourceGroupName $resourceGroupName -Location $location -SubnetId $vnet.Subnets[0].Id 

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id 

$existingOSDiskUri = "https://storageaccount.blob.core.windows.net/vhds/existing.vhd"

$vm = Set-AzureRmVMOSDisk -VM $vm -Name $OSDiskName -VhdUri $dataImageUri -Windows -CreateOption attach

New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $location -VM $vm 
