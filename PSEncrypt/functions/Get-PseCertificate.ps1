function Get-PseCertificate {
<#
.SYNOPSIS
	Retrieves PSEncrypt certificates.

.DESCRIPTION
	Retrieves certificates used for PSEncrypt.
	These are used to decrypt content intended for you.

.PARAMETER Current
	Specifies to return only the most current certificate.

.EXAMPLE
	PS C:\> Get-PseCertificate

	List all certificates created for PSEncrypt

.EXAMPLE
	PS C:\> Get-PseCertificate -Current

	Retrieves the most current certificate generated for PSEncrypt.
#>
	[CmdletBinding()]
	param (
		[switch]
		$Current
	)

	process {
		$filter = {
			if ($script:config.CertThumbprint -and $_.ThumbPrint -eq $script:config.CertThumbprint) { return $true }
			if ($script:config.CertSubject -and $_.Subject -eq $script:config.CertSubject) { return $true }
			if ($script:config.CertFriendlyName -and $_.FriendlyName -eq $script:config.CertFriendlyName) { return $true }
		}

		$certificates = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object $filter | ForEach-Object {
			[PSCustomObject]@{
				PSTypeName  = 'PSEncrypt.Certificate'
				Subject     = $_.Subject
				NotAfter    = $_.NotAfter
				Thumbprint  = $_.Thumbprint
				Certificate = $_
			}
		}
		if (-not $Current) { return $certificates }

		$certificates | Sort-Object NotAfter -Descending | Select-Object -First 1
	}
}