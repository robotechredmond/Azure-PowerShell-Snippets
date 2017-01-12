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

# Register for Multi-IP preview feature

    Register-AzureRmProviderFeature `
        -FeatureName AllowMultipleIpConfigurationsPerNic `
        -ProviderNamespace Microsoft.Network

    Register-AzureRmResourceProvider `
        -ProviderNamespace Microsoft.Network

# Once approved, the below cmdlet will return "Registered" for the "RegistrationState" of this feature

    Get-AzureRmProviderFeature `
        -FeatureName AllowMultipleIpConfigurationsPerNic `
        -ProviderNamespace Microsoft.Network

# Select Azure Resource Group containing one or more VMs

    $rgName =
        (Get-AzureRmResourceGroup |
         Out-GridView `
            -Title "Select an Azure Resource Group ..." `
            -PassThru).ResourceGroupName

# Enable Multi IP for each SQL VM node
# Perform this block once for each SQL VM node

    # Select VM from Resource Group to assign one or more secondary private IP addresses

    $vmName =
        (Get-AzureRmVM `
            -ResourceGroupName $rgName).Name | 
         Out-GridView `
            -Title "Select an Azure VM ..." `
            -PassThru

    # Get object reference to primary NIC from selected VM

    $vmNicId = 
        (Get-AzureRmVM `
         -ResourceGroupName $rgName `
         -Name $vmName `
        ).NetworkInterfaceIDs[0]

    $vmNicName = $vmNicId.Split("/")[-1]

    $vmNic = 
        Get-AzureRmNetworkInterface `
            -ResourceGroupName $rgName `
            -Name $vmNicName

    # Specify how many secondary private IP addresses to add to SQL VM NIC (Max = 250)
    # Need 1 secondary IP for WSFC cluster, and 1 secondary IP per SQL AG listener

    $secondaryIPTotal = 5

    # Add the secondary private IP addresses to the selected VM NIC

    for ($secondaryIPCount = 2; $secondaryIPCount -le $secondaryIPTotal+1; $SecondaryIPCount++)
    { 

        $vmIPConfigName = "ipconfig$secondaryIPCount"
    
        $vmNic | 
            Add-AzureRmNetworkInterfaceIpConfiguration `
                -Name $vmIPConfigName `
                -Subnet $vmNic.IpConfigurations[0].Subnet

    }

    $vmNic | Set-AzureRmNetworkInterface

    # Confirm the private IP addresses to be used within VM Guest OS
    #
    # NOTE: If using the secondary private IP addresses for AlwaysOn clustering, DO NOT configure 
    #       the secondary IP addresses on the NIC properties within the VM Guest OS, as these IP addresses 
    #       will be configured as cluster resources instead as part of the SQL AlwaysOn configuration. 
    #       In this configuration, only the primary IP address for each SQL VM NIC should be configured as
    #       a static address within the VM Guest OS NIC properties.
    #

    (Get-AzureRmNetworkInterface `
        -ResourceGroupName $rgName `
        -Name $vmNicName `
    ).IpConfigurations.PrivateIpAddress

# Install Windows Server Failover Clustering feature on each Node
# Perform once on each SQL node

    Install-WindowsFeature Failover-Clustering -IncludeManagementTools 

# Create Windows Server Failover Cluster

    New-Cluster `
        -Name ClusterName `
        -Node PrimaryComputer,SecondaryComputer `
        -StaticAddress IPAddress1,IPAddress2 `
        -NoStorage

    Set-ClusterQuorum -NodeAndFileShareMajority \\contosofswm01\witness 

# Disable Automatic Clustering of Storage on each Node

    Get-StorageSubsystem `
        -FriendlyName 'Clustered Storage Spaces*' | 
        Set-StorageSubSystem `
            -AutomaticClusteringEnabled $False

# Relax Cluster Network Timing

    (Get-Cluster).SameSubnetDelay = 2000

    (Get-Cluster).SameSubnetThreshold = 15

    (Get-Cluster).CrossSubnetDelay = 3000

    (Get-Cluster).CrossSubnetThreshold = 15

# Enable SQL Server AlwaysOn Availability Groups

    Enable-SqlAlwaysOn -ServerInstance PrimaryComputer

    Enable-SqlAlwaysOn -ServerInstance SecondaryComputer

# Configure SQL Server AlwaysOn AG 
# See https://msdn.microsoft.com/en-us/library/gg492181.aspx
# Run through rest of code blocks below once per availability group

    # Backup database and log on the primary

    Import-Module SQLPS
    
    Set-Location "SQLSERVER:\SQL\PrimaryComputer\Instance"
    
    Backup-SqlDatabase `
        -Database "MyDatabase" `
        -BackupFile "\\share\backups\MyDatabase.bak" 

    Backup-SqlDatabase `
        -Database "MyDatabase" `
        -BackupFile "\\share\backups\MyDatabase.log" `
        -BackupAction Log 

    # Restore database and log on the secondary (using NO RECOVERY)
    
    Import-Module SQLPS
    
    Set-Location "SQLSERVER:\SQL\SecondaryComputer\Instance"

    Restore-SqlDatabase `
        -Database "MyDatabase" `
        -BackupFile "\\share\backups\MyDatabase.bak" `
        -NoRecovery

    Restore-SqlDatabase `
        -Database "MyDatabase" `
        -BackupFile "\\share\backups\MyDatabase.log" `
        -RestoreAction Log `
        -NoRecovery

    # Create an in-memory representation of the primary replica.
    # Note that "\Instance" is not required in -Name parameter if using DEFAULT instance

    $primaryServer = Get-Item "SQLSERVER:\SQL\PrimaryServer\Instance22"

    $primaryReplica = New-SqlAvailabilityReplica `
        -Name "PrimaryComputer\Instance" `
        -EndpointURL "TCP://PrimaryComputer.domain.com:5022" `
        -AvailabilityMode "SynchronousCommit" `
        -FailoverMode "Automatic" `
        -Version ($primaryServer.Version) `
        -AsTemplate

    # Create an in-memory representation of the secondary replica.
    # Note that "\Instance" is not required in -Name parameter if using DEFAULT instance

    $secondaryServer = Get-Item "SQLSERVER:\SQL\SecondaryServer\Instance22"

    $secondaryReplica = New-SqlAvailabilityReplica `
        -Name "SecondaryComputer\Instance" `
        -EndpointURL "TCP://SecondaryComputer.domain.com:5022" `
        -AvailabilityMode "SynchronousCommit" `
        -FailoverMode "Automatic" `
        -Version ($secondaryServer.Version) `
        -AsTemplate

    # Create the availability group

    New-SqlAvailabilityGroup `
        -Name "MyAG" `
        -Path "SQLSERVER:\SQL\PrimaryComputer\Instance" `
        -AvailabilityReplica @($primaryReplica,$secondaryReplica) `
        -Database "MyDatabase"

    # Join the secondary replica to the availability group.

    Join-SqlAvailabilityGroup `
        -Path "SQLSERVER:\SQL\SecondaryComputer\Instance" `
        -Name "MyAG"

    # Join the secondary database to the availability group.

    Add-SqlAvailabilityDatabase `
        -Path "SQLSERVER:\SQL\SecondaryComputer\Instance\AvailabilityGroups\MyAG" `
        -Database "MyDatabase"

    # Configure SQL AlwaysOn AG Listener
    # See https://msdn.microsoft.com/en-us/library/hh213080.aspx
    # See https://blogs.msdn.microsoft.com/alwaysonpro/2014/06/03/connection-timeouts-in-multi-subnet-availability-group/

    New-SqlAvailabilityGroupListener `
        -Name "MyListener" `
        -Path "SQLSERVER:\Sql\Computer\Instance\AvailabilityGroups\MyAG" `
        -StaticIp "IPAddress1/255.255.255.0","IPAddress2/255.255.255.0" `
        -Port 1433 
