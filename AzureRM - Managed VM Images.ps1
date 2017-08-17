# Sign-in with Azure AD account credentials
Login-AzureRmAccount

# Select Azure subscription
$subscriptionName = "Contoso Sports"
Select-AzureRmSubscription -SubscriptionName $subscriptionName

# Stop and deallocate existing VM 
$vmName = "winvmr2a1"
$rgName = "winvmr2-rg"
$location = "WestUS2"
Stop-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Force

# Set status of existing VM to "Generalized"
Set-AzureRmVM -ResourceGroupName $rgName -Name $vmName -Generalized

# Get properties of existing VM
$vm = Get-AzureRmVM -ResourceGroupName $rgName -Name $vmName

# Create managed image from existing VM
$image = New-AzureRmImageConfig -Location $location -SourceVirtualMachineId $vm.Id
New-AzureRmImage -ResourceGroupName $rgName -ImageName ${vmName}-image -Image $image
