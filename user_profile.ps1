#Requires -Version 3
#Set-StrictMode -Version Latest

if (Get-Command git -ErrorAction SilentlyContinue) {
    Import-Module posh-git;
}
$env:POSH_GIT_ENABLED = $true;

oh-my-posh --init --shell pwsh --config "$PSScriptRoot/My-Posh-Theme.json" | Invoke-Expression;

Import-Module Terminal-Icons;
if (Test-Path 'C:/tools/gsudo/Current/gsudoModule.psd1') {
    Import-Module 'C:/tools/gsudo/Current/gsudoModule.psd1';
    Set-Alias 'sudo' 'Invoke-gsudo';
}

if (Test-Path 'C:\Program Files\Git\usr\bin\bash.exe') {
    Set-Alias bash 'C:\Program Files\Git\usr\bin\bash.exe';
}

Set-PSReadlineKeyHandler -Key Tab -Function Complete;
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward;
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward;

Set-PSReadLineOption -PredictionSource History;
Set-PSReadLineOption -PredictionViewStyle ListView;
Set-PSReadLineOption -EditMode Windows;

#Import-Module Pscx -arg $PSScriptRoot\Pscx.UserPreferences.ps1;
#Set-Alias sudo Invoke-Elevated;
Set-Alias rm Remove-ItemSafely -Option AllScope;

Import-Module VSSetup;
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

function New-TerminalTab {
    $cmd = $args[0];
    $rest = $args[1..($args.length - 1)];
    $cmd = Get-Command $cmd;
    if ($cmd) {
        $cmd = $cmd.Source;
    }
    else {
        $cmd = $args[0];
    }
	
    Write-Verbose "wt.exe --window 0 new-tab --startingDirectory $PWD $cmd $rest";
    wt.exe --window 0 new-tab --startingDirectory $PWD $cmd @rest;
}

function New-TerminalPane {
    $cmd = $args[0];
    $rest = $args[1..($args.length - 1)];
    $cmd = Get-Command $cmd;
    if ($cmd) {
        $cmd = $cmd.Source;
    }
    else {
        $cmd = $args[0];
    }
	
    Write-Verbose "wt.exe --window 0 split-pane --startingDirectory $PWD $cmd $rest";
    wt.exe --window 0 split-pane --startingDirectory $PWD $cmd @rest;
}
