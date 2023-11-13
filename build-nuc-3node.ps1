#https://www.virten.net/vmware/powershell-ovf-helper/vmware-esxi-virtual-appliance-8-0/
#https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/How-to-set-Hardware-virtualization-gt-expose/td-p/1758017

disconnect-viserver * -confirm:$false
set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
set-powercliconfiguration -InvalidCertificateAction Ignore -confirm:$false
$workingcsvfolder = "C:\Users\uo5221ps.VMATT\OneDrive - MNSCU\Documents\scripts\nestedESXi80"
$physHost = @()
$physHost = import-csv -path $workingcsvfolder\physhost-nuc2.csv
$hosts = @()
$hosts = import-csv -path $workingcsvfolder\nested-nuc2.csv
$cc = "Yellow"
$spec1 = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec1.nestedHVEnabled = $true
$spec1.Firmware = [VMware.Vim.GuestOsDescriptorFirmwareType]::efi
$stopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$ISOdatastore = "INTERNAL-ESX02-SSD"
$DeployTemplate = "XPTEMPLATE"
$LinuxCustSpecName = "Linux"
write-host "Starting Script Timer" -ForegroundColor $cc
$stopWatch.Start()

write-host "Connecting to $($physHost[0].vCenterFQDN)" -ForegroundColor $cc
connect-viserver $physHost[0].vCenterFQDN -user $physHost[0].vCenterUsername -password $physHost[0].vCenterPwd

sleep 5

$vSwitch = get-virtualswitch -VMHost $physHost[0].FQDN -Name $physHost[0].hostvSwitch
new-virtualportgroup -name $physHost[0].hostpg1 -VirtualSwitch $vSwitch -VLanId 4095 -Confirm:$false
get-virtualportgroup -VMHost $physHost[0].FQDN -name $physHost[0].hostpg1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0
get-virtualportgroup -name $physHost[0].hostpg1 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -ForgedTransmits $true -AllowPromiscuous $true
new-virtualportgroup -name $physHost[0].hostpg2 -VirtualSwitch $vSwitch -Confirm:$false
get-virtualportgroup -name $physHost[0].hostpg2 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -ForgedTransmits $true -AllowPromiscuous $true
new-virtualportgroup -name $physHost[0].hostpg3 -VirtualSwitch $vSwitch -Confirm:$false
get-virtualportgroup -name $physHost[0].hostpg3 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -ForgedTransmits $true -AllowPromiscuous $true

foreach ($i in $hosts){
write-Host "Building new"($i.Name)"VM" -ForegroundColor $cc
write-Host ($i.Name)"VM being configured with"($i.CPUtotal)"vCPU,"($i.memoryGB)"GB Memory" -ForegroundColor $cc
new-vm -VMHost $physHost[0].FQDN -Name $i.Name -Location $i.datacenter -Datastore $i.bootDatastore -GuestId "vmkernel8Guest" -NumCPU $i.CPUtotal -CoresPerSocket $i.corespersocket -MemoryGB $i.memoryGB -HardwareVersion vmx-20 -DiskGB $i.bootGB -CD
get-vm $i.Name | get-NetworkAdapter | Set-NetworkAdapter -NetworkName NESTED_PORT1_ALLVLANS -confirm:$false
New-HardDisk -VM $i.Name -CapacityGB $i.SSD1GB -Datastore $i.SSD1Datastore -StorageFormat Thick
New-HardDisk -VM $i.Name -CapacityGB $i.SSD2GB -Datastore $i.SSD2Datastore -StorageFormat Thick
New-NetworkAdapter -VM $i.Name -NetworkName $physHost[0].hostpg2 -Type Vmxnet3 -StartConnected
New-NetworkAdapter -VM $i.Name -NetworkName $physHost[0].hostpg3 -Type Vmxnet3 -StartConnected
start-sleep -seconds 5


write-Host "Mounting Custom ESXi installer on $($i.FQDN) VM" -ForegroundColor $cc
get-vm $i.Name | get-cddrive | set-cddrive -isopath "[$ISOdatastore] ISO/$($i.ESXiISOName)" -StartConnected $true -confirm:$false

$vm = Get-VM -Name $i.Name 
write-Host "Configuring $($i.FQDN) for nested virtualization and EFI firmware" -ForegroundColor $cc
$vm.ExtensionData.ReconfigVM($spec1)
write-Host "Powering on $($i.FQDN) VM" -ForegroundColor $cc
start-vm $i.Name
start-sleep -seconds 5
}

write-Host "VM's are created and powered on.  ESXi is installing -- waiting for hosts to come up for customization." -ForegroundColor $cc
$folder = get-folder -NoRecursion
#New-Datacenter -Location $folder -Name NUCLAB

write-Host "Creating VSAN Cluster object" -ForegroundColor $cc
new-cluster -Name $physHost[0].vsanCluster -Location $physHost[0].Datacenter -Server $physHost[0].vCenterFQDN

foreach ($i in $hosts){
 
do {
  Write-Host "waiting for"$i.FQDN"to come up on HTTPS..." -ForegroundColor $cc
  sleep 3      
} until(Test-NetConnection $i.FQDN -Port 443 | ? { $_.TcpTestSucceeded } )

sleep 45

write-host "Adding host"$i.FQDN"to vCenter Server"$i.vCenterFQDN -ForegroundColor $cc
add-vmhost -Name $i.FQDN -Location $physHost[0].vsanCluster -user root -Password $i.HostRootPwd -Force

write-host "Connecting to"$i.Name -ForegroundColor $cc
write-host "Deleting VM Network port group if it exists on"$i.Name -ForegroundColor $cc
get-virtualportgroup -Name "VM Network" | remove-virtualportgroup -Confirm:$false

write-host "Configuring vmnic0 active"$i.NestedPG1"port group on"$i.Name -ForegroundColor $cc
$hostvSwitch = get-virtualswitch -VMHost $i.FQDN -Name vSwitch0
new-virtualportgroup -name $i.NestedPG1 -VirtualSwitch $hostvSwitch -VLanId $i.NestedPG1VLAN -Confirm:$false
get-virtualportgroup -VMHost $i.FQDN -name $i.NestedPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0

write-host "Configuring vmnic0 active"$i.NestedPG2"port group on"$i.Name -ForegroundColor $cc
new-virtualportgroup -name $i.NestedPG2 -VirtualSwitch $hostvSwitch -VLanId $i.NestedPG2VLAN -Confirm:$false
get-virtualportgroup -VMHost $i.FQDN -name $i.NestedPG2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0

write-host "Configuring vmnic0 active"$i.NestedPG3"port group on"$i.Name -ForegroundColor $cc
new-virtualportgroup -name $i.NestedPG3 -VirtualSwitch $hostvSwitch -VLanId $i.NestedPG3VLAN -Confirm:$false
get-virtualportgroup -VMHost $i.FQDN -name $i.NestedPG3 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0

write-host "Configuring vmnic0 active"$i.NestedPG4"port group on"$i.Name -ForegroundColor $cc
new-virtualportgroup -name $i.NestedPG4 -VirtualSwitch $hostvSwitch -VLanId $i.NestedPG4VLAN -Confirm:$false
get-virtualportgroup -VMHost $i.FQDN -name $i.NestedPG4 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0

}


write-host "Creating new Distributed Switch on $($physHost[0].vCenterFQDN)" -ForegroundColor $cc
new-vdswitch -Name $physHost[0].vdSwitch -server $physHost[0].vCenterFQDN -Location "NUCLAB" -mtu 9000 -NumUplinkPorts 2 -version 7.0.3


write-host "Making port 1 active and port 2 standby on a new VSAN port group" -ForegroundColor $cc
New-VDPortgroup -Name $i.VSANPG -vdswitch $physHost[0].vdSwitch -server $physHost[0].vCenterFQDN

get-vdswitch -Name $physHost[0].vdSwitch | get-vdportgroup $i.VSANPG | get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink1" -StandbyUplinkPort "dvUplink2"

write-host "Making port 2 active and port 1 standby on a new VMotion port group" -ForegroundColor $cc
New-VDPortgroup -Name $i.VMotionPG1 -vdswitch $physHost[0].vdSwitch -server $physHost[0].vCenterFQDN

get-vdswitch -Name $physHost[0].vdSwitch | get-vdportgroup $i.VMotionPG1 | get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink2" -StandbyUplinkPort "dvUplink1"

foreach ($i in $hosts){
write-host "Adding host $($i.Name) to Distributed Switch"  -ForegroundColor $cc
get-vdswitch -Name $physHost[0].vdSwitch | Add-VDSwitchVMHost -VMHost "$($i.FQDN)"
$vmhostNetworkAdapter1 = get-vmhost $($i.FQDN) | get-vmhostnetworkadapter -Physical -Name vmnic1
$vmhostNetworkAdapter2 = get-vmhost $($i.FQDN) | get-vmhostnetworkadapter -Physical -Name vmnic2
write-host "Adding first host adapter on $($i.Name) to Distributed Switch"  -ForegroundColor $cc
get-vdswitch -Name $physHost[0].vdSwitch | add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostnetworkadapter1 -confirm:$false
start-sleep -seconds 5
new-vmhostnetworkadapter -VMHost $i.FQDN -PortGroup $i.VSANPG -virtualSwitch $physHost[0].vdSwitch -IP $i.VSANvmkIP -SubnetMask 255.255.255.0 -VsanTrafficEnabled:$true
write-host "Adding second host adapter on $($i.Name) to Distributed Switch"  -ForegroundColor $cc
get-vdswitch -Name $physHost[0].vdSwitch | add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostnetworkadapter2 -confirm:$false
start-sleep -seconds 5
new-vmhostnetworkadapter -VMHost $i.FQDN -PortGroup $i.VMotionPG1 -virtualSwitch $physHost[0].vdSwitch -IP $i.VMotion1vmkIP -SubnetMask 255.255.255.0 -VMotionEnabled:$true
}

get-cluster $physHost[0].vsanCluster | set-cluster -VsanEnabled:$true -confirm:$false
get-cluster $physHost[0].vsanCluster | set-vsanclusterconfiguration -SpaceEfficiencyEnabled:$true -SpaceCompressionEnabled:$true

foreach ($i in $hosts){
new-vsandiskgroup -VMHost $i.FQDN -SsdCanonicalName mpx.vmhba0:C0:T1:L0 -DataDiskCanonicalName mpx.vmhba0:C0:T2:L0 -Confirm:$false
}
#}

write-host "Enabling HA on vSAN8 cluster" -ForegroundColor $cc
#write-host "Enabling DRS and HA on vSAN8 cluster" -ForegroundColor $cc

#get-cluster $physHost[0].vsanCluster | set-cluster -DrsEnabled $false -HAEnabled $false -confirm:$false
get-cluster $physHost[0].vsanCluster | set-cluster -DrsEnabled $true -HAEnabled $true -confirm:$false

#new-resourcepool -Location $physHost[0].vsanCluster -Name 1-Gold -CpuLimitMhz 2000 -NumCpuShares 4000
#new-resourcepool -Location $physHost[0].vsanCluster -Name 2-Silver -CpuLimitMhz 1000 -NumCpuShares 2000
#new-resourcepool -Location $physHost[0].vsanCluster -Name 3-Bronze -CpuLimitMhz 500 -NumCpuShares 1000

#for ($i=1; $i -le 2; $i++)
#{
get-contentlibraryitem -Name TEMP01-CL | new-vm -Name TEST01 -ResourcePool VSANCL1 -datastore vsanDatastore -confirm:$false
start-vm TEST01 -confirm:$false
#}

#for ($i=1; $i -le 2; $i++)
#{
#  get-contentlibraryitem -Name $DeployTemplate | new-vm -Name XPSILVER$i -location UserFolders -memoryMB 256 -resourcePool 2-Silver -datastore vsanDatastore -confirm:$false
#  start-vm XPSILVER$i -confirm:$false
#}

#for ($i=1; $i -le 2; $i++)
#{
#  get-contentlibraryitem -Name $DeployTemplate | new-vm -Name XPBRONZE$i -location UserFolders -memoryMB 256 -resourcePool 3-Bronze -datastore vsanDatastore -confirm:$false
#  #set-vm UBUBRONZE$i -OSCustomizationSpec $LinuxCustSpecName -confirm:$false
#  start-vm XPBRONZE$i -confirm:$false
#}

$stopWatch.Stop()
$stopWatch

disconnect-viserver * -confirm:$false
