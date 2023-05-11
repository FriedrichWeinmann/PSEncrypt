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
		$certificates = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object FriendlyName -EQ 'PSEncrypt Certificate' | ForEach-Object {
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