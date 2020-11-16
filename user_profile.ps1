#Requires -Version 3
#Requires -Modules VSSetup, oh-my-posh
#Set-StrictMode -Version Latest

Import-Module oh-my-posh;
$ThemeSettings.MyThemesLocation = $PSScriptRoot;
Set-Theme My-Posh-Theme;
[ScriptBlock]$Prompt = $function:prompt;

Set-PSReadlineKeyHandler -Key Tab -Function Complete;
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward;
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward;

#Import-Module Pscx -arg $PSScriptRoot\Pscx.UserPreferences.ps1;
#Set-Alias sudo Invoke-Elevated;
Set-Alias rm Remove-ItemSafely -Option AllScope;

$env:Platform = 'Any CPU';
$studioInstance = Get-VSSetupInstance -All | Select-VSSetupInstance -Require 'Microsoft.VisualStudio.Workload.NetWeb' -Version 15.0 -Latest;
if ($studioInstance) {
    if ($PSVersionTable.PSEdition -eq 'Desktop') {
        Import-Module "$($studioInstance.InstallationPath)\Common7\Tools\Microsoft.VisualStudio.DevShell.dll";
        Enter-VsDevShell -VsInstanceId $studioInstance.InstanceId -StartInPath $PWD;
    }
    else {
        $scriptPath = Join-Path $studioInstance.InstallationPath 'Common7\Tools\VsDevCmd.bat';
        if (Test-Path $scriptPath) {
            & $scriptPath;
        }

        $msbuild = Get-Command msbuild -ErrorAction SilentlyContinue;
        if (-not $msbuild) {
            $exe = Get-ChildItem (Join-Path $studioInstance.InstallationPath 'MSBuild\**\Bin\MSBuild.exe');
            if ($exe) {
                $dir = Split-Path $exe;
                $env:Path += (';' + $dir + ';');
            }
        }
    }
}

$www = $env:www;

function Search-AllTextFiles {
    param(
        [parameter(Mandatory = $true, position = 0)]$Pattern,
        [switch]$CaseSensitive,
        [switch]$SimpleMatch
    );

    Get-ChildItem . * -Recurse -Exclude ('*.dll', '*.pdf', '*.pdb', '*.zip', '*.exe', '*.jpg', '*.gif', '*.png', '*.ico', '*.svg', '*.bmp', '*.tif', '*.tiff', '*.psd', '*.cache', '*.doc', '*.docx', '*.xls', '*.xlsx', '*.dat', '*.mdf', '*.nupkg', '*.snk', '*.ttf', '*.eot', '*.woff', '*.tdf', '*.gen', '*.cfs', '*.map', '*.min.js', '*.data', '*.tis', '*.fdt', '*.pack', 'index', '*.ide', '*.tmp') | Select-String -Pattern:$pattern -SimpleMatch:$SimpleMatch -CaseSensitive:$CaseSensitive;
}
