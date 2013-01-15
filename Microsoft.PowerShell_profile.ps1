Import-Module Pscx -RequiredVersion 3.0.0.0 -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1"

Import-Module Set-ModifiedTime
Set-Alias touch Set-ModifiedTime

Import-VisualStudioVars 2012 amd64 

function Set-ModifyPermission ($directory, $username, $domain = 'IIS APPPOOL') {
    cmd /c icacls "$directory" /grant ("$domain\$username" + ':(OI)(CI)M') /t /c /q
}

function GitTfs-Clone ($tfsPath, $gitPath) {
    git tfs clone http://tfs2010.etg-inc.net:8080/tfs/Engage%20TFS%202010 "$tfsPath" "$gitPath"
}