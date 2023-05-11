function New-ErrorRecord {
	<#
	.SYNOPSIS
	Generate a new error record object.
	
	.DESCRIPTION
	Generate a new error record object.
	Used to create custom errors.
	
	.PARAMETER Message
	The error message to include.
	
	.PARAMETER ErrorID
	The error ID to provide to the record
	
	.PARAMETER Category
	What kind of error it was.
	
	.PARAMETER Target
	Any target object to include for better analysis options.
	
	.EXAMPLE
	PS C:\> New-ErrorRecord -Message "Something broke".
	
	Creates an error record with a very helpful error message.

	.EXAMPLE
	PS C:\> New-ErrorRecord -Message "Target file not found: $Path" -ErrorID "FileNotFound" -Category ObjectNotFound -Target $Path

	Creates an error record with full metadata.
	#>
	[CmdletBinding()]
	param (
		[string]
		$Message,

		[string]
		$ErrorID = '<undefined>',

		[System.Management.Automation.ErrorCategory]
		$Category = [System.Management.Automation.ErrorCategory]::NotSpecified,

		$Target
	)

	$exception = [System.Exception]::new($Message)
	[System.Management.Automation.ErrorRecord]::new($exception, $ErrorID, $Category, $Target)
}