<#

Automated Microsoft Deployment Toolkit Installer
Scripter: Rhys Jeffery
Email: Rhysj@neweratech.co.nz
Date: 21/06/2021

Version: 1.2
Download: https://neweraitnz.sharepoint.com/:f:/s/tetaitokerauteam/Eq90-mWR-aFOuWqc8Urd6Z8BDfmdmbs_8LsT1FAuuXZxjw?e=DFLyQO

Install Wim can be found here : https://neweraitnz.sharepoint.com/:f:/s/tetaitokerauteam/Epj374VlIcRPoSJAgshO0OwB6tz8Xtly3wx0KxwwNqPGHQ?e=zxZiie

This Script contains low level comments for users new to powershell, however this won't contain much hand holding

Please edit config.xml for configuration changes.

Script installs MDT 8456, ADK 2004 and WINPE 2004. This script should NOT be used to update existing installs, currently that should be done manually.
     e.g. Uninstall ADK, WINPE, install new ADK, install new WINPE, install MDT update (if one), upgrade deployment share and then edited any required script.

Script also installs edited scripts that need to be manually updated if ADK or WINPE is updated.
    Domain Friendly OU Names - http://stonywall.com/2016/11/14/mdt-2013-update-2-adding-domain-ous-with-friendly-names/

Script Uses code from the following
    DomainOuList.xml Generation - https://community.spiceworks.com/scripts/show/3426-custom-domainoulist_create-ps1

#>

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
  Exit
 }
}

# Setup script for running
[xml] $Settings = Get-Content -Path "$PSScriptRoot\config.xml" # Pull configuration from xml

Import-Module -Name "$PSScriptRoot\Functions.psm1" -Force -ErrorAction stop | Out-Null

[int] $errorInstall = 0

# Check the configuration file and make sure none of the options are blank
$configcheck = $Settings.Configuration | select -ExpandProperty childnodes | where {$_.name -ne '#comment'} | select Name,InnerText
foreach ($configChild in $configcheck){

    if($configChild.innertext -eq $null){
        Write-Warning $configchild.Name " is blank, please update config.xml and try again. Exiting installer."
        $errorInstall = 1
    }

}

if($errorInstall -eq 1 ){exit}

#  We now need to generate some dynamic paths with we will use for our edits and installs
[string] $mdtUser = $Settings.Configuration.User.ToString()
[string] $mdtPassword = $Settings.Configuration.Password.ToString()
[string] $mdtInstallLocation = $Settings.Configuration.InstallLocation.ToString()

    # Check if this is an CTP install, value must be true or false
    if($Settings.Configuration.CTP -eq $True){[string] $mdtDeploymentServer = $Settings.Configuration.DeploymentServer.ToString()}else{[string] $mdtDeploymentServer = $env:COMPUTERNAME}

[string] $mdtDomainName = $Settings.Configuration.DomainName.ToString()
[string] $mdtSchoolName = $Settings.Configuration.SchoolName.ToString()
[string] $mdtDefaultDevicePassword = $Settings.Configuration.DefaultDevicePassword.ToString()
[string] $mdtDefaultOU = $Settings.Configuration.DefaultDeviceOU.ToString()
[string] $mdtSchoolWebsite = $Settings.Configuration.SchoolWebsite.ToString()
[string] $mdtServerIsRODC = $Settings.Configuration.RODC.ToString()

# built in strings
$objectToString = $configcheck | Select-Object -Property *
[string] $configList = Out-String -InputObject $objectToString

Call-Action -Message "Please check the following configuration is correct." -ExtraMessage $configlist # outputs list, user presses c to continue, or a to abort depending on if the output looks correct to them

# Install required software & features
Install-MDT
Install-ADK-WinPE
Install-WDS -mdtInstallLocation $mdtInstallLocation

Start-Sleep -Seconds 5 # wait for 5 seconds

# Run configuration functions
Setup-MDT -mdtUser $mdtUser -mdtDomainName $mdtDomainName -mdtInstallLocation $mdtInstallLocation
Import-OS
Configure-MDT -mdtUser $mdtUser -mdtPassword $mdtPassword -mdtInstallLocation $mdtInstallLocation -mdtDomainName $mdtDomainName -mdtSchoolName $mdtSchoolName -mdtDefaultDevicePassword $mdtDefaultDevicePassword -mdtSchoolWebsite $mdtSchoolWebsite -mdtDefaultOU $mdtDefaultOU

if($mdtServerIsRODC -eq "True"){
    Generate-OUs -searchbase $mdtDefaultOU -exportpath "$mdtInstallLocation\DeploymentShare\Control\DomainOUList.xml"
    }
