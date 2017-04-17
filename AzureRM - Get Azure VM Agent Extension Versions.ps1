Login-AzureRmAccount

$location = "southeastasia"

(Get-AzureRmVMExtensionImage -Location $location -PublisherName “Microsoft.PowerShell” -Type “DSC”).Version

(Get-AzureRmVMExtensionImage -Location $location -PublisherName “Microsoft.Azure.Security” -Type “IaaSAntimalware”).Version