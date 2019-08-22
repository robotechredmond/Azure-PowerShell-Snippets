((Get-AzNetworkServiceTag -Location EastUS).Values |
Where-Object { $_.Name -like "AzureCloud.*" -and $_.Properties.AddressPrefixes -contains "20.38.128.0/21" } 
).Properties