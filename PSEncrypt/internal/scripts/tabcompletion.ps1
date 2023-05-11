$contactsCompletion = {
	param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

	$contacts = Get-PseContact | ? { ($_.Name -replace "'|`"") -like "$wordToComplete*"}
	foreach ($contact in $contacts) {
		$completion = $contact.Name
		if ($completion -match '\s') { $completion = "'$completion'" }
		[System.Management.Automation.CompletionResult]::new($completion)
	}
}
Register-ArgumentCompleter -CommandName Get-PseContact -ParameterName Name -ScriptBlock $contactsCompletion
Register-ArgumentCompleter -CommandName Protect-PseDocument -ParameterName Recipient -ScriptBlock $contactsCompletion
Register-ArgumentCompleter -CommandName Remove-PseContact -ParameterName Name -ScriptBlock $contactsCompletion