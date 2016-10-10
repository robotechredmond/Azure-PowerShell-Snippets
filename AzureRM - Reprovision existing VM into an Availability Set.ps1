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

# Create a new Azure availability set

    $asName = 
        Read-Host `
            -Prompt "Enter a new Availability Set name"

    $as = 
        New-AzureRmAvailabilitySet `
            -Name $asName `
            -ResourceGroupName $rgName `
            -Location $location

# Stop and Deprovision existing Azure VM, retaining Disks

    $vm | Stop-AzureRmVm -Force

    $vm | Remove-AzureRmVm -Force

# Set VM config to include new Availability Set

    $asRef = New-Object Microsoft.Azure.Management.Compute.Models.AvailabilitySetReference

    $asRef.ResourceUri = $as.Id

    $vm.AvailabilitySetReference = $asRef # To remove VM from Availability Set, set to $null

# Clean-up VM config to reflect deployment from attached disks

    $vm.StorageProfile.OSDisk.Name = $vmName

    $vm.StorageProfile.OSDisk.CreateOption = "Attach"

    $vm.StorageProfile.DataDisks | 
        ForEach-Object { $_.CreateOption = "Attach" }

    $vm.StorageProfile.ImageReference = $null

    $vm.OSProfile = $null

# Re-provision VM from attached disks

    $vm | 
        New-AzureRmVm `
            -ResourceGroupName $rgName `
            -Location $location
