#Requires -Version 3
#Set-StrictMode -Version Latest

Import-Module oh-my-posh
$ThemeSettings.MyThemesLocation = $PSScriptRoot
Set-Theme My-Posh-Theme
[ScriptBlock]$Prompt = $function:prompt

Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward

Import-Module Pscx -arg $PSScriptRoot\Pscx.UserPreferences.ps1
Set-Alias sudo Invoke-Elevated
Set-Alias rm Remove-ItemSafely -Option AllScope

$env:Platform = 'Any CPU'
#Import-VisualStudioVars 150
if ($env:VS150COMNTOOLS -and (Test-Path $env:VS150COMNTOOLS)) {
    Invoke-BatchFile (Join-Path $env:VS150COMNTOOLS VsDevCmd.bat) -Parameters '-no_logo'
}

$www = $env:www

function Search-AllTextFiles {
    param(
        [parameter(Mandatory = $true, position = 0)]$Pattern,
        [switch]$CaseSensitive,
        [switch]$SimpleMatch
    );

    Get-ChildItem . * -Recurse -Exclude ('*.dll', '*.pdf', '*.pdb', '*.zip', '*.exe', '*.jpg', '*.gif', '*.png', '*.ico', '*.svg', '*.bmp', '*.tif', '*.tiff', '*.psd', '*.cache', '*.doc', '*.docx', '*.xls', '*.xlsx', '*.dat', '*.mdf', '*.nupkg', '*.snk', '*.ttf', '*.eot', '*.woff', '*.tdf', '*.gen', '*.cfs', '*.map', '*.min.js', '*.data', '*.tis', '*.fdt', '*.pack', 'index', '*.ide', '*.tmp') | Select-String -Pattern:$pattern -SimpleMatch:$SimpleMatch -CaseSensitive:$CaseSensitive
}
