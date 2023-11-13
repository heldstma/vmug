$workingcsvfolder = "C:\Users\uo5221ps.VMATT\OneDrive - MNSCU\Documents\scripts\nestedESXi80"
$physHost = @()
$physHost = import-csv -path $workingcsvfolder\physhost-nuc2.csv
$hosts = @()
$hosts = import-csv -path $workingcsvfolder\nested-nuc2.csv

disconnect-viserver * -confirm:$false
connect-viserver $physHost[0].vCenterFQDN -user administrator@vsphere.local -password $physHost[0].vCenterPwd


#$spec = New-Object VMware.Vim.ClusterConfigSpecEx
#$spec.DrsConfig = New-Object VMware.Vim.ClusterDrsConfigInfo
#$spec.SystemVMsConfig = New-Object VMware.Vim.ClusterSystemVMsConfigSpec
#$spec.SystemVMsConfig.DeploymentMode = 'ABSENT'
#$spec.DpmConfig = New-Object VMware.Vim.ClusterDpmConfigInfo
#$modify = $true
#$_this = Get-View -Id 'ClusterComputeResource-domain-c8009'
#$_this.ReconfigureComputeResource_Task($spec, $modify)


#disconnect-viserver * -confirm:$false
#connect-viserver $physHost[0].vCenterFQDN -user administrator@vsphere.local -password $physHost[0].vCenterPwd

#get-cluster $physHost[0].vsanCluster | get-vm | Stop-VM -confirm:$false
#get-cluster $physHost[0].vsanCluster | get-vm | Remove-VM -DeleteFromDisk -confirm:$false
#get-resourcepool -Name 1-Gold | Remove-ResourcePool -confirm:$false
#get-resourcepool -Name 2-Silver | Remove-ResourcePool -confirm:$false
#get-resourcepool -Name 3-Bronze | Remove-ResourcePool -confirm:$false

foreach ($i in $hosts){
get-vmhost $i.FQDN | set-vmhost -State "Disconnected"
get-vmhost $i.FQDN | remove-vmhost -confirm:$false
get-vm $i.Name | Stop-VM -confirm:$false
get-vm $i.Name | Remove-VM -DeleteFromDisk -confirm:$false
}
get-cluster $physHost[0].vsanCluster | remove-cluster -confirm:$false
get-vdswitch VDS_VSAN8 | get-vdportgroup | remove-vdportgroup -confirm:$false
get-vdswitch VDS_VSAN8 | Remove-VDSwitch -confirm:$false
get-virtualportgroup -VMHost $physHost[0].FQDN -Name $physHost[0].hostpg1 | remove-virtualportgroup -confirm:$false
get-virtualportgroup -VMHost $physHost[0].FQDN -Name $physHost[0].hostpg2 | remove-virtualportgroup -confirm:$false
get-virtualportgroup -VMHost $physHost[0].FQDN -Name $physHost[0].hostpg3 | remove-virtualportgroup -confirm:$false

disconnect-viserver * -confirm:$false
#Remove-Variable * -ErrorAction SilentlyContinue


