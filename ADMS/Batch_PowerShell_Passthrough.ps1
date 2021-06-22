<#
Script By: rhysj@newerait.co.nz
Last Updated: 14/04/2021
Edit the lines between Configure Start and Configure End.
Make sure you sync the staffs classification to their department field, check Northland College as an example
Please make sure the linked .bat has the correct ScriptType, otherwise this will all break.

You can add the users department to A1Groups if you'd like to force A1 Licenses, might be usful for students who come in from other schools for lab usage etc.

NewStudent
UpdateStudent
LeaverStudent
NewStaff
UpdateStaff
LeaverStaff
#>

<# Change Log
    Fixed missing group info on functions
#>

<# Configure Start #>

$lp = "C:\AdmsScripts\Log" # Log Path
[int]$mls = 5 # Max Log Size

#Departments you want to have A1
[string[]]$A1Groups = "",""

#Home Drives leave blank if not using homedrives
$HomePaths = ""

<# Configure End #>

# All Office 365 License Group names in AD
[string[]]$A3StaffGroups = "LIC_Office365A3forFaculty","LIC_MinecraftEducationEditionFaculty","LIC_Windows10EnterpriseA3forFaculty","LIC_EnterpriseMobilitySecurityE3"
[string[]]$A3StudentGroups = "LIC_Office365A3forStudents","LIC_MinecraftEducationEditionStudent","LIC_Windows10EnterpriseA3forStudents","LIC_EnterpriseMobilitySecurityE3"
[string]$A1StaffGroups = "LIC_Office365A1PlusForFaculty"
[string]$A1StudentGroups = "LIC_Office365A1PlusForStudents"
$AllStaffGroups = [array]$A3StaffGroups + $A1StaffGroups
$AllStudentGroups = [array]$A3StudentGroups + $A1StudentGroups

[string]$SamAccountName = $args[0] # Pull UserName from .bat
[string]$ScriptType = $args[1] # Pull ScriptType from .bat


# Log cleanup
$logsize = Get-ChildItem -Filter *.txt $lp -Recurse | Measure-Object -Property length -Sum
$logsize = "{0:N2}" -f ($logsize.sum / 1MB)
if ($logsize -gt $mls) { Write-Host "Log Folder oversized, deleting logs."; Remove-Item -Recurse -Force $lp }

# Log Date & Name
$TimeStamp = Get-Date -Format "dd-mm-yyyy"
$LogFile = $lp + "\" + "$TimeStamp - $SamAccountName" + ".txt"

<# Functions Start #>

function Remove-All-Group-Memberships {
	param($SamAccountName,$DistinguishedName,$Department,$ExistingGroups)
	if ($DistinguishedName –match "Left") {
		if ($DistinguishedName –match "Students") {
			foreach ($Group in $AllStudentGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $true) {
					Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
			(Get-Date -Format "HH:mm:ss") +" INFO: Completed" | Out-File $Logfile -Append
			exit # Exit running PS session
		}

		if ($DistinguishedName –match "Staff") {
			foreach ($Group in $AllStaffGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $true) {
					Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
			(Get-Date -Format "HH:mm:ss") +" INFO: Completed" | Out-File $Logfile -Append
			exit # Exit running PS session
		}
	}
}

function Add-All-Group-Memberships {
	param($SamAccountName,$DistinguishedName,$Department,$ExistingGroups)

	# FAILSAFE
	if ($DistinguishedName –match "Left") {
		"WARNING: FAILED - ERROR User $SamAccountName is in Wrong OU and has been detected AS LEFT, please check AD and Kamar" | Out-File $Logfile -Append
		exit
	}

	# A1 Licenses
	if ($A1Groups -contains $Department) {
		if ($DistinguishedName –match "Students") {
			foreach ($Group in $A1StudentGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $false) {
					Add-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
			(Get-Date -Format "HH:mm:ss") +" INFO: Completed" | Out-File $Logfile -Append
			exit # Exit running PS session
		}
		if ($DistinguishedName –match "Staff") {
			foreach ($Group in $A1StaffGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $false) {
					Add-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
			(Get-Date -Format "HH:mm:ss") +" INFO: Completed" | Out-File $Logfile -Append
			exit # Exit running PS session
		}
	}
	# A3 Licenses
	if ($A1Groups -notcontains $Department) {
		if ($DistinguishedName –match "Students") {
			foreach ($Group in $A3StudentGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $false) {
					Add-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
			(Get-Date -Format "HH:mm:ss") +" INFO: Completed" | Out-File $Logfile -Append
			exit # Exit running PS session
		}
		if ($DistinguishedName –match "Staff") {
			foreach ($Group in $A3StaffGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $false) {
					Add-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - ADD User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
			(Get-Date -Format "HH:mm:ss") +" INFO: Completed" | Out-File $Logfile -Append
			exit # Exit running PS session
		}
	}
}

function Update-All-Group-Memberships {
	param($SamAccountName,$DistinguishedName,$Department,$ExistingGroups)

	# FAILSAFE
	if ($DistinguishedName –match "Left") {
		"WARNING: FAILED - ERROR User $SamAccountName is in Wrong OU and has been detected AS LEFT, please check AD and Kamar" | Out-File $Logfile -Append
		Remove-All-Group-Memberships -SamAccountName $SamAccountName -DistinguishedName $DistinguishedName -Department $Department
	}

	if ($A1Groups -notcontains $Department) {
		if ($DistinguishedName –match "Students") {
			foreach ($Group in $A1StudentGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $true) {
					Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
		}
		if ($DistinguishedName –match "Staff") {
			foreach ($Group in $A1StaffGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $true) {
					Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
		}
	}
	if ($A1Groups -contains $Department) {
		if ($DistinguishedName –match "Students") {
			foreach ($Group in $A3StudentGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $true) {
					Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
		}
		if ($DistinguishedName –match "Staff") {
			foreach ($Group in $A3StaffGroups) {
				$GroupMember = $ExistingGroups.Contains($Group) ; (Get-Date -Format "HH:mm:ss") + " INFO: Checking users membership of $Group" | Out-File $LogFile -Append
				if ($GroupMember -eq $true) {
					Remove-ADGroupMember -Identity $Group -Members $SamAccountName -Confirm:$False
					if ($? -eq $True) {
						(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					} else {
						(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - REMOVE User '$SamAccountName' from Group '$Group'" | Out-File $Logfile -Append
					}
				}
			}
		}
	}
	Add-All-Group-Memberships -SamAccountName $SamAccountName -DistinguishedName $DistinguishedName -Department $Department -ExistingGroups $ExistingGroups
}

function Create-Home-Folders {
    param ($SamAccountName,$DistinguishedName)
    

    if ($DistinguishedName –match "Students") {
		[string]$HomePath = $HomePaths + "Students\" + $UserName
    } elseif ($DistinguishedName –match "Staff") {
        [string]$HomePath = $HomePaths + "Staff\" + $UserName
    }

    if (!(Test-Path "$HomePath")) {
		New-Item -Type Directory "$HomePath"
		if ($? -eq $True){ 
			(Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - CREATE Home Path '$HomePath'" | out-file $LogFile -Append 
		} else {
			(Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - CREATE Home Path '$HomePath'" | out-file $LogFile -Append
		}
	    $Acl = Get-Acl "$HomePath"
	    $AccessRule = New-object System.Security.AccessControl.FileSystemAccessRule($Username,"Modify","ContainerInherit, ObjectInherit","None","Allow")
	    $Acl.SetAccessRule($AccessRule)
	    Set-Acl "$HomePath" $Acl -Verbose
	    if ($? -eq $True) {
		    (Get-Date -Format "HH:mm:ss") + " INFO: SUCCESS - SET Permission on Home Path '$HomePath'" | out-file $LogFile -Append 
	    } else {
		    (Get-Date -Format "HH:mm:ss") + " WARNING: FAILED - SET Permission on Home Path '$HomePath'" | out-file $LogFile -Append
	    }
    }
}

<# Functions End #>

<# Script Starts #>
(Get-Date -Format "HH:mm:ss") +" INFO: Starting" | Out-File $Logfile -Append
$User = Get-ADUser -Identity $SamAccountName -Properties DistinguishedName,Department # Get AD User
$ExistingGroups = Get-ADPrincipalGroupMembership -Identity $SamAccountName | Select-Object -ExpandProperty SamAccountName

$DistinguishedName = $User.DistinguishedName

if ($User.department -eq $null -or $test -eq "") { $Department = "NotSyncedFromKamar" } else { $Department = $User.department }


(Get-Date -Format "HH:mm:ss") +" USER: Sam Account Name - $SamAccountName" | Out-File -FilePath $LogFile -Append
(Get-Date -Format "HH:mm:ss") +" USER: Distinguished Name - $DistinguishedName" | Out-File -FilePath $LogFile -Append
(Get-Date -Format "HH:mm:ss") +" USER: Department - $Department" | Out-File -FilePath $LogFile -Append

# New User
if ($ScriptType -eq "NewStudent" -or $ScriptType -eq "NewStaff") {
	(Get-Date -Format "HH:mm:ss") +" USER: RUN TYPE - New User" | Out-File -FilePath $LogFile -Append
    if($Homepath -ne $null -and $HomePath -ne ""){Create-Home-Folders -SamAccountName $SamAccountName -DistinguishedName $DistinguishedName}
	Add-All-Group-Memberships -SamAccountName $SamAccountName -DistinguishedName $DistinguishedName -Department $Department -ExistingGroups $ExistingGroups
}

# Update User
if ($ScriptType -eq "UpdateStudent" -or $ScriptType -eq "UpdateStaff") {
	(Get-Date -Format "HH:mm:ss") +" USER: RUN TYPE - Updating User" | Out-File -FilePath $LogFile -Append
	Update-All-Group-Memberships -SamAccountName $SamAccountName -DistinguishedName $DistinguishedName -Department $Department -ExistingGroups $ExistingGroups
}

# Leaver User
if ($ScriptType -eq "LeaverStudent" -or $ScriptType -eq "LeaverStaff") {
	(Get-Date -Format "HH:mm:ss") +" USER: RUN TYPE - Leaving User" | Out-File -FilePath $LogFile -Append
	Remove-All-Group-Memberships -SamAccountName $SamAccountName -DistinguishedName $DistinguishedName -Department $Department -ExistingGroups $ExistingGroups
}

<# Script Ends #>
