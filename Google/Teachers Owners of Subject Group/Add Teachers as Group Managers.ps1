$Groups = Get-ADGroup -filter "name -like 'Subject*'" -SearchBase "OU=Groups,OU=KAMAR,DC=wghs,DC=local" -Properties * -SearchScope OneLevel

$staff = Get-ADGroupMember -Identity "All Staff" -Recursive | Select -ExpandProperty Name

Foreach($group in $Groups){

$members = $group.members

Foreach($user in $members){

$sam = Get-ADUser -Identity $user | select SamAccountName

$so = $sam.SamAccountName
$go = $Group.Name

if($staff -contains $Sam.SamAccountName){write-host "Setting $so as manager of $go";Set-ADGroup -Identity $Group -ManagedBy $sam.SamAccountName}



}

}

