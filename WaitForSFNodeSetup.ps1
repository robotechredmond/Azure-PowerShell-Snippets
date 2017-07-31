function WaitForSFNodeSetup
{

    $logPath = "."

    $logFileMatch = "FabricMSIInstall*.log"

    $logContentMatch = "Product: Microsoft Azure Service Fabric -- Installation completed successfully"

    $logSuccess = $false

    do
    {
        Start-Sleep -Seconds 30

        $logFile = (Get-ChildItem -Path $logPath -Recurse -File -Include $logFileMatch -ErrorAction SilentlyContinue).FullName

        if ($logFile -ne $null) {
            $logContent = Get-Content -Path $logFile -Tail 50
            $logSuccess = ($logContent -match $logContentMatch)
        }
    }
    until ($logSuccess)

}

