#Requires -Version 3
#Requires -Modules AdministratorRole, Set-ModifiedTime
Set-StrictMode -Version Latest

Import-Module Pscx -RequiredVersion 3.2.0.0 -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1"
Set-Alias touch Set-ModifiedTime
Set-Alias sudo Invoke-Elevated
Set-Alias rm Remove-ItemSafely -Option AllScope
$www = $env:www

Invoke-BatchFile $env:VS140COMNTOOLS\VsMSBuildCmd.bat 
$env:Platform = "Any CPU"

function GitTfs-Clone {
    param(
        [parameter(Mandatory=$true,position=0)]$tfsPath, 
        [parameter(Mandatory=$false,position=1)]$gitPath, 
        $tfsServer = 'http://tfs.etg-inc.net:8080/tfs/Engage%20TFS%202010', 
        [switch]$export);

    if ($export) {
        $authorsFile = Join-Path $pwd authors.txt
        git tfs clone $tfsServer "$tfsPath" "$gitPath" --ignorecase=true --fetch-labels  --export --authors="$authorsFile"
    } else {
        git tfs clone $tfsServer "$tfsPath" "$gitPath" --ignorecase=true --fetch-labels
    }
    
    if ($gitPath) {
      cd $gitPath
    } else {
      $repoPath = Split-Path $tfsPath -Leaf
      cd $repoPath
    }
    
    git config core.ignorecase true
    git gc
    git tfs cleanup
}

function Fix-GitTfsBindings () {
    git config tfs-remote.default.legacy-urls http://tfs2010.etg-inc.net:8080/tfs/Engage%20TFS%202010
    git config tfs-remote.default.url http://tfs.etg-inc.net:8080/tfs/Engage%20TFS%202010
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

Enable-GitColors
