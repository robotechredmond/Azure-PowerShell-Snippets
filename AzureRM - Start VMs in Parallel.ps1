workflow Shutdown-Start-ARM-VMs-Parallel {

    Param(

        [Parameter(Mandatory=$true)]
        [String]
        $ResourceGroupName,

        [Parameter(Mandatory=$true)]
        [Boolean]
        $Shutdown

    )
            
    #The name of the Automation Credential Asset this runbook will use to authenticate to Azure.

    $CredentialAssetName = "DefaultAzureCredential";
            
    #Get the credential with the above name from the Automation Asset store

    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName

    if(!$Cred) {

        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    
    }

    #Connect to your Azure Account

    Add-AzureRmAccount -Credential $Cred
            
    $vms = Get-AzureRmVM -ResourceGroupName $ResourceGroupName;
            
    Foreach -Parallel ( $vm in $vms ) {
                        
        if ( $Shutdown ) {

            Write-Output "Stopping $($vm.Name)";              
            Stop-AzureRmVm -Name $vm.Name -ResourceGroupName $ResourceGroupName -Force;

        }

        else {

            Write-Output "Starting $($vm.Name)";                
            Start-AzureRmVm -Name $vm.Name -ResourceGroupName $ResourceGroupName;

        }

    }

}
