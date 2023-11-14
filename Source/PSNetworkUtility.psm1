<#
.SYNOPSIS
    This module contains functions for working with networks.
.DESCRIPTION
    Small utility functions will be created in here for gathering 'normal' network information in a better way.
.LINK
    https://github.com/AndrewWayLCA/PSNetworkUtility
#>

# dot-source all the files in the Private and Classes folders first, before starting on Public
foreach ($folderItem in 'Private','Classes') {
    Get-ChildItem "$PSScriptRoot/$folderItem/*.ps1" | ForEach-Object {
        . $PSItem.FullName
    }
}

# dot-source all files in the Public folder and export the functions
$publicFunctions = Get-ChildItem "$PSScriptRoot/Public/*.ps1" | ForEach-Object {
    . $PSItem.FullName
    #Output the name of the function assuming it is the same as the .ps1 file so it can be exported
    $PSItem.BaseName
}

Export-ModuleMember $publicFunctions
