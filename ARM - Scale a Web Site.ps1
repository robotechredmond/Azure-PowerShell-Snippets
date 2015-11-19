# Authenticate with Azure Account

Add-AzureAccount

# Switch Azure PowerShell Mode to Resource Manager

Switch-AzureMode -Name AzureServiceManagement
# Get WebApp Server Farm Id

$webAppName = "kemwebapp02"

$webApp = Get-AzureResource `
    -ExpandProperties | 
    Where-Object { 
        $_.Name -eq $webAppName `
        -and `
        $_.ResourceType -eq "Microsoft.Web/sites" `
    } 

$serverFarmId = $webApp.Properties.serverFarmId

# Set new number of WebApps instances

$numInstances= 1

$resourceProps = @{"numberOfWorkers" = $numInstances}

$apiVers = "2015-02-01"

Set-AzureResource `
    -ResourceId $serverFarmId `
    -Properties $resourceProps `
    -ApiVersion $apiVers `
    -OutputObjectFormat New `
    -Force

# Confirm new number of WebApps instances

$webFarm = Get-AzureResource `
    -ResourceId $serverFarmId 

$webFarm.Properties.currentNumberOfWorkers

