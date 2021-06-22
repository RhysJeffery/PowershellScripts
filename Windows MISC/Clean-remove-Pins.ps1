$pinnedShortcuts = @("Word","Excel","PowerPoint","Outlook")

ForEach($pin in $pinnedShortcuts){
    ((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | ?{$_.Name -eq $pin}).Verbs() | ?{$_.Name.replace('&','') -match 'Unpin from taskbar'} | %{$_.DoIt(); $exec = $true}
}
