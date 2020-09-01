$Servers = 'TASDC01','TASWD01'

$VendorUefi = 'PXEClient (UEFI x64)'
$VendorBios = 'PXEClient (BIOS x86 & x64)'

$DescriptionUefi = 'PXEClient:Arch:00007'
$DescriptionBios = 'PXEClient:Arch:00000'

$DataUefi = '0x505845436c69656e743a417263683a3030303037'
$DataBios = '0x505845436c69656e743a417263683a3030303030'

$PolicyDescriptionUefi = 'Delivers the correct bootfile for (UEFI x64)'
$PolicyDescriptionBios = 'Delivers the correct bootfile for (BIOS ALL)'

$BootServer = "taswd01.internal.taipa.school.nz"
$BootUefi = 'boot\x64\wdsmgfw.efi'
$BootBios = 'boot\x86\wdsnbp.com'

$Scopes = Get-DhcpServerv4Scope

Foreach($server in $Servers){

    Set-DhcpServerv4OptionValue -OptionId 066 -Value $BootServer -ComputerName $Server    
    add-DhcpServerv4Class -Name $VendorUefi -Type Vendor -Description $DescriptionUefi -Data $DataUefi -ComputerName $server
    add-DhcpServerv4Class -Name $VendorBios -Type Vendor -Description $DescriptionBios -Data $DataBios -ComputerName $server

    Foreach($Scope in $Scopes){

        Add-DhcpServerv4Policy -ScopeId $Scope.ScopeId -ComputerName $Server -Name $VendorUefi -Description $PolicyDescriptionUefi -ProcessingOrder 1 -Condition Or -VendorClass EQ, 'PXEClient (UEFI x64)*'
        Add-DhcpServerv4Policy -ScopeId $Scope.ScopeId -ComputerName $Server -Name $VendorBios -Description $PolicyDescriptionBios -ProcessingOrder 2 -Condition Or -VendorClass EQ, 'PXEClient (BIOS x86 & x64)*'
        Set-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId -ComputerName $Server -PolicyName $VendorUefi -OptionId 067 -Value $BootUefi
        Set-DhcpServerv4OptionValue -ScopeId $Scope.ScopeId -ComputerName $Server -PolicyName $VendorBios -OptionId 067 -Value $BootBios

    }

}