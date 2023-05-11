function Unprotect-PseDocument {
	<#
	.SYNOPSIS
		Decrypts data or file encrypted with PSEncrypt for the current user.
	
	.DESCRIPTION
		Decrypts data or file encrypted with PSEncrypt for the current user.
		The encrypted data must have been generated using Protect-PseDocument with the current user as its recipient.

		The data will be verified with the signature included in the data against the certificate of the contact representing the sender.
		Data from untrusted sources - senders that are not in the list of contacts of the current user - will be rejected.

		To include the sender as a trusted sender, have the sender use Export-PseCertificate to provide the contact information,
		and use Import-PseContact to use that contact information and add the sender to your contacts.
	
	.PARAMETER Path
		Path to the file to decrypt.
		Decrypted file will be created in the same path, unless OutPath is specified.
	
	.PARAMETER Content
		The json string containing data encrypted by PSEncrypt.
		If the original content was a file, specfying an OutPath becomes mandatory.
	
	.PARAMETER OutPath
		Path in which to generate the decrypted document.
		By default, encrypted files will be written in the same path as the original file and encrypted string content will be returned as decrypted string.
	
	.EXAMPLE
		PS C:\> Unprotect-PseDocument -Path .\report.xlsx.json

		Decrypts "report.xlsx.json" in the same path under the original filename (probably "report.xlsx")
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ParameterSetName = 'File', ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[Alias('FullName')]
		[string[]]
		$Path,

		[Parameter(Mandatory = $true, ParameterSetName = 'Content', ValueFromPipelineByPropertyName = $true)]
		[string]
		$Content,

		[string]
		$OutPath
	)
	
	begin {
		function Unprotect-Dataset {
			[CmdletBinding()]
			param (
				[string]
				$Content,

				[AllowEmptyString()]
				[string]
				$OutPath,

				$Cmdlet
			)

			try { $config = $Content | ConvertFrom-Json -ErrorAction Stop }
			catch {
				$Cmdlet.WriteError($_)
				return
			}

			if ($config.Type -eq 'File' -and -not $OutPath) {
				$record = New-ErrorRecord -Message "Invalid configuration: File provided without an OutPath: $($config.Name)" -ErrorID 'BadParameters' -Category InvalidArgument -Target $config
				$Cmdlet.WriteError($record)
				return
			}

			$recipientCert = Get-Item "Cert:\CurrentUser\My\$($config.CryptThumbprint)" -ErrorAction Ignore
			if (-not $recipientCert) {
				$record = New-ErrorRecord -Message "Cannot find certificate $($config.CryptThumbprint) to decrypt data: $($config.Name)" -ErrorID 'CertNotFound' -Category InvalidArgument -Target $config
				$Cmdlet.WriteError($record)
				return
			}
			
			$senderCert = Get-PseContact | Where-Object ThumbPrint -EQ $config.SignThumbprint | ForEach-Object Certificate
			if (-not $senderCert) {
				$record = New-ErrorRecord -Message "Cannot find certificate $($config.SignThumbprint) to verify the sender: $($config.Name)" -ErrorID 'CertNotFound' -Category InvalidArgument -Target $config
				$Cmdlet.WriteError($record)
				return
			}

			if (-not $config.Data -or -not $config.Signature) {
				$record = New-ErrorRecord -Message "Missing Data to decrypt or signature to verify: $($config.Name)" -ErrorID 'BadConfig' -Category InvalidArgument -Target $config
				$Cmdlet.WriteError($record)
				return
			}

			try {
				$bytesData = [convert]::FromBase64String($config.Data)
				$bytesSignature = [convert]::FromBase64String($config.Signature)
			}
			catch {
				$record = New-ErrorRecord -Message "Invalid format for data or signature: $($config.Name)" -ErrorID 'BadConfig' -Category InvalidArgument -Target $config
				$Cmdlet.WriteError($record)
				return
			}

			$isFromSender = $senderCert.PublicKey.GetRSAPublicKey().VerifyData($bytesData, $bytesSignature, [System.Security.Cryptography.HashAlgorithmName]::SHA512, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
			if (-not $isFromSender) {
				$record = New-ErrorRecord -Message "Invalid signature! $($config.Name) could not be verified to come from $($senderCert.Subject) ($($senderCert.Thumbprint))!" -ErrorID 'InvalidSignature' -Category InvalidData -Target $config
				$Cmdlet.WriteError($record)
				return
			}

			try { $decryptedBytes = $recipientCert.PrivateKey.Decrypt($bytesData, [System.Security.Cryptography.RSAEncryptionPadding]::Pkcs1) }
			catch {
				$record = New-ErrorRecord -Message "Error decrypting data! $($config.Name) could not be decrypted wth $($recipientCert.Subject) ($($recipientCert.Thumbprint)): $_" -ErrorID 'InvalidCert' -Category InvalidData -Target $config
				$Cmdlet.WriteError($record)
				return
			}

			if ($config.Type -eq 'Content') {
				$content = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
				if (-not $OutPath) { return $content }

				$exportPath = Join-Path -Path $OutPath -ChildPath $config.Name
				$content | Set-Content -Path $exportPath -Encoding UTF8
				Write-Host "Unporotected file written to: $exportPath"
			}
			else {
				$exportPath = Join-Path -Path $OutPath -ChildPath $config.Name
				[System.IO.File]::WriteAllBytes($exportPath, $decryptedBytes)
				Write-Host "Unporotected file written to: $exportPath"
			}
		}
	}
	process {
		if ($Content) {
			Unprotect-Dataset -Content $Content -OutPath $OutPath -Cmdlet $PSCmdlet
		}
		foreach ($file in Resolve-PathEx -Path $Path -Type File -Mode AnyWarning -Provider FileSystem | ForEach-Object Path) {
			$root = Split-Path $file
			if ($OutPath) { $root = $OutPath }
			Write-Verbose "Unprotecting: $file to $root"
			Unprotect-Dataset -Content ([System.IO.File]::ReadAllText($file)) -OutPath $root -Cmdlet $PSCmdlet
		}
	}
}
