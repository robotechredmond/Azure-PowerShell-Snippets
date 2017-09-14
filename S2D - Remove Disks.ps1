$myVirtualDisk = Get-VirtualDisk | Out-GridView -PassThru -Title "Please select the Virtual Disk"
 
$storagepool = Get-StoragePool -VirtualDisk $myVirtualDisk
 
$node1 = Get-StorageNode | Out-GridView -PassThru -Title "Please select the first Node"
$node2 = Get-StorageNode | Out-GridView -PassThru -Title "Please select the second Node"
 
$DisksToRemoveFromNode1 = @()
$DisksToRemoveFromNode2 = @()
 
$SelectedDisksToRemoveFromNode1 = Get-PhysicalDisk -StorageNode $node1 -PhysicallyConnected | select * | Sort-Object PhysicalLocation | Out-GridView -PassThru -Title ("Select disk to remove from node {0}" -f $node1.Name)
foreach ($selectedDisk in $SelectedDisksToRemoveFromNode1) { $DisksToRemoveFromNode1 += Get-PhysicalDisk -UniqueId $selectedDisk.UniqueId }
$SelectedDisksToRemoveFromNode2 = Get-PhysicalDisk -StorageNode $node2 -PhysicallyConnected | select * | Sort-Object PhysicalLocation | Out-GridView -PassThru -Title ("Select disk to remove from node {0}" -f $node2.Name)
foreach ($selectedDisk in $SelectedDisksToRemoveFromNode2) { $DisksToRemoveFromNode2 += Get-PhysicalDisk -UniqueId $selectedDisk.UniqueId }
 
$DisksToRemoveFromNode1 | Set-PhysicalDisk -NewFriendlyName "Disk from node 1 to remove"
$DisksToRemoveFromNode2 | Set-PhysicalDisk -NewFriendlyName "Disk from node 2 to remove"
 
$DisksToRemoveFromNode1 | Set-PhysicalDisk -Usage Retired
$DisksToRemoveFromNode2 | Set-PhysicalDisk -Usage Retired
 
$myVirtualDisk | Repair-VirtualDisk -AsJob
 
Get-StorageJob
 
Remove-PhysicalDisk -PhysicalDisks $DisksToRemoveFromNode1 -StoragePool $storagepool -Confirm:$false
Remove-PhysicalDisk -PhysicalDisks $DisksToRemoveFromNode2 -StoragePool $storagepool 