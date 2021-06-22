<#

Automated Microsoft Deployment Toolkit Installer Function Set
Scripter: Rhys Jeffery
Email: Rhysj@neweratech.co.nz
Date: 29/03/21

Version: 1.2
Download: https://neweraitnz.sharepoint.com/:f:/s/tetaitokerauteam/Eq90-mWR-aFOuWqc8Urd6Z8BDfmdmbs_8LsT1FAuuXZxjw?e=DFLyQO

 This script module contails all the functions used in the main setup.ps1

 This Module contains low level comments for users new to powershell, however this won't contain much hand holding

#>


Function Call-Action {
    param([string] $Message, [string] $ExtraMessage)

    # Function to prompt for continue or abort, breaks out of script if user aborts.
    # Supports option extra message

        Write-Warning "$message"
        if($extraMessage -ne $null){Write-Output $extraMessage}

        Write-Output "Press c to continue, press a to abort and exit script"
        $action = Read-Host -Prompt "Enter Your selection and press enter!"

        switch ($action.ToLower())
        { "c"{continue} ;  "a"{Break Script}

            Default {
                Write-Warning "Invalid selection" ;  Call-Action $message
                }
        }
}

Function Install-MDT {

    # Installs MDT

    Write-Warning "Installing MDT and dependencies"
     if((Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | where-object {$_.DisplayName -like "*Microsoft Deployment Toolkit*"}) -ne $null){Write-Warning "MDT Already Installed, check version, manually re-install if needed"}
    else
    {
        msiexec /qb /i "$PSScriptRoot\Installers\MicrosoftDeploymentToolkit_x64.msi" | Out-Null
        if(!(Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | where-object {$_.DisplayName -like "*Microsoft Deployment Toolkit*"})){Write-Warning "MDT is not installed, please manually check!"}
    }

}

Function Install-ADK-WinPE {

    # Installs ADK, then WinPE and finally installs patch for ADK 2004

    Write-Warning "Installing ADK, please wait."
        try{Start-Process -Wait "$PSScriptRoot\Installers\ADKOffline\adksetup.exe" '"/quiet" "/features" "OptionId.DeploymentTools"'}
            catch{Call-Action -Message "Failed to install Windows ADK, please check manually" -ExtraMessage $Error[0].Exception.Message}         

    Write-Warning "Installing WinPE, please wait."
        try{Start-Process -Wait "$PSScriptRoot\Installers\WinPEoffline\adkwinpesetup.exe" '"/quiet"'}
            catch{Call-Action -Message "Failed to install Windows WinPE, please check manually" -ExtraMessage $Error[0].Exception.Message}             

    Write-Warning "Patching ADK, please wait."
        try{
            Copy-Item -Path "$PSScriptRoot\Patches\BIOS\x86" -Destination "%ProgramFiles%\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x86" -Force -Recurse
            Copy-Item -Path "$PSScriptRoot\Patches\BIOS\x64" -Destination "%ProgramFiles%\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64" -Force -Recurse
            }
            catch{Call-Action -Message "Failed to patch ADK, please check manually" -ExtraMessage $Error[0].Exception.Message}

}

Function Install-WDS{

    Write-Warning "Installing and configuring WDS"
        if((Get-WindowsFeature "WDS").installed -eq $true){Call-Action "WDS Feature already installed, continue with configuration?"}
            else{Add-WindowsFeature WDS}
 
        try{
            wdsutil /initialize-server /reminst:D:\RemoteInstall /standalone | Out-Null
            wdsutil /set-server /answerclients:ALL | Out-Null
            WDSUTIL /Set-Server /Transport /EnableTftpVariableWindowExtension:Yes /TftpMaximumBlockSize:16784
        }
        catch{Call-Action -Message "Failed to invoke WDSUTIL, check WDS Feature is installed properly." -ExtraMessage $Error[0].Exception.Message}

}

Function Setup-MDT{
    param(
        [string] $mdtUser,
        [string] $mdtDomainName,
        [string] $mdtInstallLocation
        )

            #Creates folder for deployment share, sets it up as an share and then adds to MDT. Finally sets ACL for mdtUser to Modify

        [string] $deploymentShare = "$mdtInstallLocation"+"DeploymentShare"
        [string] $sharedDeploymentShare = "\\$env:COMPUTERNAME\DeploymentShare$"

        

        try{
                Write-Warning "Creating Deployment Share"
                if(!(Test-Path $deploymentShare)){New-Item $deploymentShare -ItemType Directory -ErrorAction STOP}

                Start-Sleep -Seconds 1 # Sleep for 1 second, slows script down but solves issues with ACL setting straight after creation

                $acl = Get-Acl $deploymentShare
                $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$mdtDomainName\$mdtUser","Modify","ContainerInherit, ObjectInherit","None","Allow")
                $acl.SetAccessRule($AccessRule)
                $acl | Set-Acl $deploymentShare
        }
            Catch{Call-Action -Message "Failed to create deployment share ($deploymentShare) please check script is running as admin" -ExtraMessage $Error[0].Exception.Message}

        # Importing MDT SnapIn
        try{Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction Stop}Catch{Call-Action -Message "Failed to import SnapIn, please check MDT is installed." -ExtraMessage $Error[0].Exception.Message}
        try{Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1" -ErrorAction Stop}Catch{Call-Action -Message "Failed to import MDT Module, please check MDT is installed." -ExtraMessage $Error[0].Exception.Message}    

        try{
                Write-Warning "Sharing Deployment Share"
                New-SmbShare -Name "DeploymentShare$" -Path "$deploymentShare" -FullAccess "Everyone"
                }
                Catch{Call-Action -Message "Failed to share deployment share ($deploymentShare) please check script is running as admin" -ExtraMessage $Error[0].Exception.Message}
        try{
                Write-Warning "Creating Deployment Share"        
                New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$deploymentShare" -Description "Default MDT Deployment Share" -NetworkPath "$sharedDeploymentShare" -ErrorAction Stop | add-MDTPersistentDrive 
            }catch{Call-Action -Message "Failed to create deployment share in MDT ($deploymentShare) please check script is running as admin" -ExtraMessage $Error[0].Exception.Message}
        
        try{
            Write-Warning "Patching MDT, please wait."
            Copy-Item -Path "$PSScriptRoot\Patches\BIOS\x86" -Destination "$deploymentShare\Tools\x86" -Force -Recurse
            Copy-Item -Path "$PSScriptRoot\Patches\BIOS\x64" -Destination "$deploymentShare\Tools\x64" -Force -Recurse
            }
            catch{Call-Action -Message "Failed to patch ADK, please check manually" -ExtraMessage $Error[0].Exception.Message}

}

Function Configure-MDT{
    param(
        [string] $mdtUser,
        [string] $mdtPassword,
        [string] $mdtInstallLocation,
        [string] $mdtDomainName,
        [string] $mdtSchoolName,
        [string] $mdtDefaultDevicePassword,
        [string] $mdtSchoolWebsite,
        [string] $mdtDefaultOU
        )

            # Copies over base MDT files, edits some. DomainsOuList.xml needs to be edited manually, the rest is filled out from vars passed to function

        [string] $deploymentShare = "$mdtInstallLocation"+"DeploymentShare"
        [string] $sharedDeploymentShare = "\\$env:COMPUTERNAME\DeploymentShare$"

        try{Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction Stop}Catch{Call-Action -Message "Failed to import SnapIn, please check MDT is installed." -ExtraMessage $Error[0].Exception.Message}
        try{Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1" -ErrorAction Stop}Catch{Call-Action -Message "Failed to import MDT Module, please check MDT is installed." -ExtraMessage $Error[0].Exception.Message}        

         try{Copy-Item "$PSScriptRoot\control\*" -Destination "$deploymentShare\control\" -Recurse -Force -ErrorAction Stop}
            Catch{Call-Action -Message "Failed to copy deployment share base files ($deploymentShare) please check script is running as admin" -ExtraMessage $Error[0].Exception.Message}

         $files = "$deploymentShare\Control\Bootstrap.ini","$deploymentShare\Control\CustomSettings.ini","$deploymentShare\Control\Settings.xml"

         foreach($file in $files){
            try{
                Write-Warning "Updating $file"

                (Get-Content $file ) -replace "SERVERWDS", $sharedDeploymentShare | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "MDTUSER",$mdtUser | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "MDTPASS",$mdtPassword | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "MDTDOMAIN",$mdtDomainName | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "SCHOOLNAME",$mdtSchoolName | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "DEPLOYMENTSERVER",$env:COMPUTERNAME | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "DEFAULTPASSWORD",$mdtDefaultDevicePassword | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "phyDEPLOYMENTSHARE",$deploymentShare | Set-Content $file -ErrorAction Stop
                (Get-Content $file ) -replace "DEFAULTOU",$mdtDefaultOU | Set-Content $file -ErrorAction Stop

            }Catch{Call-Action -Message "Failed to edit $file, please confirm file exists" -ExtraMessage $Error[0].Exception.Message}
         }

         $file = "$deploymentShare\Scripts\DeployWiz_ComputerName.vbs"

            try{
                Write-Warning "Patching $file"

                (Get-Content $file) | Foreach-Object {
                    $_ -replace 'Function AddItemToMachineObjectOUOpt\(item\)', 'Function AddItemToMachineObjectOUOpt(item,value)' `
                       -replace 'oOption.Value = item', 'oOption.Value = value' `
                       -replace 'AddItemToMachineObjectOUOpt oItem.text', 'AddItemToMachineObjectOUOpt oItem.text, oItem.Attributes.getNamedItem("value").value'
                    } | Set-Content $file

            }Catch{Call-Action -Message "Failed to edit $file, please confirm file exists" -ExtraMessage $Error[0].Exception.Message}

            # Creating Task Sequence and then importing template into created TS
            try{
                Write-Warning "Mounting Deployment Share"        
                New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "$deploymentShare" -Description "Default MDT Deployment Share" -ErrorAction SilentlyContinue
            }catch{Call-Action -Message "Failed to create deployment share in MDT ($deploymentShare) please check script is running as admin" -ExtraMessage $Error[0].Exception.Message}

            try{import-mdttasksequence -path "DS001:\Task Sequences" -Name "Install Windows" -Template "$deploymentShare\Control\ts.xml" -Comments "" -ID "1" -Version "1.0" -FullName "$mdtSchoolName" -OrgName "$mdtSchoolName" -HomePage "$mdtSchoolWebsite" -erroraction stop}
                Catch{Call-Action -Message "Failed to create new Task Sequence" -ExtraMessage $Error[0].Exception.Message}

            try{Enable-MDTMonitorService -EventPort 9800 -DataPort 9801 }Catch{Call-Action -Message "Failed to enable Monitor Serivce" -ExtraMessage $Error[0].Exception.Message}
            try{update-MDTDeploymentShare -path "DS001:"}Catch{Call-Action -Message "Failed to update Deployment Share" -ExtraMessage $Error[0].Exception.Message}
               
            try{
                Write-Warning "Importing boot wim into WDS"
                $bootWimPath ="$deploymentShare\boot\LiteTouchPE_x64.wim"
                wdsutil /add-Image imageFile:$bootWimPath /Servimagetype:Boot
                wdsutil /set-server /bootimage:Boot\x64\Images\LiteTouchPE_x64.wim /Architecture:x64
                wdsutil /set-server /bootimage:Boot\x64\Images\LiteTouchPE_x64.wim /Architecture:x64uefi
            }
            catch{Call-Action -Message "Failed to invoke WDSUTIL, check WDS Feature is installed properly." -ExtraMessage $Error[0].Exception.Message}
}

Function Import-OS{
    $osWims = Get-ChildItem -Path "$PSScriptRoot\Wim"

    ForEach($wimFile in $osWims){
        try{Import-mdtoperatingsystem -path "DS001:\Operating Systems" -SourceFile $wimFile -DestinationFolder "Windows 10" -Verbose}Catch{Call-Action -Message "Failed to Import OS or no WIM Present" -ExtraMessage $Error[0].Exception.Message}
    }
    
    

}

Function Generate-OUs{
    Param
    (	
            [String]$SearchBase,
            [String]$ExportPath
    )
    
    Write-Warning "Generating DomainOUList.xml"

    #Define ASCII Characters    
        $Equals = [Char]61
        $Space = [Char]32
        $SingleQuote = [Char]39
        $DoubleQuote = [Char]34
        $NewLine = "`n"
        $Tab = "`t"

    #Determine The Parent Of An Active Directory Object
        Function Get-ADObjectParent ($DistinguishedName) 
        {
            $Parts = $DistinguishedName -Split "(?<![\\]),"
            Return $Parts[1..$($Parts.Count - 1)] -Join ","
        }

        #Clear "DomainOUList.xml"
    If (Test-Path -Path "$ExportPath") {Remove-Item -Path $ExportPath -Force}

    #Create "DomainOUList.xml"
        $DomainOUList_Create = (New-Item -ItemType File -Path "$ExportPath" -Force).FullName

    #Retrieve Organizational Units From Active Directory And Sort The Results Based On CanonicalName
        $OUs = Get-ADOrganizationalUnit -Filter * -Credential $Credentials -Properties * -SearchBase $SearchBase -SearchScope OneLevel -Server $Server | Select *, @{Name="FriendlyName";Expression={($_.CanonicalName).Split("/")}}, @{Name="Parent";Expression={Get-ADObjectParent -DistinguishedName $_.DistinguishedName}} | Sort-Object CanonicalName

        [string]$ouList = $OUs

        Call-Action -Message "Please check the following configuration is correct." -ExtraMessage $ouList # outputs list, user presses c to continue, or a to abort depending on if the output looks correct to them

    #Export To "DomainOUList.xml" for use with Microsoft Deployment Toolkit
        If ($OUs.Count -gt 0)
            {
                $Output = ("<?xml version=`"1.0`" encoding=`"utf-8`"?>" + $NewLine + $NewLine)
            
                $Output += ("<DomainOUs>" + $NewLine + $NewLine)

                ForEach ($Item In $OUs)
                    {  
                        #If You Want To Remove Portions Of The "$Item.FriendlyName" Property, Experiment With The "+ 4" Value. Example - Change It To + 3, etc... This May Make It Easier To See The Names When Selecting Them During Deployment.
                            $Item.FriendlyName = (($Item.FriendlyName)[($Item.FriendlyName.GetLowerBound(0) + 4)..($Item.FriendlyName.GetUpperBound(0))] -Join " \ ") 
                    
                            $Output += ($Tab + "<DomainOU value=`"$($Item.DistinguishedName)`">" + $NewLine + $Tab + $Tab + $($Item.FriendlyName) + $NewLine + $Tab + "</DomainOU>" + $NewLine + $NewLine)
               
                    }

                $Output += ("</DomainOUs>")

                #Export Data To "DomainOUList.xml"
                    $Output | Out-File "$ExportPath" -Append -Encoding utf8
            }
}