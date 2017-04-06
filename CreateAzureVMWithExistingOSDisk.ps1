[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$ResourceGroupName,
	
    [Parameter(Mandatory=$True)]
    [string]$Location,

    [Parameter(Mandatory=$True)]
    [string]$VNetName,

    [Parameter(Mandatory=$True)]
    [string]$SubnetName,

    [Parameter(Mandatory=$True)]
    [string]$IPName,

    [Parameter(Mandatory=$True)]
    [string]$NICName,

    [Parameter(Mandatory=$True)]
    [string]$NSGName,

    [Parameter(Mandatory=$True)]
    [string]$VMName,

    [Parameter(Mandatory=$True)]
    [string]$OSDiskUri
)

$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 10.0.0.0/24
$vnet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet
$pip = New-AzureRmPublicIpAddress -Name $IPName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod Dynamic

$nic = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name myRdpRule -Description "Allow RDP" -Access Allow -Protocol Tcp -Direction Inbound -Priority 110 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $NSGName -SecurityRules $rdpRule

$vmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize "Standard_DS2_V2"
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id

$osDiskName = $VMName + "osDisk" 
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $OSDiskUri -CreateOption attach -Windows
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $vm