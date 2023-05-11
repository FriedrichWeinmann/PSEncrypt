function Set-PseCertificate {
	<#
	.SYNOPSIS
		Configure the certificate to use for PSEncrypt.
	
	.DESCRIPTION
		Configure the certificate to use for PSEncrypt.
		The certificate in question must support document signing and document encryption, otherwise it will fail.
		This command includes no validation!
		For a simple self-start with a self-signed certificate use New-PseCertificate instead.

		Documents encrypted for previous certificates will still be decryptable, so long as the old certificate is still available.
	
	.PARAMETER Thumbprint
		Thumbprint of the certificate to use.
	
	.PARAMETER FriendlyName
		Friendly name of the certificate to use.
		Will always select the certificate with the latest expiration date.
	
	.PARAMETER Subject
		Select a certificate by its subject name.
		Will always select the certificate with the latest expiration date.
	
	.EXAMPLE
		PS C:\> Set-PseCertificate -Thumbprint $cert.Thumbprint
		
		Registers the certificate stored in $cert as certificate to use.

	.EXAMPLE
		PS C:\> Set-PseCertificate -Subject 'CN=fred@contoso.com'

		Registers the latest certificate with the subject "CN=fred@contoso.com" as certificate to use to encrypt.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
		[string]
		$Thumbprint,

		[Parameter(Mandatory = $true, ParameterSetName = 'FriendlyName')]
		[string]
		$FriendlyName,

		[Parameter(Mandatory = $true, ParameterSetName = 'Subject')]
		[string]
		$Subject
	)

	process {
		$configuration = @{
			CertThumbprint = ''
			CertFriendlyName = ''
			CertSubject = ''
		}
		if ($Thumbprint) { $configuration.CertThumbprint = $Thumbprint }
		if ($FriendlyName) { $configuration.CertFriendlyName = $FriendlyName }
		if ($Subject) { $configuration.CertSubject = $Subject }

		$script:config = $configuration
		$configPath = Join-Path -Path $script:configFolder -ChildPath 'config.clixml'
		$script:config | Export-Clixml -Path $configPath
	}
}