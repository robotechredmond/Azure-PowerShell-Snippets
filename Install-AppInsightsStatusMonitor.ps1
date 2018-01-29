
Configuration AppInsightsConfig
{
    Node localhost
    {    
        Script WebPi_Download
        {
            SetScript = 'Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkId=255386" -OutFile "${env:TEMP}\webpilauncher.exe"'
            TestScript = '((Get-ChildItem -Path ${env:TEMP}\webpilauncher.exe -ErrorAction SilentlyContinue).Exists -eq $True)'
            GetScript = '@{Ensure = if ((Get-ChildItem -Path ${env:TEMP}\webpilauncher.exe -ErrorAction SilentlyContinue).Exists -eq $True) {"Present"} else {"Absent"}'
        }
        
        Package WebPi_Installation
        {
            Ensure = "Present"
            Name = "Microsoft Web Platform Installer 5.0"
            Path = "${env:TEMP}\webpilauncher.exe"
            ProductId = "4D84C195-86F0-4B34-8FDE-4A17EB41306A"
            Arguments = ""
            DependsOn = @("[Script]WebPi_Download")
        }

        Package AppInsights_Installation
        {
            Ensure = "Present"
            Name = "Application Insights Status Monitor"
            Path = "${env:ProgramFiles}\Microsoft\Web Platform Installer\WebPiCmd-x64.exe"
            ProductId = ""
            Arguments = "/install /products:ApplicationInsightsStatusMonitor /AcceptEula"
            DependsOn = @("[Package]WebPi_Installation")
        }

    }

}

AppInsightsConfig

Start-DscConfiguration -Path .\AppInsightsConfig -Wait -Force 
