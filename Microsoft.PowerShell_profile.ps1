Set-StrictMode -Version Latest

Import-Module Pscx -RequiredVersion 3.1.0.0 -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1"

Import-Module AdministratorRole
Import-Module Set-ModifiedTime
Set-Alias touch Set-ModifiedTime
Set-Alias sudo Invoke-Elevated

Import-VisualStudioVars 2013 amd64 
$env:Platform = "Any CPU"

function Set-ModifyPermission {
    param(
        [parameter(Mandatory=$true,position=0)]$directory, 
        [parameter(Mandatory=$true,position=1)]$username, 
        $domain = 'IIS APPPOOL');

    Assert-AdministratorRole

    $inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $propagation = [system.security.accesscontrol.PropagationFlags]"None"

    if ($domain -eq 'IIS APPPOOL') {
        Import-Module WebAdministration
        $sid = (Get-ItemProperty IIS:\AppPools\$username).ApplicationPoolSid
        $identifier = New-Object System.Security.Principal.SecurityIdentifier($sid)
        $user = $identifier.Translate([System.Security.Principal.NTAccount])
    } else {
        $user = New-Object System.Security.Principal.NTAccount($domain, $username)
    }

    $accessrule = New-Object system.security.AccessControl.FileSystemAccessRule($user, "Modify", $inherit, $propagation, "Allow")

    $acl = Get-Acl $directory
    $acl.AddAccessRule($accessrule)
    set-acl -aclobject $acl $directory
}

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
    #if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    #    Write-Host '╠☇╣' -NoNewline -BackgroundColor Yellow -ForegroundColor Black
    #}

    Write-Host "$($pwd.ProviderPath)" -NoNewline -BackgroundColor Blue -ForegroundColor White    

    Write-VcsStatus
    
    $global:LASTEXITCODE = $realLASTEXITCODE
    return "`n> "
}

Enable-GitColors
