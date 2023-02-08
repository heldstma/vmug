#https://www.virten.net/vmware/powershell-ovf-helper/vmware-esxi-virtual-appliance-8-0/
#https://communities.vmware.com/t5/VMware-PowerCLI-Discussions/How-to-set-Hardware-virtualization-gt-expose/td-p/1758017

disconnect-viserver * -confirm:$false
set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -confirm:$false
set-powercliconfiguration -InvalidCertificateAction Ignore -confirm:$false
$physHost = @()
$physHost = import-csv -path h:\scripts\nestedESXi80\physhost.csv
$hosts = @()
$hosts = import-csv -path h:\scripts\nestedESXi80\nested.csv
$cc = "Yellow"
$spec1 = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec1.nestedHVEnabled = $true
$stopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
$ISOdatastore = "INTERNAL-SAS-DATASTORE1"

#VMotionType Definitions
#Single = Uses vmnic3 as active and vmnic2 as standby - non routed
#Dual = uses vmnic0/vmnic1 active/standby on port 1, vmnic1/vmnic0 as active/standby on port 2
$VMotionType = "Single"

sleep 5
write-host "Starting Script Timer" -ForegroundColor $cc
$stopWatch.Start()
write-host "Connecting to $($physHost[0].FQDN)" -ForegroundColor $cc

connect-viserver $physHost[0].FQDN -user root -password $physHost[0].HostRootPwd

write-host "Deleting VM Network port group if it exists on $($physHost[0].FQDN)" -ForegroundColor $cc
$Exists = get-virtualportgroup -name "VM Network" -ErrorAction SilentlyContinue
If ($Exists){
  get-virtualportgroup -Name "VM Network" | remove-virtualportgroup -Confirm:$false
}
write-host "Adding VMNICs to $($physHost[0].FQDN)" -ForegroundColor $cc
get-virtualswitch -name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name vmnic1,vmnic2,vmnic3) -confirm:$false
#get-virtualswitch -name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name "vmnic2") -confirm:$false
#get-virtualswitch -name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name "vmnic3") -confirm:$false


sleep 5

## 

write-host "Creating new port group $($physHost[0].hostpg1) VM Network port group and tagging it VLAN 4095" -ForegroundColor $cc
new-virtualportgroup -name $physHost[0].hostpg1 -VirtualSwitch vSwitch0 -Server $physHost[0].FQDN -VLanId 4095 -Confirm:$false

write-host "Making vmnic0 active and vmnic1,2,3 unused for $($physHost[0].hostpg1)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0
get-virtualportgroup -name $physHost[0].hostpg1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic1,vmnic2,vmnic3

write-host "Enabling MAC Changes and Promiscuous Mode for $($physHost[0].hostpg1)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg1 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -AllowPromiscuous $true


write-host "Creating new port group $($physHost[0].hostpg2) VM Network port group and tagging it VLAN 4095" -ForegroundColor $cc
new-virtualportgroup -name $physHost[0].hostpg2 -VirtualSwitch vSwitch0 -Server $physHost[0].FQDN -VLanId 4095 -Confirm:$false

write-host "Making vmnic1 active and vmnic0,2,3 unused for $($physHost[0].hostpg2)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic1
get-virtualportgroup -name $physHost[0].hostpg2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic0,vmnic2,vmnic3

write-host "Enabling MAC Changes and Promiscuous Mode for $($physHost[0].hostpg2)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg2 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -AllowPromiscuous $true




write-host "Creating new port group $($physHost[0].hostpg3) VM Network port group and tagging it VLAN 4095" -ForegroundColor $cc
new-virtualportgroup -name $physHost[0].hostpg3 -VirtualSwitch vSwitch0 -Server $physHost[0].FQDN -VLanId 4095 -Confirm:$false

write-host "Making vmnic2 active and vmnic0,1,3 unused for $($physHost[0].hostpg3)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg3 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic2
get-virtualportgroup -name $physHost[0].hostpg3 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic0,vmnic1,vmnic3

write-host "Enabling MAC Changes and Promiscuous Mode for $($physHost[0].hostpg3)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg3 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -AllowPromiscuous $true



write-host "Creating new port group $($physHost[0].hostpg4) VM Network port group and tagging it VLAN 4095" -ForegroundColor $cc
new-virtualportgroup -name $physHost[0].hostpg4 -VirtualSwitch vSwitch0 -Server $physHost[0].FQDN -VLanId 4095 -Confirm:$false

write-host "Making vmnic3 active and vmnic0,1,2 unused for $($physHost[0].hostpg4)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg4 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic3
get-virtualportgroup -name $physHost[0].hostpg4 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic0,vmnic1,vmnic2

write-host "Enabling MAC Changes and Promiscuous Mode for $($physHost[0].hostpg4)" -ForegroundColor $cc
get-virtualportgroup -name $physHost[0].hostpg4 | Get-SecurityPolicy | Set-SecurityPolicy -MacChanges $true -AllowPromiscuous $true


sleep 5

$num = 0..($hosts.count-1)
foreach ($item in $num){
write-Host "Building new $($hosts[$item].Name) VM" -ForegroundColor $cc
write-Host "$($hosts[$item].Name) VM being configured with $($hosts[$item].CPUtotal) vCPU, $($hosts[$item].memory) GB Memory" -ForegroundColor $cc
new-vm -Name $hosts[$item].Name -Datastore $physHost[0].DatastoreSAS -GuestId "vmkernel65Guest" -NumCPU $hosts[$item].CPUtotal -CoresPerSocket $hosts[$item].corespersocket -MemoryGB $hosts[$item].memory -HardwareVersion vmx-13 -DiskGB $hosts[$item].bootGB -CD
New-HardDisk -VM $hosts[$item].Name -CapacityGB $hosts[$item].cacheGB -Datastore $physHost[0].datastoreSSD -StorageFormat Thick
New-HardDisk -VM $hosts[$item].Name -CapacityGB $hosts[$item].capacityGB -Datastore $physHost[0].datastoreSAS -StorageFormat Thick
New-NetworkAdapter -VM $hosts[$item].Name -NetworkName $physHost[0].hostpg2 -Type Vmxnet3 -StartConnected
New-NetworkAdapter -VM $hosts[$item].Name -NetworkName $physHost[0].hostpg3 -Type Vmxnet3 -StartConnected
New-NetworkAdapter -VM $hosts[$item].Name -NetworkName $physHost[0].hostpg4 -Type Vmxnet3 -StartConnected

write-Host "Mounting Custom ESXi installer on $($hosts[$item].FQDN) VM" -ForegroundColor $cc
get-vm $hosts[$item].Name | get-cddrive | set-cddrive -isopath "[$ISOdatastore] ISO/$($hosts[$item].ESXiISOName)" -StartConnected $true -confirm:$false

$vm = Get-VM -Name $hosts[$item].Name 
write-Host "Configuring $($hosts[$item].FQDN) for nested virtualization" -ForegroundColor $cc
$vm.ExtensionData.ReconfigVM($spec1)
write-Host "Powering on $($hosts[$item].FQDN) VM" -ForegroundColor $cc
start-vm $hosts[$item].Name
start-sleep -seconds 15
}
write-Host "VM's are created and powered on.  ESXi is installing -- waiting for hosts to come up for customization." -ForegroundColor $cc

disconnect-viserver $physHost[0].FQDN -confirm:$false

$num = 0..($hosts.count-1)
foreach ($item in $num){
 
do {
  Write-Host "waiting for $($hosts[$item].FQDN) to come up on HTTPS..." -ForegroundColor $cc
  sleep 3      
} until(Test-NetConnection $hosts[$item].FQDN -Port 443 | ? { $_.TcpTestSucceeded } )


sleep 30
write-host "Connecting to $($hosts[$item].Name)" -ForegroundColor $cc
connect-viserver $hosts[$item].FQDN -user root -password $hosts[$item].HostRootPwd
write-host "Deleting VM Network port group if it exists on $($hosts[$item].Name)" -ForegroundColor $cc
get-virtualportgroup -Name "VM Network" | remove-virtualportgroup -Confirm:$false

write-host "Adding vmnic1,2,3 to vSwitch0 on $($hosts[$item].Name)" -ForegroundColor $cc
get-virtualswitch -name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name "vmnic1") -confirm:$false
get-virtualswitch -name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name "vmnic2") -confirm:$false
get-virtualswitch -name vSwitch0 | Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Physical -Name "vmnic3") -confirm:$false

write-host "Configuring vmnic0,1 active and vmnic2,3 unused for $($hosts[$item].NestedPG1) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].NestedPG1 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].NestedPG1VLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].NestedPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0,vmnic1
get-virtualportgroup -name $hosts[$item].NestedPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic2,vmnic3

write-host "Configuring vmnic0,1 active and vmnic2,3 unused for $($hosts[$item].NestedPG2) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].NestedPG2 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].NestedPG2VLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].NestedPG2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0,vmnic1
get-virtualportgroup -name $hosts[$item].NestedPG2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic2,vmnic3

write-host "Configuring vmnic0,1 active and vmnic2,3 unused for $($hosts[$item].NestedPG3) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].NestedPG3 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].NestedPG3VLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].NestedPG3 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0,vmnic1
get-virtualportgroup -name $hosts[$item].NestedPG3 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic2,vmnic3

write-host "Configuring vmnic0,1 active and vmnic2,3 unused for $($hosts[$item].NestedPG4) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].NestedPG4 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].NestedPG4VLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].NestedPG4 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0,vmnic1
get-virtualportgroup -name $hosts[$item].NestedPG4 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic2,vmnic3

write-host "Configuring vmnic2 active, vmnic3 standby and vmnic0,1 unused for $($hosts[$item].VSANPG) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].VSANPG -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].VSANVLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].VSANPG | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic0,vmnic1
get-virtualportgroup -name $hosts[$item].VSANPG | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic2
get-virtualportgroup -name $hosts[$item].VSANPG | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicStandby vmnic3
write-host "Setting IP $($hosts[$item].VSANvmkIP) for $($hosts[$item].VSANPG) VMKernel" -ForegroundColor $cc
new-vmhostnetworkadapter -VMHost $hosts[$item].FQDN -PortGroup $hosts[$item].VSANPG -virtualSwitch "vSwitch0" -IP $hosts[$item].VSANvmkIP -SubnetMask 255.255.255.0 -VsanTrafficEnabled:$true

if ($vmotiontype -eq "Single")
{
write-host "Configuring vmnic3 active, vmnic2 standby and vmnic0,1 unused for $($hosts[$item].VMotionPG1) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].VMotionPG1 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].VMotionVLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].VMotionPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic3
get-virtualportgroup -name $hosts[$item].VMotionPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicStandby vmnic2
get-virtualportgroup -name $hosts[$item].VMotionPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic0,vmnic1
write-host "Setting IP $($hosts[$item].VMotion1vmkIP) for $($hosts[$item].VMotionPG1) VMKernel" -ForegroundColor $cc
new-vmhostnetworkadapter -VMHost $hosts[$item].FQDN -PortGroup $hosts[$item].VMotionPG1 -virtualSwitch "vSwitch0" -IP $hosts[$item].VMotion1vmkIP -SubnetMask 255.255.255.0 -VMotionEnabled:$true
}

if ($vmotiontype -eq "Dual")
{
write-host "Configuring vmnic0 active, vmnic1 standby and vmnic2,3 unused for $($hosts[$item].VMotionPG1) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].VMotionPG1 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].VMotionVLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].VMotionPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic0
get-virtualportgroup -name $hosts[$item].VMotionPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicStandby vmnic1
get-virtualportgroup -name $hosts[$item].VMotionPG1 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic2,vmnic3
write-host "Setting IP $($hosts[$item].VMotion1vmkIP) for $($hosts[$item].VMotionPG1) VMKernel" -ForegroundColor $cc
new-vmhostnetworkadapter -VMHost $hosts[$item].FQDN -PortGroup $hosts[$item].VMotionPG1 -virtualSwitch "vSwitch0" -IP $hosts[$item].VMotion1vmkIP -SubnetMask 255.255.255.0 -VMotionEnabled:$true

write-host "Configuring vmnic1 active, vmnic0 standby and vmnic2,3 unused for $($hosts[$item].VMotionPG2) port group on $($hosts[$item].Name)" -ForegroundColor $cc
new-virtualportgroup -name $hosts[$item].VMotionPG2 -VirtualSwitch vSwitch0 -Server $hosts[$item].FQDN -VLanId $hosts[$item].VMotionVLAN -Confirm:$false
get-virtualportgroup -name $hosts[$item].VMotionPG2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicStandby vmnic0
get-virtualportgroup -name $hosts[$item].VMotionPG2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicActive vmnic1
get-virtualportgroup -name $hosts[$item].VMotionPG2 | get-nicteamingpolicy | set-nicteamingpolicy -MakeNicUnused vmnic2,vmnic3
write-host "Setting IP $($hosts[$item].VMotion2vmkIP) for $($hosts[$item].VMotionPG2) VMKernel" -ForegroundColor $cc
new-vmhostnetworkadapter -VMHost $hosts[$item].FQDN -PortGroup $hosts[$item].VMotionPG2 -virtualSwitch "vSwitch0" -IP $hosts[$item].VMotion2vmkIP -SubnetMask 255.255.255.0 -VMotionEnabled:$true
disconnect-viserver $hosts[$item].FQDN -confirm:$false
}
}

write-host "Installing vCenter Server on vcen2.vmatt.net" -ForegroundColor $cc

h:
cd H:\scripts\nestedESXi80\VCSA\vcsa-cli-installer\win32
.\vcsa-deploy.exe install --accept-eula --acknowledge-ceip --no-esx-ssl-verify H:\scripts\nestedESXi80\VCSA\vcsa-cli-installer\win32\vCSA_with_cluster_on_ESXi.json

sleep 30

write-host "Connecting to vCenter Server on vcen2.vmatt.net" -ForegroundColor $cc
connect-viserver vcen2.vmatt.net -user administrator@vsphere.local -password $physHost[0].vCenterPwd

#Add array hosts 1,2,3 to cluster (skip host 0 as it is already in the array)
$num = 1..($hosts.count-1)
foreach ($item in $num){
#Join remaining hosts to vCenter and create a disk group for vSAN
write-host "Adding host $($hosts[$item].FQDN) to vCenter Server on vcen2.vmatt.net" -ForegroundColor $cc
add-vmhost -Name $hosts[$item].FQDN -Location $physHost[0].vsanCluster -user root -Password $hosts[$item].HostRootPwd -Force
new-vsandiskgroup -VMHost $hosts[$item].FQDN -SsdCanonicalName mpx.vmhba0:C0:T1:L0 -DataDiskCanonicalName mpx.vmhba0:C0:T2:L0 -Confirm:$false
}

write-host "Enabling DRS and HA on vSAN8 cluster" -ForegroundColor $cc
get-cluster vSAN8 | set-cluster -DrsEnabled $true -HAEnabled $true -confirm:$false

#Figure out nested loop to end after ESXi hosts are built and before config
#https://docs.vmware.com/en/VMware-vSphere/8.0/vsphere-vcenter-installation/GUID-15F4F48B-44D9-4E3C-B9CF-5FFC71515F71.html
#.\vcsa-deploy.exe install --accept-eula --acknowledge-ceip --no-esx-ssl-verify H:\scripts\nestedESXi80\VCSA\vcsa-cli-installer\win32\vCSA_with_cluster_on_ESXi.json

#PS H:\scripts\nestedESXi80\VCSA\vcsa-cli-installer\win32> .\vcsa-deploy.exe install --accept-eula --acknowledge-ceip --no-esx-ssl-verify H:\scripts\nestedESXi80\VCSA\vcsa-cli-installer\win32\vCSA_with_cluster_on_ESXi.json
#https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.esxi.install.doc/GUID-C03EADEA-A192-4AB4-9B71-9256A9CB1F9C.html <-- Create an installer ISO image with a custom installation or upgrade script
#https://kb.vmware.com/s/article/2004582 - ks.cfg options
#
#First, understand all of the steps required
#Second, go through the process manually and familiarize yourself with the steps
#Next, group the steps into sections that you can automate - low hanging fruit first
#  It might be a good idea to automate with simple commands - don't worry about looping and making your script shorter
#  Once you have the seconds down, look at improving by incorporating arrays and loops



write-host "Creating new Distributed Switch on vcen2.vmatt.net" -ForegroundColor $cc
new-vdswitch -Name "VDS_VSAN8" -server "vcen2.vmatt.net" -Location "NestedDC" -mtu 9000 -NumUplinkPorts 2 -version 7.0.3
write-host "Creating new Distributed Switch Port Group for VSAN" -ForegroundColor $cc
New-VDPortgroup -Name "VLAN0100_VSAN" -vdswitch "VDS_VSAN8" -VlanID 100 -server "vcen2.vmatt.net"
write-host "Making port 1 active and port 2 standby on new VSAN port group" -ForegroundColor $cc
get-VDSwitch -Name "VDS_VSAN8" | Get-VDUplinkTeamingPolicy | Set-VDUplinkTeamingPolicy -ActiveUplinkPort "dvUplink1" -StandbyUplinkPort "dvUplink2"

$num = 0..($hosts.count-1)
foreach ($item in $num){
  write-host "Adding host $($hosts[$item].Name) to Distributed Switch"  -ForegroundColor $cc
  get-vdswitch -Name "VDS_VSAN8" | Add-VDSwitchVMHost -VMHost "$($hosts[$item].FQDN)"
  $vmhostNetworkAdapter2 = get-vmhost $($hosts[$item].FQDN) | get-vmhostnetworkadapter -Physical -Name vmnic2
  $vmhostNetworkAdapter1 = get-vmhost $($hosts[$item].FQDN) | get-vmhostnetworkadapter -Physical -Name vmnic3
  write-host "Adding first host adapter on $($hosts[$item].Name) to Distributed Switch"  -ForegroundColor $cc
  get-vdswitch -Name "VDS_VSAN8" | add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostnetworkadapter2 -confirm:$false
  start-sleep -seconds 15
  $virtualNic = Get-VMHostNetworkAdapter -VMHost $($hosts[$item].FQDN) -Name "vmk1"
  write-host "Migrating VSAN VMKernel Adapter on $($hosts[$item].Name) to Distributed Switch"  -ForegroundColor $cc
  Set-VMHostNetworkAdapter -PortGroup VLAN0100_VSAN -VirtualNic $virtualNIC -confirm:$false
  write-host "Adding second host adapter on $($hosts[$item].Name) to Distributed Switch"  -ForegroundColor $cc
  get-vdswitch -Name "VDS_VSAN8" | add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostnetworkadapter1 -confirm:$false
  start-sleep -seconds 15
  
}
test-VsanNetworkPerformance -Cluster vSAN8

$stopWatch.Stop()
$stopWatch

Remove-Variable * -ErrorAction SilentlyContinue