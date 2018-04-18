# Sign-in to Azure via Azure Resource Manager

    Login-AzureRmAccount

# Select Azure Subscription

    $subscriptionId = 
        ( Get-AzureRmSubscription |
            Out-GridView `
              -Title "Select an Azure Subscription ..." `
              -PassThru
        ).SubscriptionId

    Set-AzureRmContext -Subscription $subscriptionId

# Create new Resource Group

    $location = "westcentralus"

    $rgName = "enter-resource-group-name"

    $rg = New-AzureRmResourceGroup `
        -Location $location `
        -Name $rgName

# Create new Storage Account

    $saName = "enter-storage-account-name"

    $sa = New-AzureRmStorageAccount `
        -Location $location `
        -ResourceGroupName $rgName `
        -Name $saName `
        -SkuName Standard_LRS `
        -Kind Storage `
        -EnableEncryptionService Blob `
        -EnableHttpsTrafficOnly $true 

 # Assign Azure AD Identity to Storage Account

    Set-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName -AssignIdentity

    $sa = Get-AzureRmStorageAccount -ResourceGroupName $rgName -Name $saName

# Create new Key Vault

    $kvName = "enter-keyvault-name"

    $kv = New-AzureRmKeyVault `
        -Location $location `
        -ResourceGroupName $rgName `
        -VaultName $kvName `
        -EnableSoftDelete `
        -Sku Standard # "Standard" or "Premium" - Premium needed for HSM

# Disable Purge on KeyVault

    $kvResource = Get-AzureRmResource -ResourceId $kv.ResourceId

    $kvResource.Properties | 
        Add-Member `
            -MemberType NoteProperty `
            -Name "enablePurgeProtection" `
            -Value $true

    Set-AzureRmResource -ResourceId $kv.ResourceId `
        -Properties $kvResource.Properties -Force

# Generate encryption key in Key Vault

    $keyName = "enter-key-name"

    $keyDestination = "Software" # "Software" or "HSM"

    $key = Add-AzureKeyVaultKey `
        -VaultName $kv.VaultName `
        -Name $keyName `
        -Destination $keyDestination

# Assign access to key for Storage Account

    Set-AzureRmKeyVaultAccessPolicy `
        -VaultName $kv.VaultName `
        -ObjectId $sa.Identity.PrincipalId `
        -PermissionsToKeys wrapkey,unwrapkey,get

# Enable SSE Encryption on Storage Account with Customer-Managed Key

    Set-AzureRmStorageAccount `
        -ResourceGroupName $sa.ResourceGroupName `
        -Name $sa.StorageAccountName `
        -KeyvaultEncryption `
        -KeyName $key.Name `
        -KeyVersion $key.Version `
        -KeyVaultUri $kv.VaultUri 

