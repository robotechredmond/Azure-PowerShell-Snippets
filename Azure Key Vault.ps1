Add-AzureAccount

(Get-AzureSubscription).SubscriptionName

Select-AzureSubscription -SubscriptionName 'Keith Internal'

Switch-AzureMode -Name AzureResourceManager

New-AzureResourceGroup -Name 'DemoResourceGroup' -Location 'East US'

Get-AzureResourceGroup -ResourceGroupName 'DemoResourceGroup'

New-AzureKeyVault -VaultName 'MyDemoVault' -ResourceGroupName 'DemoResourceGroup' -Location 'East US' -SKU Premium

Get-AzureKeyVault -VaultName 'MyDemoVault'

Set-AzureKeyVaultAccessPolicy -VaultName 'MyDemoVault' -ServicePrincipalName 49297c7c-7479-465f-8bc3-501a64d59479 -PermissionsToKeys create,get,list,wrapKey,unwrapKey

Set-AzureKeyVaultAccessPolicy -VaultName 'MyDemoVault' -ServicePrincipalName ea0170a3-2bb2-40e0-966b-9d14cd9d5685 -PermissionsToKeys get,list,wrapKey,unwrapKey

