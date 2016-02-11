# Sign-in with Azure account credentials

Login-AzureRmAccount

# Select Azure Subscription

$subscriptionId = 
    (Get-AzureRmSubscription |
     Out-GridView `
        -Title "Select an Azure Subscription ..." `
        -PassThru).SubscriptionId

Select-AzureRmSubscription `
    -SubscriptionId $subscriptionId

# Select Azure Resource Group 

$rgName =
    (Get-AzureRmResourceGroup |
     Out-GridView `
        -Title "Select an Azure Resource Group ..." `
        -PassThru).ResourceGroupName

$rg =
    Get-AzureRmResourceGroup `
        -Name $rgName

# Create New Key Vault
# To create via ARM template - https://github.com/Azure/azure-quickstart-templates/tree/master/101-key-vault-create

$vaultName = 'MyDemoVault01'

$vaultSKU = 'Premium'

New-AzureRmKeyVault `
    -VaultName $vaultName `
    -ResourceGroupName $rgName `
    -Location $rg.Location `
    -SKU $vaultSKU

# Get Key Vault

$vault =
    Get-AzureRmKeyVault `
        -VaultName $vaultName `
        -ResourceGroupName $rgName

# Show current properties of Key Vault

$vault | Format-List

# Set Azure Key Vault Access Policy for ARM Template Deployments

Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -EnabledForTemplateDeployment

# Set Azure Key Vault Access Policy for ARM Compute xRP Deployments

Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -EnabledForDeployment

# Set Azure Key Vault Access Policy for SQL TDE
# For details - https://msdn.microsoft.com/en-us/library/dn198405(v=sql.120).aspx
# Video walk-through - https://channel9.msdn.com/Shows/TechNet+Radio/TechNet-Radio-Part-23-Building-Your-Hybrid-Cloud-Azure-Key-Vault

$spName1 = '<aad-client-id1>' # Service Principal for SQL Server Admin

$spName2 = '<aad-client-id2>' # Service Principal for SQL Server DB Engine

Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -ServicePrincipalName $spName1 `
    -PermissionsToKeys create,get,list,wrapKey,unwrapKey

Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -ServicePrincipalName $spName2 `
    -PermissionsToKeys get,list,wrapKey,unwrapKey

# Store password credentials in Key Vault
# Sample template - https://github.com/Azure/azure-quickstart-templates/tree/master/101-vm-secure-password

$secret = 
    Read-Host `
        -Prompt 'Enter password' `
        -AsSecureString

$secretName = 'ITSecret'

Set-AzureKeyVaultSecret `
    -VaultName $vaultName `
    -Name $secretName `
    -SecretValue $secret

Get-AzureKeyVaultSecret `
    -VaultName $vaultName `
    -Name $secretName

# Store certificate in Key Vault
# Sample template - https://github.com/Azure/azure-quickstart-templates/tree/master/201-vm-winrm-keyvault-windows
# Details - http://blogs.technet.com/b/kv/archive/2015/07/14/vm_2d00_certificates.aspx

$certFilename = '.\SampleCert.pfx'

$certPassword = 
    Read-Host `
        -Prompt 'Enter password' 

$fileContentBytes = 
    get-content $certFileName -Encoding Byte

$fileContentEncoded = 
    [System.Convert]::ToBase64String($fileContentBytes)

$jsonObject = @"
    {
    "data": "$filecontentencoded",
    "dataType" :"pfx",
    "password": "$certPassword"
    }
"@

$jsonObjectBytes = 
    [System.Text.Encoding]::UTF8.GetBytes($jsonObject)

$jsonEncoded = 
    [System.Convert]::ToBase64String($jsonObjectBytes)

$secret = 
    ConvertTo-SecureString `
        -String $jsonEncoded `
        -AsPlainText `
        -Force

$secretName = 'SampleCert'

Set-AzureKeyVaultSecret `
    -VaultName $vaultName `
    -Name $secretName `
    -SecretValue $secret

Get-AzureKeyVaultSecret `
    -VaultName $vaultName `
    -Name $secretName

# Enable Disk Encryption for IaaS VMs
# Sample Template - https://github.com/Azure/azure-quickstart-templates/tree/master/201-encrypt-create-new-vm-gallery-image/
# Details - http://blogs.msdn.com/b/azuresecurity/archive/2015/11/17/explore-azure-disk-encryption-with-azure-powershell.aspx

$aadClientID = 
    '<aad-client-id>'

$aadClientSecret = 
    '<aad-client-secret>'

$vaultUri = 
    $vault.VaultUri

$vaultResourceId = 
    $vault.ResourceId

Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -ServicePrincipalName $aadClientID `
    -PermissionsToKeys all `
    -PermissionsToSecrets all 

Set-AzureRmKeyVaultAccessPolicy `
    -VaultName $vaultName `
    -EnabledForDiskEncryption

$rgName =
    (Get-AzureRmResourceGroup |
     Out-GridView `
        -Title "Select an Azure Resource Group ..." `
        -PassThru).ResourceGroupName

$rg =
    Get-AzureRmResourceGroup `
        -Name $rgName

$vmName =
    (Get-AzureRmVm `
        -ResourceGroupName $rgName).Name |
    Out-GridView `
        -Title "Select an Azure VM ..." `
        -PassThru

$vm = 
    Get-AzureRmVm `
        -ResourceGroupName $rgName `
        -Name $vmName

$vm | Start-AzureRmVm

$vmStatus =
    (Get-AzureRmVm `
        -ResourceGroupName $rgName `
        -Name $vmName `
        -Status).Statuses

$vmStatus[-1]

Set-AzureRmVMDiskEncryptionExtension `
    -ResourceGroupName $rgName `
    -VMName $vmName `
    -AadClientID $aadClientID `
    -AadClientSecret $aadClientSecret `
    -DiskEncryptionKeyVaultUrl $vaultUri `
    -DiskEncryptionKeyVaultId $vaultResourceId `
    -VolumeType All `
    -Force

 Get-AzureRmVMDiskEncryptionStatus `
    -ResourceGroupName $rgName `
    -VMName $vmName

# Enable Logging for Key Vault

$saName = $vaultName.ToLower() + "logs"

$sa = 
    New-AzureRmStorageAccount `
        -ResourceGroupName $rgName `
        -Name $saName `
        -Type Standard_LRS `
        -Location $rg.Location

Set-AzureRmDiagnosticSetting `
    -ResourceId $vault.ResourceId `
    -StorageAccountId $sa.Id `
    -Enabled $true `
    -Categories AuditEvent

$container =
    'insights-logs-auditevent'

$logs = 
    Get-AzureStorageBlob `
        -Container $container `
        -Context $sa.Context

$logs | Get-AzureStorageBlobContent -Destination '.' -Force