function Protect-PseDocument {
	<#
	.SYNOPSIS
	Encrypt a document for a specific recipient and sign it with your own certificate.
	
	.DESCRIPTION
	Encrypt a document for a specific recipient and sign it with your own certificate.

	Can protect both files and string content.

	Files:
	- When only providing a path, it will create a new file, appending ".json" in the same path.
	- When also providing an "OutPath", it will create a new file, appending ".json", and write it to that path.
	- When specifying -PassThru, the resultant json string will be returned as output.

	Content:
	- Will be returned as protected json string.
	
	.PARAMETER Recipient
	The recipient to encrypt the data for.
	Use Import-PseContact to add a valid recipient, have your contact use Export-PseCertificate to generate the data consumed by Import-PseContact.
	
	.PARAMETER Path
	Path to the file to protect.
	
	.PARAMETER Content
	String content to protect-
	
	.PARAMETER Name
	Name to assign to the Content.
	By default, a GUID and date are used.
	
	.PARAMETER PassThru
	Whether to return the protected json data as string, rather than writing files.
	
	.PARAMETER OutPath
	Path in which to write protected files.
	Must be a folder that exists.
	By default, protected files are stored in the same path as the original input file.
	
	.EXAMPLE
	PS C:\> Protect-PseDocument -Recipient fred@contoso.com -Path .\security-roadmap.pptx
	
	Creates a protected file from "security-roadmap.pptx" named "security-roadmap.pptx.json" in the same path as the original file.
	Only the intended recipient "fred@contoso.com" should have the certificate to decrypt this document.
	The recipient can also verify, that the file was originally protected by the current user.
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding(DefaultParameterSetName = 'File')]
	Param (
		[Parameter(Mandatory = $true)]
		[string]
		$Recipient,

		[Parameter(Mandatory = $true, ParameterSetName = 'File', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[string[]]
		$Path,

		[Parameter(Mandatory = $true, ParameterSetName = 'Content', ValueFromPipelineByPropertyName = $true)]
		[string]
		$Content,

		[Parameter(ParameterSetName = 'Content', ValueFromPipelineByPropertyName = $true)]
		[string]
		$Name = "$([guid]::NewGuid())-$(Get-Date -Format yyyy-MM-dd)",

		[Parameter(ParameterSetName = 'File')]
		[switch]
		$PassThru,

		[Parameter(ParameterSetName = 'File')]
		[string]
		$OutPath
	)
	
	begin {
		#region Functions
		function Protect-Content {
			[CmdletBinding()]
			param (
				[string]
				$Content,

				[string]
				$Name,

				[System.Security.Cryptography.X509Certificates.X509Certificate2]
				$OwnCertificate,

				$Contact
			)

			$bytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
			$bytesEncrypted = $Contact.Certificate.PublicKey.GetRSAPublicKey().Encrypt($bytes, [System.Security.Cryptography.RSAEncryptionPadding]::Pkcs1)
			$bytesSignature = $OwnCertificate.PrivateKey.SIgnData($bytesEncrypted, [System.Security.Cryptography.HashAlgorithmName]::SHA512, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

			@{
				Name            = $Name
				Recipient       = $Contact.Name
				Type            = 'Content'
				SignThumbprint  = $OwnCertificate.Thumbprint
				CryptThumbprint = $Contact.Certificate.Thumbprint
				Data            = [convert]::ToBase64String($bytesEncrypted)
				Signature       = [convert]::ToBase64String($bytesSignature)
			} | ConvertTo-Json
		}

		function Protect-File {
			[CmdletBinding()]
			param (
				[string]
				$Path,

				[System.Security.Cryptography.X509Certificates.X509Certificate2]
				$OwnCertificate,

				$Contact,

				[switch]
				$PassThru,

				[AllowEmptyString()]
				[string]
				$OutPath
			)

			$bytes = [System.IO.File]::ReadAllBytes($Path)
			$bytesEncrypted = $Contact.Certificate.PublicKey.GetRSAPublicKey().Encrypt($bytes, [System.Security.Cryptography.RSAEncryptionPadding]::Pkcs1)
			$bytesSignature = $OwnCertificate.PrivateKey.SignData($bytesEncrypted, [System.Security.Cryptography.HashAlgorithmName]::SHA512, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)

			$fileName = Split-Path -Path $Path -Leaf
			$data = @{
				Name            = $fileName
				Recipient       = $Contact.Name
				Type            = 'File'
				SignThumbprint  = $OwnCertificate.Thumbprint
				CryptThumbprint = $Contact.Certificate.Thumbprint
				Data            = [convert]::ToBase64String($bytesEncrypted)
				Signature       = [convert]::ToBase64String($bytesSignature)
			} | ConvertTo-Json

			if ($PassThru) { $data }
			if ($OutPath) {
				$newPath = Join-Path -Path $OutPath -ChildPath "$($fileName).json"
				$data | Set-Content -Path $newPath
				Write-Host "Protected file created at: $newPath"
			}
			if (-not $PassThru -and -not $OutPath) {
				$data | Set-Content -Path "$Path.json"
				Write-Host "Protected file created at: $Path.json"
			}
		}
		#endregion Functions

		$ownCertificate = Get-PseCertificate -Current | ForEach-Object Certificate
		if (-not $ownCertificate) {
			$record = New-ErrorRecord -Message 'No applicable user certificate found! Use New-PseCertificate to register a certificate to use.' -ErrorID 'CertNotFound' -Category ObjectNotFound
			$PSCmdlet.ThrowTerminatingError($record)
		}

		$contact = Get-PseContact | Where-Object {
			$_.Name -eq $Recipient -or
			$_.Thumbprint -eq $Recipient
		} | Sort-Object NotAfter -Descending | Select-Object -First 1

		if (-not $contact) {
			$record = New-ErrorRecord -Message "Contact $Recipient not found! Check your spelling against Get-PseContact or use Import-PseContact to import a new contact. Your contact can generate the import data using Export-PseCertificate." -ErrorID 'ContactNotFound' -Category ObjectNotFound
			$PSCmdlet.ThrowTerminatingError($record)
		}
	}
	process {
		switch ($PSCmdlet.ParameterSetName) {
			'File' {
				foreach ($file in Resolve-PathEx -Path $Path -Type File -Mode AnyWarning -Provider FileSystem | ForEach-Object Path) {
					Protect-File -Path $file -OwnCertificate $ownCertificate -Contact $contact -PassThru:$PassThru -OutPath $OutPath
				}
			}
			'Content' {
				Protect-Content -Content $Content -Name $Name -OwnCertificate $ownCertificate -Contact $contact
			}
		}
	}
}
