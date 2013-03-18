Set-StrictMode -Version Latest

function Set-ProjectWebPath {
  param(
    [parameter(Mandatory=$true,position=0)]
    [string]$projectFile,
    [parameter(Mandatory=$true,position=1)]
    [string]$rootUrl,
    [parameter(Mandatory=$true,position=2)]
    [string]$relativeProjectUrl
  );
  
  $userFilePath = $projectFile + '.user'
  $rootUri = New-Object System.Uri (?: { $rootUrl.StartsWith("http") } { $rootUrl } { 'http://' + $rootUrl }), ([System.UriKind]::Absolute)
  $relativeProjectUri = New-Object System.Uri $relativeProjectUrl, ([System.UriKind]::Relative)
  $projectUri = New-Object System.Uri $rootUri, $relativeProjectUri

  [xml]$userFileContent = Get-Content $userFilePath
  $webProjectNode = $userFileContent.Project.ProjectExtensions.VisualStudio.FlavorProperties.WebProjectProperties
  if (!$webProjectNode) {
    Write-Error 'The Web Project Properties node was not in the settings file'
    return
  }

  CreateOrSet $webProjectNode, 'UseIIS', 'True'
  CreateOrSet $webProjectNode, 'IISUrl', $projectUri.AbsoluteUri
  CreateOrSet $webProjectNode, 'OverrideIISAppRootUrl', 'True'
  CreateOrSet $webProjectNode, 'IISAppRootUrl', $rootUri.AbsoluteUri

  <#
.SYNOPSIS
    Sets the web path of the given Visual Studio project
.DESCRIPTION
    Sets the project's user configuration file to use IIS for the project, setting the URL and application root override URL
.PARAMETER projectFile
    The path to the csproj file for the project
.PARAMETER rootUrl
    The URL to the root of the site (e.g. 'dnndev.me')
.PARAMETER relativeProjectUrl
    The URL to the project, relative to the rootUrl (e.g. 'DesktopModules/Engage/CoolThing')
#>
}

function CreateOrSet($parentNode, $childNodeName, $value) { 
    $ns = @{ base = 'http://schemas.microsoft.com/developer/msbuild/2003' }
    $childNode = (Select-Xml ('base:' + $childNodeName) -Xml $parentNode -Namespace $ns)
    if (!$childNode) {
        $childNode = $parentNode.CreateElement($childNodeName)
        $parentNode.AppendChild($childNode)
    } else {
        $childNode = $childNode.Node
    }

    $childNode.Value = $value
}

Export-ModuleMember Set-ProjectWebPath