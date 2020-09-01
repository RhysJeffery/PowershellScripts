$tp = Test-Path -Path "$PSScriptRoot\HWID"

if($tp -eq $false){md "$PSScriptRoot\HWID"}

Set-Location "$PSScriptRoot\HWID"
$Serial = wmic bios get serialnumber
$serial = $Serial.item(2)
#Install-Script -Name Get-WindowsAutoPilotInfo -Force -Repository

$argumentList = "-OutputFile '$serial - AutoPilotHWID.csv'"
$ScriptPath = "$PSScriptRoot\Get-WindowsAutoPilotInfo.ps1"
Invoke-Expression "$scriptPath $argumentList"
