# Check if default SQL instance is already clustered

Import-Module SQLPS -DisableNameChecking

$instance = (Get-Item SQLSERVER:\sql\$env:ComputerName\DEFAULT -ErrorAction SilentlyContinue).IsClustered

# Silently uninstall default SQL instance if not a clustered instance

if (!$instance) {

    Start-Process -Wait -FilePath "C:\SQLServer_12.0_Full\setup.exe" -ArgumentList "/ACTION=Uninstall /FEATURES=SQL /INSTANCENAME=MSSQLSERVER /Q /HIDECONSOLE"

}