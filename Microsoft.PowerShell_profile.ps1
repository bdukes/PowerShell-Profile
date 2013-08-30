Set-StrictMode -Version Latest

Import-Module Pscx -RequiredVersion 3.0.0.0 -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1"

Import-Module Set-ModifiedTime
Set-Alias touch Set-ModifiedTime
Set-Alias sudo Invoke-Elevated

Import-VisualStudioVars 2012 amd64 

function Set-ModifyPermission ($directory, $username, $domain = 'IIS APPPOOL') {
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

function GitTfs-Clone ($tfsPath, $gitPath) {
    git tfs clone http://tfs.etg-inc.net:8080/tfs/Engage%20TFS%202010 "$tfsPath" "$gitPath"
    if ($gitPath) {
      cd $gitPath
    } else {
      $repoPath = Split-Path $tfsPath -Leaf
      cd $repoPath
    }
    
    git config core.ignorecase true
}

function Fix-GitTfsBindings () {
    git config tfs-remote.default.legacy-urls http://tfs2010.etg-inc.net:8080/tfs/Engage%20TFS%202010
    git config tfs-remote.default.url http://tfs.etg-inc.net:8080/tfs/Engage%20TFS%202010
}

function Open-BrowserstackTunnel ($hostName, $port = 80, $ssl = $false) {
    $sslBit = 0
    if ($ssl) { $sslBit = 1 }
    java -jar c:\tools\BrowserStackTunnel.jar $env:browserStackTunnelKey "$hostName,$port,$sslBit"
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
    Write-Host "$($pwd.ProviderPath)" -NoNewline -BackgroundColor Blue -ForegroundColor White    

    Write-VcsStatus

    $global:LASTEXITCODE = $realLASTEXITCODE
    return "`n> "
}

Enable-GitColors
