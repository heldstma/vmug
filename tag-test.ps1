disconnect-viserver * -confirm:$false
connect-viserver vcen1.vmatt.net

$tagassign = get-tagassignment | where-object {$_.Tag -Match 'Snapshots/ProtectSnapshots'}
$all = get-vm
[System.Collections.ArrayList]$list = @($all.Name)
foreach ($i in $tagassign.entity)
    {
        $list.Remove($i.Name)
    }

$vmsnapshots = get-vm $list | Get-Snapshot

foreach ($i in $vmsnapshots)
{    
    $currentDate = Get-Date
    $snapAge = ($currentDate - $i.Created)
    if ($snapAge.TotalDays -gt 7) {$i | remove-snapshot -confirm:$false}
}


foreach ($i in $list) {
    $snapCount = get-vm $i | get-snapshot

    #write-host $i "contains" $($snapCount.count) "snapshots"
    #if ($i -ne $tagassign.Entity)
    #{
    #    if ($tagassign.Tag.Name -notLike "ProtectSnapshots")
    #    {
    #        $snapInfo=@()
    #        $snapAge=@()
    #        $snapInfo = get-vm $vm | Get-Snapshot
    #        $currentDate = Get-Date
    #        $snapAge = ($currentDate - $snapInfo.Created)
    #        get-vm $i | get-snapshot | remove-snapshot -confirm:$false
    #        write-host $snapAge.TotalDays
    #
    #   }
    
    } 
    




************************
    $snapInfo=@()
    $snapAge=@()
    $vm=@()
    $snapCount=@()

    $tagassign = get-tagassignment
    $vm = get-vm test11
    $snapCount = get-vm $vm | get-snapshot
    write-host $vm "contains" $($snapCount.count) "snapshots"
    if ($vm.Name -ne $tagassign.Entity.Name)
    {
        if ($tagassign.Tag.Name -notLike "ProtectSnapshots")
        {
            
            $snapInfo = get-vm $vm | Get-Snapshot
            $currentDate = Get-Date
            $snapAge = ($currentDate - $snapInfo.Created)
            get-vm $vm | get-snapshot | remove-snapshot -confirm:$false
            write-host $snapAge.TotalDays

        }
    
    } 
    

******************
$tagassign = Get-TagAssignment
$all = get-vm
[System.Collections.ArrayList]$list = @($all.Name)
foreach ($i in $tagassign.entity)
    {
        $list.Remove($i.Name)
    }