$Servers = 'server1','server2'
$PrimaryDHCP = 'server1'

 

Invoke-DhcpServerv4FailoverReplication -ComputerName $PrimaryDHCP -force
Foreach($server in $Servers){

 

$Scopes = Get-DhcpServerv4Scope -ComputerName $Server
Set-DhcpServerv4DnsSetting -ComputerName $Server -DynamicUpdates "OnClientRequest" -UpdateDnsRRForOlderClients $false -DeleteDnsRROnLeaseExpiry $true
Add-ADGroupMember -identity "DnsUpdateProxy" -members $server
    Foreach($Scope in $Scopes){

 

        Repair-DhcpServerv4IPRecord -ScopeId $Scope.ScopeId -force
        Set-DhcpServerv4DnsSetting -ScopeId $Scope.ScopeId -DynamicUpdates "OnClientRequest" -UpdateDnsRRForOlderClients $false -DeleteDnsRROnLeaseExpiry $true

 

    }

 

}
