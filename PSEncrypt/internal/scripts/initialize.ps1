# Folder where config items are persisted. Notably destination certificates.
$script:configFolder = Join-Path $env:APPDATA "PowerShell\PSEncrypt"
$script:certFolder = Join-Path $script:configFolder 'certs'

$script:config = @{
	CertThumbprint = ''
	CertFriendlyName = 'PSEncrypt Certificate'
	CertSubject = ''
}

if (-not (Test-Path $script:certFolder)) {
	$null = New-Item -Path $script:certFolder -ItemType Directory -Force
}

$configPath = Join-Path -Path $script:configFolder -ChildPath 'config.clixml'
if (Test-Path -Path $configPath) {
	$script:config = Import-Clixml -Path $configPath
}