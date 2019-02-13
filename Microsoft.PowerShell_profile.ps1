#Requires -Version 3
#Requires -Modules AdministratorRole
#Set-StrictMode -Version Latest

Set-Alias sudo Invoke-Elevated
Set-Alias rm Remove-ItemSafely -Option AllScope

$env:Platform = "Any CPU"
if (Test-Path $env:VS140COMNTOOLS\VsMSBuildCmd.bat) {
    Invoke-BatchFile $env:VS140COMNTOOLS\VsMSBuildCmd.bat 
}

$www = $env:www

function Search-AllTextFiles {
    param(
        [parameter(Mandatory=$true,position=0)]$Pattern, 
        [switch]$CaseSensitive,
        [switch]$SimpleMatch
    );

    Get-ChildItem . * -Recurse -Exclude ('*.dll','*.pdf','*.pdb','*.zip','*.exe','*.jpg','*.gif','*.png','*.ico','*.svg','*.bmp','*.psd','*.cache','*.doc','*.docx','*.xls','*.xlsx','*.dat','*.mdf','*.nupkg','*.snk','*.ttf','*.eot','*.woff','*.tdf','*.gen','*.cfs','*.map','*.min.js','*.data') | Select-String -Pattern:$pattern -SimpleMatch:$SimpleMatch -CaseSensitive:$CaseSensitive
}

Import-Module posh-git

# Set up a simple prompt, adding the git prompt parts inside git repos
function prompt {
    $realLASTEXITCODE = $LASTEXITCODE

    # Reset color, which can be messed up by Enable-GitColors
    $Host.UI.RawUI.ForegroundColor = $GitPromptSettings.DefaultForegroundColor

    Write-Host ""
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host '╠☇╣' -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    }

    Write-Host $pwd.ProviderPath -NoNewline -BackgroundColor Blue -ForegroundColor White    

    Write-VcsStatus
    
    $global:LASTEXITCODE = $realLASTEXITCODE
    Write-Host "`nλ" -NoNewline -ForegroundColor DarkGreen
    return ' '
}
