Connect-AzAccount

$aaName = "Automate-35481b74-e090-40a8-888b-42bc552d8369-EUS"
$rgName = "DefaultResourceGroup-EUS"

Get-AzAutomationSchedule -ResourceGroupName $rgName -AutomationAccountName $aaName