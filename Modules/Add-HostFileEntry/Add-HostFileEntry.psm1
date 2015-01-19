Set-StrictMode -Version Latest

function Add-HostFileEntry {
  param(
    [parameter(Mandatory=$true,position=0)]
	[string]$hostName,
    [string]$ipAddress = '127.0.0.1'
  );

	$hostsLocation = "$env:windir\System32\drivers\etc\hosts";
    $hostsContent = Get-Content $hostsLocation -Raw;
    
    $ipRegex = [regex]::Escape($ipAddress);
    $hostRegex = [regex]::Escape($hostName);
    
    $existingEntry = $hostsContent -match "(?:`n|\A)\s*$ipRegex\s+$hostRegex\s*(?:`n|\Z)"
	if(-not $existingEntry)
	{
        if ($hostsContent -notmatch "`n\s*$") 
        {
            # Add line break if missing from last line
            Add-Content -Path $hostsLocation -Value '';
        }

		Add-Content -Path $hostsLocation -Value "$ipAddress`t$hostName";
	}
}

Export-ModuleMember Add-HostFileEntry