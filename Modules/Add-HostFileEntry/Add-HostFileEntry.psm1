Set-StrictMode -Version Latest

function Add-HostFileEntry {
  param(
    [parameter(Mandatory=$true,position=0)]
	[string]$hostName,
    [string]$ipAddress = '127.0.0.1'
  );

	$hostsLocation = "$env:windir\System32\drivers\etc\hosts";
    $hostsContent = Get-Content $hostsLocation;
    
    $ipRegex = [regex]::Escape($ipAddress);
    $hostRegex = [regex]::Escape($hostName);
    
    $existingEntry = $hostsContent -Match "^\s*$ipRegex\s+$hostRegex\s*$"
	if(-not $existingEntry)
	{
		Add-Content -Path $hostsLocation -Value "$ipAddress         $hostName";
	}
}