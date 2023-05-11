# Folder where config items are persisted. Notably destination certificates.
$script:configFolder = Join-PSFPath (Get-PSFPath -Name AppData) PowerShell PSEncrypt
$script:certFolder = Join-Path $script:configFolder 'certs'

if (-not (Test-Path $script:certFolder)) {
	$null = New-Item -Path $script:certFolder -ItemType Directory -Force
}
