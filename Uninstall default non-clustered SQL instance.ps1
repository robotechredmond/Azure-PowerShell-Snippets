# Check if default SQL instance is already clustered

Import-Module SQLPS -DisableNameChecking

$instance = (Get-Item SQLSERVER:\sql\$env:ComputerName\DEFAULT -ErrorAction SilentlyContinue).IsClustered

# Silently uninstall default SQL instance if not a clustered instance

if (!$instance) {

    Start-Process -Wait -FilePath "C:\SQLServer_13.0_Full\setup.exe" -ArgumentList "/ACTION=Uninstall /FEATURES=SQL,AS,RS /INSTANCENAME=MSSQLSERVER /Q /HIDECONSOLE"

    Restart-Computer

}

# Silently install SQL Failover Cluster

Test-Cluster

Start-Process -Wait -FilePath "C:\SQLServer_13.0_Full\setup.exe" -ArgumentList '/Q /HIDECONSOLE /ACTION=InstallFailoverCluster /InstanceName=MSSQLSERVER /FAILOVERCLUSTERDISKS="Cluster Virtual Disk (VDisk01)" /INSTALLSQLDATADIR="C:\ClusterStorage\Volume1\MSSQLSERVER" /FAILOVERCLUSTERNETWORKNAME="Cluster Network 1" /FAILOVERCLUSTERIPADDRESSES="IPv4;10.0.1.10;Cluster Network 1;10.0.1.255 IPv4;10.0.1.6;Cluster Network 1;10.0.1.255" /FAILOVERCLUSTERGROUP="MSSQLSERVER" /Features=SQL /AGTSVCACCOUNT="CONTOSO\sqlservice" /AGTSVCPASSWORD="P@ssp0rt1234" /SQLCOLLATION="SQL_Latin1_General_CP1_CS_AS" /SQLSVCACCOUNT="CONTOSO\sqlservice" /SQLSVCPASSWORD="P@ssp0rt1234" /SQLSYSADMINACCOUNTS="CONTOSO\AzureAdmin" /IACCEPTSQLSERVERLICENSETERMS'

Start-Process -Wait -FilePath "C:\SQLServer_13.0_Full\setup.exe" -ArgumentList '/Q /HIDECONSOLE /ACTION=AddNode /InstanceName=MSSQLSERVER /AGTSVCACCOUNT="CONTOSO\sqlservice" /AGTSVCPASSWORD="P@ssp0rt1234" /SQLSVCACCOUNT="CONTOSO\sqlservice" /SQLSVCPASSWORD="P@ssp0rt1234" /IACCEPTSQLSERVERLICENSETERMS'