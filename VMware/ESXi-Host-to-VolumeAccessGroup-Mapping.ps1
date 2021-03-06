<#
This script provides ability to report on which VolumeAccessGroup an ESXi host is associated.  This can be extremely helpful since an iSCSI initiator can only belong to a single volume access group.
To add initiators to a volume access group use Add-SFInitiatorToVolumeAccessGroup.
To remove initiators from a volume access group use Remove-SFInitiatorFromVolumeAccessGroup
#>

# Check for PowerCLI snap-in (Optional)

#if((Get-PSSnapin VMware.VimAutomation.Core) -eq $null){
#	add-pssnapin VMware.VimAutomation.Core -ErrorAction:SilentlyContinue
#	}

# Check for vCenter Server connection

if($global:DefaultVIServer -eq $null){
	Write-Host "You do not have an active vCenter Server connection." -ForegroundColor Yellow
	$vcenter = Read-Host "vCenter Server name"
	$vccred = Get-Credential -Message "Please enter your vCenter Credentials"
	Connect-VIserver $vcenter -credential $vccred
	}

# Check for SolidFire connection

if($SFConnection -eq $null){
	# Checks to ensure the connection information has been collected using Connect-SFCluster
	Write-Host "You do not have an active SolidFire Cluster connection." -ForegroundColor Yellow
	$cluster = Read-Host "Please provide your SolidFire Cluster IP or FQDN"
	$cred = Get-Credential -Message "Please enter your SolidFire cluster credentials"
	Connect-SFCluster -Target $cluster -Credential $cred
	}

# Get list of ESXi host software initiator IQNs

$IQNs = Get-VMHost | Select name,@{n="IQN";e={$_.ExtensionData.Config.StorageDevice.HostBusAdapter.IscsiName}}

$result = @()
foreach($vmhost in $IQNs){
	foreach($iqn in $vmhost.IQN){ 
        $vag = Get-SFVolumeAccessGroup | Where{$_.Initiators -match $iqn}
	 
	     $a = New-Object System.Object
	     $a | Add-Member -Type NoteProperty -Name VMhost -Value $vmhost.Name
	     $a | Add-Member -Type NoteProperty -Name VolumeAccessGroup -Value $vag.VolumeAccessGroupName
	     $a | Add-Member -Type NoteProperty -Name IQN -Value $vmhost.IQN

$result += $a
}
}
Write-Output $result