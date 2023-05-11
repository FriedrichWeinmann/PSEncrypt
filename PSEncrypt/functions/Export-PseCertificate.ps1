function Export-PseCertificate {
	<#
	.SYNOPSIS
		Creates an export of your own PSEncrypt certificate (public key only).
	
	.DESCRIPTION
		Creates an export of your own PSEncrypt certificate (public key only).
		This is used by other users of PSEncrypt to encrypt data to send to you.
	
	.PARAMETER Path
		Path to the json-file to create, containing the public information for your certificate.
	
	.PARAMETER PassThru
		Rather than generating a file, return your certificate data as json string.
		This makes it easy to share it via text-messengers such as teams or discord.
	
	.EXAMPLE
		PS C:\> Export-PseCertificate -Path .\psencrypt-certificate.json
		
		Exports you own PSEncrypt certificate to .\psencrypt-certificate.json
		Provide this to a recipient you intend to exchange data with securely.

	.EXAMPLE
		PS C:\> Export-PseCertificate -PassThru | Set-Clipboard
		
		Exports you own PSEncrypt certificate as json string and writes it to your clipboard.
		Provide this to a recipient you intend to exchange data with securely.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Path,

		[switch]
		$PassThru
	)

	begin {
		if (-not $Path -and -not $PassThru) {
			$Path = Show-SaveFileDialog -Filter 'Json Files (*.json)|*.json'
			if (-not $Path) {
				throw "no export path found! Specify Path or use the UI prompt to specify an export path!"
			}
		}
	}
	process {
		$cert = Get-PseCertificate -Current | ForEach-Object Certificate
		if (-not $cert) {
			throw "No PSEncrypt certificate found, use New-PseCertificate to create one!"
		}

		$certBytes = $cert.GetRawCertData()

		$data = @{
			Name = $cert.Subject -replace '^CN=|, O=PSEncrypt$'
			Cert = [Convert]::ToBase64String($certBytes)
		}
		if ($PassThru) { return $data | ConvertTo-Json }
		$data | ConvertTo-Json | Set-Content -Path $Path
	}
}