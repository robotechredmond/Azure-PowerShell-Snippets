Login-AzureRmAccount

(Get-AzureRmResource -ResourceName $vmssName -ResourceGroupName $rgName -ExpandProperties) | ConvertTo-Json -Depth 99
