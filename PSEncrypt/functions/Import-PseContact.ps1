function Import-PseContact {
	<#
	.SYNOPSIS
	Imports contact information needed to send encrypted data to the creator of that information.
	
	.DESCRIPTION
	Imports contact information needed to send encrypted data to the creator of that information.
	Reads the clipboard if no other data is provided.
	
	.PARAMETER Path
	Path to the json file containing the contact information.
	
	.PARAMETER Content
	The json string containing the contact information.
	
	.PARAMETER TrustedOnly
	Only accept contact certificates from a trusted root authority.
	By default, any self-signed certificate will do.
	
	.EXAMPLE
	PS C:\> Import-PseContact
	
	Import the json contact data from the clipboard and register it as a new contact.

	.EXAMPLE
	PS C:\> Get-ChildItem .\contacts\*.json | Import-PseContact -TrustedOnly

	Import all the contacs files in the "contacts" subfolder, ensuring only contacts with trusted certificates are imported.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[string[]]
		$Path,

		[string]
		$Content,

		[switch]
		$TrustedOnly
	)
	
	begin {
		function Import-ContactData {
			[CmdletBinding()]
			param (
				[string]
				$Data,

				$Cmdlet,

				[switch]
				$TrustedOnly
			)

			try { $jsonContent = $Data | ConvertFrom-Json -ErrorAction Stop }
			catch {
				$Cmdlet.WriteError($_)
				return
			}

			if (-not $jsonContent.Name -or -not $jsonContent.Cert) {
				$record = New-ErrorRecord -Message 'Invalid json structure - ensure the data provided has been generated through Export-PseCertificate!' -ErrorID InvalidData -Category InvalidData
				$Cmdlet.WriteError($record)
				return
			}

			try {
				$bytes = [Convert]::FromBase64String($jsonContent.Cert)
				$certificate = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new($bytes)
			}
			catch {
				$record = New-ErrorRecord -Message "Invalid certificate data for $($jsonContent.Name) - ensure the data provided has been generated through Export-PseCertificate!" -ErrorID InvalidData -Category InvalidData
				$Cmdlet.WriteError($record)
				return
			}

			if ($TrustedOnly -and -not $certificate.Verify()) {
				$record = New-ErrorRecord -Message "Invalid certificate for $($jsonContent.Name) - the certificate $($certificate.Subject) ($($certificate.ThumbPrint)) is not trusted!" -ErrorID NotTrusted -Category SecurityError
				$Cmdlet.WriteError($record)
				return
			}

			$certData = [PSCustomObject]@{
				PSTypeName  = 'PSEncrypt.Contact'
				Name        = $jsonContent.Name
				Thumbprint  = $certificate.Thumbprint
				NotAfter    = $certificate.NotAfter
				Certificate = $certificate
			}

			$exportPath1 = Join-Path -Path $script:certFolder -ChildPath "$($certData.Name).clixml"
			$exportPath2 = Join-Path -Path $script:certFolder -ChildPath "$($certData.Thumbprint).clixml"
			$certData | Export-Clixml -Path $exportPath1
			$certData | Export-Clixml -Path $exportPath2
			$certData
		}
	}
	process {
		if (-not $Content -and -not $Path) {
			$Content = (Get-Clipboard) -join "`n"
		}
		if ($Content) {
			Import-ContactData -Data $Content -Cmdlet $PSCmdlet -TrustedOnly:$TrustedOnly
		}

		if (-not $Path) { return }
		
		foreach ($file in Resolve-PathEx -Path $Path -Type File -Mode AnyWarning -Provider FileSystem) {
			foreach ($filePath in $file.Path) {
				Write-Verbose "Importing: $filePath"
				$text = [System.IO.File]::ReadAllText($filePath)
				Import-ContactData -Data $text -Cmdlet $PSCmdlet -TrustedOnly:$TrustedOnly
			}
		}
	}
}