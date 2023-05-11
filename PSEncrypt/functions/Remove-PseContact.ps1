function Remove-PseContact
{
	<#
	.SYNOPSIS
	Remove a contact from the list of known PSEncrypt contacts.
	
	.DESCRIPTION
	Remove a contact from the list of known PSEncrypt contacts.
	This deletes the public certificates needed to send new protected files or verify protected data sent by the contact deleted.
	
	.PARAMETER Name
	Name of the contact to remove
	
	.EXAMPLE
	PS C:\> Remove-PseContact -Name fred@contoso.com

	Removes the PSEncrypt contact "fred@contoso.com"
	#>
	[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
		[string[]]
		$Name
	)
	
	process
	{
		foreach ($entry in $Name) {
			$contact = $null
			$contact = Get-PseContact -Name $entry
			if (-not $contact) { continue }

			$badCharacters = [System.IO.Path]::GetInvalidFileNameChars() -replace '\\', '\\' -replace '\|','\|' -join '|'
			$exportPath1 = Join-Path -Path $script:certFolder -ChildPath "$($contact.Name -replace $badCharacters,'_').clixml"
			$exportPath2 = Join-Path -Path $script:certFolder -ChildPath "$($contact.Thumbprint).clixml"

			if (Test-Path $exportPath1) { Remove-Item -Path $exportPath1 }
			if (Test-Path $exportPath2) { Remove-Item -Path $exportPath2 }
		}
	}
}
