#region Setup PowerShell for AWS

# Set PowerShell Script Execution Policy to RemoteSigned

    Set-ExecutionPolicy RemoteSigned

# Import PowerShell Module for Amazon Web Services
# Download from http://aws.amazon.com/powershell
   
    Import-Module AWSPowerShell

# Set AWS Access Key and Secret Key credentials
# Create and confirm at https://portal.aws.amazon.com/gp/aws/securityCredentials

    Set-AWSCredentials -AccessKey <insert_access_key> -SecretKey <insert_secret_key>

#endregion

#region On Source VM

# On Source VM: Create a new Amazon S3 Bucket to upload VHD

    New-S3Bucket -BucketName XXXvmtemp -Region us-west-2

# On Source VM: Upload VHD to new Amazon S3 Bucket from within source VM being migrated

    Write-S3Object -BucketName XXXvmtemp -File D:\VMTEMP\WS2008VM01.VHD -Key XXXws2008vm01 -CannedACLName Private -Region us-west-2

#endregion

#region on local Hyper-V Host

# Download VHD to local Hyper-V Host

    $vhdTempPath = "D:\VMTEMP\WS2008VM01.VHD"

    Copy-S3Object -BucketName XXXvmtemp -Key XXXws2008vm01 -localfile $vhdTempPath

# Convert Dynamically Expanding VHD to Fixed Size VHD

    $vhdConvertedPath = "D:\VHD\WS2008VM01.VHD"

    Convert-VHD -Path $vhdTempPath -DestinationPath $vhdConvertedPath -VHDType Fixed

# Install Hyper-V Integration Services

    $cabPath = "C:\Windows\vmguest\support\amd64\Windows6.x-HyperVIntegrationServices-x64.cab" # Hyper-V Integration Services for Win7 and WS2008R2

    # $CabPath = "C:\Windows\vmguest\support\amd64\Windows6.2-HyperVIntegrationServices-x64.cab" # Hyper-V Integration Services for Win8 and WS2012

    $diskNum = ( Mount-VHD -Path $vhdConvertedPath -PassThru).DiskNumber

    (Get-Disk $diskNum).OperationalStatus

    $vhdDriveLetter = (Get-Disk $diskNum | Get-Partition | Get-Volume).DriveLetter

    Set-Disk $diskNum -IsReadOnly $False

    Add-WindowsPackage -PackagePath $cabPath -Path ($vhdDriveLetter+":\")

    Dismount-VHD -Path $vhdConvertedPath

# Upload VHD and Provision VM in Windows Azure

# Set the Windows Azure Variable Values

    $myStorageAcct = "XXXlabstor02" # Windows Azure Storage Account
    $mySourceVHD = $vhdConvertedPath # Local VHD Path to Upload From
    $myDestVHD = "http://" + $myStorageAcct + ".blob.core.windows.net/vhds/WS2008VM01.vhd" # Windows Azure Storage Path to Upload To
    $myVMName = "XXXws2008vm01" # Windows Azure VM Name
    $myCloudService = "XXXws2008vm01-svc" # Windows Azure Cloud Service Name

# Upload VHD to Azure Storage Account

    Add-AzureVhd –LocalFilePath $mySourceVHD –Destination $myDestVHD

# Assign VHD to Azure Disk

    Add-AzureDisk –OS Windows –MediaLocation $myDestVHD `
	    –DiskName "$myVMName-VHD" # Add Disk for 1 VM

# Provision Azure VM

    New-AzureVMConfig -Name $myVMName -InstanceSize Small `
        -DiskName "$myVMName-VHD" |
        Add-AzureEndpoint -Protocol tcp -LocalPort 3389 -PublicPort 3389 -Name 'RemoteDesktop' |
        New-AzureVM -ServiceName $myCloudService -Location "East US"

#endregion
