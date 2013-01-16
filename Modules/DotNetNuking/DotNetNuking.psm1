Set-StrictMode -Version Latest

Push-Location

Import-Module Add-HostFileEntry
Import-Module WebAdministration
Import-Module SQLPS -DisableNameChecking

Pop-Location

$defaultDotNetNukeVersion = '7.0.1'

function Remove-DotNetNukeSite {
  param(
    [parameter(Mandatory=$true,position=0)]
    [string]$siteName
  );
  
  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
  }

  Remove-Website $siteName
  Remove-WebAppPool $siteName
  rmdir C:\inetpub\wwwroot\$siteName -Recurse -Force
  Invoke-Sqlcmd -Query "ALTER DATABASE [$siteName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;" -ServerInstance . -Database master
  Invoke-Sqlcmd -Query "DROP DATABASE [$siteName];" -ServerInstance . -Database master
}

function Restore-DotNetNukeSite {
  param(
    [parameter(Mandatory=$true,position=0)]
    [string]$siteName,
    [parameter(Mandatory=$true,position=1)]
    [string]$siteZip,
    [parameter(Mandatory=$true,position=2)]
    [string]$databaseBackup,
    [parameter(Mandatory=$false)]
    [string]$sourceVersion = '',
    [parameter(Mandatory=$false)]
    [string]$oldDomain = ''
  );
  
  # TODO: Switch $siteZip and $databaseBackup is $siteZip extension is .bak

  $version = if ($sourceVersion -ne '') { $sourceVersion } else { $defaultDotNetNukeVersion }
  $includeSource = $sourceVersion -ne ''
  New-DotNetNukeSite $siteName -siteZip $siteZip -databaseBackup $databaseBackup -version $version -includeSource $includeSource -oldDomain $oldDomain
}

function New-DotNetNukeSite {
  param(
    [parameter(Mandatory=$true,position=0)]
    [string]$siteName,
    [parameter(Mandatory=$false,position=1)]
    [string]$version = $defaultDotNetNukeVersion,
    [parameter(Mandatory=$false,position=2)]
    [bool]$includeSource = $true,
    [parameter(Mandatory=$false)]
    [string]$objectQualifier = '',
    [parameter(Mandatory=$false)]
    [string]$databaseOwner = 'dbo',
    [parameter(Mandatory=$false)]
    [string]$siteZip = $null,
    [parameter(Mandatory=$false)]
    [string]$databaseBackup = $null,
    [parameter(Mandatory=$false)]
    [string]$oldDomain = $null
  );

  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
  }
  
  $v = New-Object System.Version($version)
  $majorVersion = $v.Major
  $formattedVersion = $v.Major.ToString('0#') + '.' + $v.Minor.ToString('0#') + '.' + $v.Build.ToString('0#')
  if ($includeSource -eq $true) {
    &7za x -oC:\inetpub\wwwroot\$siteName "${env:soft}\DNN\Versions\DotNetNuke $majorVersion\DotNetNuke_Community_${formattedVersion}_Source.zip" | Out-Null
    cp "${env:soft}\DNN\Versions\DotNetNuke $majorVersion\DotNetNuke_Community_${formattedVersion}_Symbols.zip" C:\inetpub\wwwroot\$siteName\Website\Install\Module
    ls C:\inetpub\wwwroot\$siteName\*.sln | % { Set-Content $_ ((Get-Content $_) -replace '"http://localhost/DotNetNuke_Community"', "`"http://$siteName`"") }
  }
  
  if ($siteZip -eq $null) { 
    $siteZip = "${env:soft}\DNN\Versions\DotNetNuke $majorVersion\DotNetNuke_Community_${formattedVersion}_Install.zip"
  }
  &7za x -y -oC:\inetpub\wwwroot\$siteName\Website $siteZip | Out-Null

  Add-HostFileEntry $siteName

  New-WebAppPool $siteName
  New-Website $siteName -HostHeader $siteName -PhysicalPath C:\inetpub\wwwroot\$siteName\Website -ApplicationPool $siteName
  Set-ModifyPermission C:\inetpub\wwwroot\$siteName\Website $siteName
  
  [xml]$webConfig = Get-Content C:\inetpub\wwwroot\$siteName\Website\web.config
  if ($databaseBackup -eq $null) {
    New-DotNetNukeDatabase $siteName
  }
  else {
    Restore-DotNetNukeDatabase $siteName $databaseBackup

    $objectQualifier = $webConfig.configuration.dotnetnuke.data.providers.add.objectQualifier
    $databaseOwner = $webConfig.configuration.dotnetnuke.data.providers.add.databaseOwner
    $objectQualifier = $objectQualifier.TrimEnd('_')
    $databaseOwner = $databaseOwner.TrimEnd('.')

    if ($oldDomain -ne $null) {
      Invoke-Sqlcmd -Query "UPDATE ${databaseOwner}.[${objectQualifier}PortalAlias] SET HTTPAlias = REPLACE(HTTPAlias, '$oldDomain', '$siteName')" -Database $siteName
      Invoke-Sqlcmd -Query "UPDATE ${databaseOwner}.[${objectQualifier}PortalSettings] SET SettingValue = REPLACE(SettingValue, '$oldDomain', '$siteName') WHERE SettingName = 'DefaultPortalAlias'" -Database $siteName
      # TODO: Update remaining .com aliases to .com.dev
      # TODO: Add all aliases to host file and IIS
    }

    # TODO: Set SMTP to localhost
  }

  $connectionString = "Data Source=.`;Initial Catalog=$siteName`;Integrated Security=true"
  $webConfig.configuration.connectionStrings.add.connectionString = $connectionString
  $webConfig.configuration.appSettings.add | ? { $_.key -eq 'SiteSqlServer' } | % { $_.value = $connectionString }
  $webConfig.configuration.dotnetnuke.data.providers.add.objectQualifier = $objectQualifier
  $webConfig.configuration.dotnetnuke.data.providers.add.databaseOwner = $databaseOwner
  $webConfig.Save("C:\inetpub\wwwroot\$siteName\Website\web.config")
  
  Invoke-Sqlcmd -Query "CREATE LOGIN [IIS AppPool\$siteName] FROM WINDOWS WITH DEFAULT_DATABASE = [$siteName];" -Database master
  Invoke-Sqlcmd -Query "CREATE USER [IIS AppPool\$siteName] FOR LOGIN [IIS AppPool\$siteName];" -Database $siteName
  Invoke-Sqlcmd -Query "EXEC sp_addrolemember N'db_owner', N'IIS AppPool\$siteName';" -Database $siteName
  
  Start-Process -FilePath http://$siteName
}

function New-DotNetNukeDatabase {
  param(
    [parameter(Mandatory=$true,position=0)]
    [string]$siteName
  );
  
  Invoke-Sqlcmd -Query "CREATE DATABASE [$siteName];" -Database master
}

function Restore-DotNetNukeDatabase {
  param(
    [parameter(Mandatory=$true,position=0)]
    [string]$siteName,
    [parameter(Mandatory=$true,position=1)]
    [string]$databaseBackup
  );
  
  #based on http://redmondmag.com/articles/2009/12/21/automated-restores.aspx
  $server = New-Object Microsoft.SqlServer.Management.Smo.Server('(local)')
  $dbRestore = New-Object Microsoft.SqlServer.Management.Smo.Restore
  
  $dbRestore.Action = 'Database'
  $dbRestore.NoRecovery = $false
  $dbRestore.ReplaceDatabase = $true
  $dbRestore.Devices.AddDevice($databaseBackup, [Microsoft.SqlServer.Management.Smo.DeviceType]::File)
  $dbRestore.Database = $siteName
   
  $dbRestoreFile = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile
  $dbRestoreLog = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile
  
  $logicalDataFileName = $siteName
  $logicalLogFileName = $siteName
  
  foreach ($file in $dbRestore.ReadFileList($server)) {
    switch ($file.Type) {
      'D' { $logicalDataFileName = $file.LogicalName }
      'L' { $logicalLogFileName = $file.LogicalName }
    }
  }

  $dbRestoreFile.LogicalFileName = $logicalDataFileName
  $dbRestoreFile.PhysicalFileName = $server.Information.MasterDBPath + '\' + $siteName + '_Data.mdf'
  $dbRestoreLog.LogicalFileName = $logicalLogFileName
  $dbRestoreLog.PhysicalFileName = $server.Information.MasterDBLogPath + '\' + $siteName + '_Log.ldf'
  
  $dbRestore.RelocateFiles.Add($dbRestoreFile) | Out-Null
  $dbRestore.RelocateFiles.Add($dbRestoreLog) | Out-Null
  
  try {
    $dbRestore.SqlRestore($server)
  }
  catch [System.Exception] {
    write-host $_.Exception
  }
}

Export-ModuleMember Remove-DotNetNukeSite
Export-ModuleMember New-DotNetNukeSite
Export-ModuleMember Restore-DotNetNukeSite