if (Get-Command gulp -ErrorAction SilentlyContinue) {
	Invoke-Expression ((gulp --completion=powershell) -join [System.Environment]::NewLine)
}
