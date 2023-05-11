function New-PseCertificate {
	<#
	.SYNOPSIS
	Generate a new certificate to use as your own PSEncrypt certificate, enabling you to receive encrypted data.
	
	.DESCRIPTION
	Generate a new certificate to use as your own PSEncrypt certificate, enabling you to receive encrypted data.
	This generates a self-signed certificate, useful for quickly enabling use of PSEncrypt.

	If you want to also ensure trusted certificates, instead of using this command, issue a certificate with the friendly name "PSEncrypt Certificate",
	usable for document signing and document encryption (DigitalSignature, DataEncipherment)
	
	.PARAMETER Name
	Name of the certificate to assign.
	By default, it will attempt to read your username from MS Teams if present.
	
	.EXAMPLE
	PS C:\> New-PseCertificate
	
	Creates a new certificate to use as your own PSEncrypt certificate, using your Teams account name as name
	#>
	[CmdletBinding()]
	param (
		[string]
		$Name
	)

	begin {
		if (-not $Name) {
			$Name = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Office\Teams' -ErrorAction Ignore).HomeUserUpn
		}
		if (-not $Name) {
			throw "Name not resolveable, manually specify it through the -Name parameter!"
		}
	}
	process {
		$cert = New-SelfSignedCertificate -KeyUsage DigitalSignature, DataEncipherment -Subject "CN=$Name, O=PSEncrypt" -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddYears(20) -FriendlyName 'PSEncrypt Certificate'
		Get-PseCertificate | Where-Object Thumbprint -EQ $cert.Thumbprint
	}
}