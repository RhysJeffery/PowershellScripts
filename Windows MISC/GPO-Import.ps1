# Rhys Jeffery @ New Era Technology


$GPath = "C:\Users\newerait\Desktop\GPOs\GPOs" # Path to backed up GPOS
$GPOS = Get-ChildItem -Path $Gpath
$MT = "C:\Users\newerait\Desktop\GPOs\mt.migtable" # Path to Migration Table
$dni = "Default Domain Policy","Default Domain Controllers Policy" # GPOs you do not want to import, use correct name from pervious directory

Function Get-GPOBackup {
# https://jdhitsolutions.com/blog/powershell/1460/get-gpo-backup/
[cmdletbinding()]

Param(
[Parameter(Position=0,Mandatory=$False,HelpMessage="What is the path to the GPO backup folder?")]
[ValidateNotNullOrEmpty()]
[string]$Path=$global:GPBackupPath,
[Parameter(Position=1)]
[string]$Name,
[switch]$Latest
)

#validate $Path
if (-Not $Path) {
$Path=Read-Host "What is the path to the GPO backup folder?"
}

Try
{
Write-Verbose "Validating $Path"
if (-Not (Test-Path $Path)) { Throw }
}
Catch
{
Write-Warning "Failed to find $Path"
Break
}

#get each folder that looks like a GUID
[regex]$regex="^(\{){0,1}[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}(\}){0,1}$"

Write-Verbose "Enumerating folders under $Path"

#define an array to hold each backup object
$Backups=@()

#find all folders named with a GUID
Get-ChildItem -Path $path | Where {$_.name -Match $regex -AND $_.PSIsContainer} |
foreach {

#import the Bkupinfo.xml file
$file=Join-Path $_.FullName -ChildPath "bkUpinfo.xml"
Write-Verbose "Importing $file"
[xml]$data=Get-Content -Path $file

#parse the xml file for data
$GPO=$data.BackupInst.GPODisplayName."#cdata-section"
$GPOGuid=$data.BackupInst.GPOGuid."#cdata-section"
$ID=$data.BackupInst.ID."#cdata-section"
$Comment=$data.BackupInst.comment."#cdata-section"
#convert backup time to a date time object
[datetime]$Backup=$data.BackupInst.BackupTime."#cdata-section"
$Domain=$data.BackupInst.GPODomain."#cdata-section"

#write a custom object to the pipeline
$Backups+=New-Object -TypeName PSObject -Property @{
Name=$GPO
Comment=$Comment
#strip off the {} from the Backup ID GUID
BackupID=$ID.Replace("{","").Replace("}","")
#strip off the {} from the GPO GUID
Guid=$GPOGuid.Replace("{","").Replace("}","")
Backup=$Backup
Domain=$Domain
Path=$Path
}

} #foreach

#if searching by GPO name, then filter and get just those GPOs
if ($Name)
{
Write-Verbose "Filtering for GPO: $Name"
$Backups=$Backups | where {$_.Name -like $Name}

}

Write-Verbose "Found $($Backups.Count) GPO Backups"

#if -Latest then only write out the most current version of each GPO
if ($Latest)
{
Write-Verbose "Getting Latest Backups"
$grouped=$Backups | Sort-Object -Property GUID | Group-Object -Property GUID
$grouped | Foreach {
$_.Group | Sort-Object -Property Backup | Select-Object -Last 1
}
}
else
{
$Backups
}

Write-Verbose "Ending function"

} #end function

$BGPOS = Get-GPOBackup -Path $gpath

ForEach($GPO in $GPOS){

     $path = $gpo.FullName.Replace("\" + $gpo.Name,"")
     $guid = $gpo.name.Replace('{',"").replace('}',"")
     ForEach($BGPO in $BGPOS){
        if($dni -contains $bgpo.name){continue}
        if($bgpo.backupid -eq $guid){Import-GPO -BackupId $gpo.Name -Path $path -TargetName $bgpo.name -MigrationTable $mt -CreateIfNeeded }
        }

}
