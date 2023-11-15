function Get-IPConfig {
<#
.SYNOPSIS
    A quick command to use as a shortcut replacement for ipconfig to get back active IPv4 address key information.
.DESCRIPTION
    I type ipconfig a lot to confirm base IP information and to see if the network I am connected to is working and providing the right network details. This command quickly helps with that.

    I would recommend adding an Alias in your $PROFILE to map ipconfig to this command. I use the following:

    Set-Alias -Name ipconfig -Value Get-IPConfig
.NOTES
    This is not intended to be a full replacement for ipconfig.
.LINK
    https://github.com/AndrewWayLCA/PSNetworkUtility
.EXAMPLE
    PS> Get-IPConfig

    IPAddress      DefaultGateway DNSServers                   ifIndex InterfaceAlias             PrefixOrigin
    ---------      -------------- ----------                   ------- --------------             ------------
    192.168.64.144 192.168.64.254 {192.168.64.1, 192.168.64.2}      12 Ethernet 4                         Dhcp
    172.20.112.1                                                    22 vEthernet (nat)                  Manual
    172.31.128.1                                                    32 vEthernet (Default Switch)       Manual
#>

    $allIPs = Get-NetIPAddress
    $justTheIPsICareAbout = $allIPs | Where-Object {$_.AddressFamily -eq "IPv4" -and $_.AddressState -eq "Preferred" -and $_.IPAddress -ne "127.0.0.1"}

    $ips = $justTheIPsICareAbout | Select-Object -Property IPAddress,  
        @{l="DefaultGateway";e={(Get-NetRoute -InterfaceIndex $_.ifIndex -DestinationPrefix "0.0.0.0/0").NextHop}},
        @{l="DNSServers";e={(Get-DnsClientServerAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses}},
        ifIndex, InterfaceAlias, PrefixOrigin

    # sort and present the output
    $ips | Sort-Object -Property ifIndex | Format-Table

}