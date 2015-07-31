Set-StrictMode -Version Latest

function Remove-ItemSafely {
  param(
        [parameter(Mandatory=$true,position=0)]$Path,
        [switch]$DeletePermanently);

    if ($DeletePermanently) {
        Remove-Item -Path:$Path
        return
    }

    $item = Get-Item $Path
    $directoryPath = Split-Path $item -Parent
    
    $shell = new-object -comobject "Shell.Application"
    $shellFolder = $shell.Namespace($directoryPath)
    $shellItem = $shellFolder.ParseName($item.Name)
    $shellItem.InvokeVerb("delete")

<#
.SYNOPSIS
    Deletes files and folders into the Recycle Bin
.DESCRIPTION
    Deletes the file or folder as if it had been done via File Explorer.  Based on http://stackoverflow.com/a/502034/2688
.PARAMETER Path
    The path to the file or folder
.PARAMETER DeletePermanently
    Bypasses the recycle bin, deleting the file or folder permanently
#>
}

Export-ModuleMember Remove-ItemSafely