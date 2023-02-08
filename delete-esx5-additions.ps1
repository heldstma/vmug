$physHost = @()
$physHost = import-csv -path h:\scripts\nestedESXi80\physhost.csv
$hosts = @()
$hosts = import-csv -path h:\scripts\nestedESXi80\nested.csv
disconnect-viserver * -confirm:$false
connect-viserver $physHost[0].FQDN -user root -password $physHost[0].HostRootPwd

get-vm $hosts[0].Name | Stop-VM -confirm:$false
get-vm $hosts[1].Name | Stop-VM -confirm:$false
get-vm $hosts[2].Name | Stop-VM -confirm:$false
get-vm $hosts[3].Name | Stop-VM -confirm:$false

get-vm $hosts[0].Name | Remove-VM -DeleteFromDisk -confirm:$false
get-vm $hosts[1].Name | Remove-VM -DeleteFromDisk -confirm:$false
get-vm $hosts[2].Name | Remove-VM -DeleteFromDisk -confirm:$false
get-vm $hosts[3].Name | Remove-VM -DeleteFromDisk -confirm:$false

get-vmhostnetworkadapter -Physical -Name "vmnic1" | remove-virtualswitchphysicalnetworkadapter -confirm:$false
get-vmhostnetworkadapter -Physical -Name "vmnic2" | remove-virtualswitchphysicalnetworkadapter -confirm:$false
get-vmhostnetworkadapter -Physical -Name "vmnic3" | remove-virtualswitchphysicalnetworkadapter -confirm:$false

get-virtualportgroup -Name $physHost[0].hostpg1 | remove-virtualportgroup -confirm:$false
get-virtualportgroup -Name $physHost[0].hostpg2 | remove-virtualportgroup -confirm:$false
get-virtualportgroup -Name $physHost[0].hostpg3 | remove-virtualportgroup -confirm:$false
get-virtualportgroup -Name $physHost[0].hostpg4 | remove-virtualportgroup -confirm:$false
disconnect-viserver * -confirm:$false
Remove-Variable * -ErrorAction SilentlyContinue


