$loc = 'South India'
$AzureImage = Get-AzureRmVMImage -Location 'South India' -PublisherName 'MicrosoftWindowsServer' -Offer "WindowsServer" -Skus "2012-R2-Datacenter-smalldisk"
#Create a VM
$rgname = 'RG-SCUSA'
$vmsize = 'Standard_A2';
$vmname = 'testvmARM';
# Setup Storage
$stoname = 'savtechsalrsscus';
$stotype = 'Standard_LRS';

#Create a v2 Storage Account on ARM
#New-AzureStorageAccount -ResourceGroupName $rgname -Name $stoname -Location $loc -Type $stotype$stoaccount = Get-AzureRmStorageAccount -ResourceGroupName $rgname -Name $stoname;

# Create VM Object
$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize

 Setup Networking
$subnet = New-AzureRmVirtualNetworkSubnetConfig -Name ('subnet' + $rgname) -AddressPrefix "10.0.0.0/24"
$vnet = New-AzureRmVirtualNetwork -Force -Name ('vnet' + $rgname) -ResourceGroupName $rgname -Location $loc `
    -AddressPrefix "10.0.0.0/16" -DnsServer "10.1.1.1" -Subnet $subnet
#$vnet = Get-AzureRmVirtualNetwork -Name ('vnet' + $rgname) -ResourceGroupName $rgname
$subnetId = $vnet.Subnets[0].Id

$pip = New-AzureRmPublicIpAddress -ResourceGroupName $rgname -Name "vip1" `
    -Location $loc -AllocationMethod Dynamic -DomainNameLabel $vmname.ToLower()

$nic = New-AzureRmNetworkInterface -Force -Name ('nic' + $vmname) -ResourceGroupName $rgname `
    -Location $loc -SubnetId $subnetId -PublicIpAddressId $pip.Id
$nic = Get-AzureRmNetworkInterface -Name ('nic' + $vmname) -ResourceGroupName $rgname

# Add NIC to VM
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

$osDiskName = $vmname+'_osDisk'
$osDiskCaching = 'ReadWrite'
$osDiskVhdUri = "https://$stoname.blob.core.windows.net/vhds/"+$vmname+"_os.vhd"

# Setup OS & Image
$user = "localadmin"
$password = 'Pa55word5'
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmname -Credential $cred
$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName $AzureImage.PublisherName -Offer $AzureImage.Offer `
    -Skus $AzureImage.Skus -Version $AzureImage.Version
$vm = Set-AzureRmVMOSDisk -VM $vm -VhdUri $osDiskVhdUri -name $osDiskName -CreateOption fromImage -Caching $osDiskCaching

# Create Virtual Machine
New-AzureRmVM -ResourceGroupName $rgname -Location $loc -VM $vm 
