function Get-PseContact {
	<#
	.SYNOPSIS
		Get a list of all contacts you have registered.
	
	.DESCRIPTION
		Get a list of all contacts you have registered.
		Contacts are acquaintances that have shared teir certificate with you, enabling you to exchange secure files & data with them.
	
	.PARAMETER Name
		The name of the contact to filter by.
		Defaults to '*'
	
	.EXAMPLE
		PS C:\> Get-PseContact

		List all PSEncrypt contacts.

	.EXAMPLE
		PS C:\> Get-PSseContact -Name fred@infernal-associates.org

		Return the PSEncrypt contact with the name fred@infernal-associates.org
	#>
	[CmdletBinding()]
	Param (
		[string]
		$Name = '*'
	)
	
	process {
		Get-ChildItem -Path $script:certFolder | Where-Object Name -Match '^[0-9A-F]{40}\.clixml$' | Import-Clixml | Where-Object Name -Like $Name | ForEach-Object {
			$_.PSObject.TypeNames.Insert(0, 'PSEncrypt.Contact')
			$_
		}
	}
}