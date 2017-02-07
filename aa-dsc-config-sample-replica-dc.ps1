Configuration ReplicaDC {
        param 
	    ( 
	        [Parameter(Mandatory)]
	        [String]$DomainName
	    )
        
        Import-DscResource -ModuleName xActiveDirectory

        $AdminCreds = Get-AutomationPSCredential -Name "aa-credential-asset-name"
               
        Node $AllNodes.Localhost {
           WindowsFeature InstallADDS {
                Ensure = "Present"
                Name = "AD-Domain-Services"
           }
           xADDomainController ReplicaDC { 
                DomainName = $DomainName
                DomainAdministratorCredential = $AdminCreds
           }            
        }
}

$Params = @{"DomainName"="contoso.com"}

# Note that PSDscAllowPlainTextPassword does not present security issue, because Azure Automation encrypts the compiled MOF itself.

$ConfigData = @{
    AllNodes = @(
        @{
            NodeName =  "*"
            PSDscAllowPlainTextPassword = $True
        }

    )
} 

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName "rg01" -AutomationAccountName  "auto01" -ConfigurationName "ReplicaDC" -Parameters $Params -ConfigurationData $ConfigData