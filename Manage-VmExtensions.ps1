Param
(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName = "ienopcore-rg",

    [switch]$RemoveFailed,

    [switch]$RemoveAll
)

$vmList = Get-AzureRmVM -ResourceGroupName $ResourceGroupName
foreach ($vm in $vmList)
{
    if ($vm.Extensions -eq $null -or $vm.Extensions.Count -eq 0)
    {
        Write-Host -ForegroundColor Yellow "NONE: $($vm.Name) extension: <absent>."
    }
    else
    {
        foreach ($ext in $vm.Extensions)
        {
            $extIdParts = $ext.Id -split '/'
            $extIdName = $extIdParts[$extIdParts.Length - 1]
            $extDetails = Get-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $vm.Name -Name $extIdName
            if ($extDetails.ProvisioningState -eq "Failed")
            {
                if ($RemoveFailed -or $RemoveAll)
                {
                    Write-Host -NoNewLine -ForegroundColor Red "FAIL: $($vm.Name) extension: $extIdName. Removing..."
                    Remove-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $vm.Name -Name $extIdName -Force | Out-Null
                    Write-Host "[Done]"
                }
                else
                {
                    Write-Host -ForegroundColor Red "FAIL: $($vm.Name) extension: $extIdName."
                }
            }
            elseif ($extDetails.ProvisioningState -eq "Succeeded")
            {
                if ($RemoveAll)
                {
                    Write-Host -NoNewLine "OK:   $($vm.Name) extension: $extIdName. Removing..."
                    Remove-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $vm.Name -Name $extIdName -Force | Out-Null
                    Write-Host "[Done]"
                }
                else
                {
                    Write-Host "OK:   $($vm.Name) extension: $extIdName."
                }
            }
			else
			{
                if ($RemoveAll)
                {
                    Write-Host -NoNewLine -ForegroundColor Yellow "$($extDetails.ProvisioningState):   $($vm.Name) extension: $extIdName. Removing..."
                    Remove-AzureRmVMExtension -ResourceGroupName $ResourceGroupName -VMName $vm.Name -Name $extIdName -Force | Out-Null
                    Write-Host "[Done]"
                }
                else
                {
                    Write-Host -ForegroundColor Yellow "$($extDetails.ProvisioningState):   $($vm.Name) extension: $extIdName."
                }
			}
        }
    }
}
