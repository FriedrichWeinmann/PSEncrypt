function Show-SaveFileDialog {
	<#
	.SYNOPSIS
		Shows a visual dialog, prompting the user to pick a path where to write a file to.
	
	.DESCRIPTION
		Shows a visual dialog, prompting the user to pick a path where to write a file to.
	
	.PARAMETER InitialDirectory
		Initial folder from which the user may navigate to wherever.
	
	.PARAMETER Filter
		Filter string to constrain user option on what filetype to save as.
		E.g.: "Json Files (*.json)|*.json"
	
	.PARAMETER Filename
		Default filename, which is offered to the user.
	
	.EXAMPLE
		PS C:\> Show-SaveFileDialog

		Opens a "Save file" dialog in the current path.

	.EXAMPLE
		PS C:\> Show-SaveFileDialog -InitialDirectory $HOME -Filter 'CSV Files (*.csv)|*.csv' -FileName report.csv

		Opens a "Save file" dialog in the user profile, filtering for CSV files with "report.csv" as the default filename.
	#>
    [CmdletBinding()]
    param (
        [string]
        $InitialDirectory = '.',

        [string]
        $Filter = '*.*',
        
        $Filename
    )

	Add-Type -AssemblyName System.Windows.Forms -ErrorAction Ignore
    
    $saveFileDialog = [Windows.Forms.SaveFileDialog]::new()
    $saveFileDialog.FileName = $Filename
    $saveFileDialog.InitialDirectory = Resolve-Path -Path $InitialDirectory
    $saveFileDialog.Title = "Save File to Disk"
    $saveFileDialog.Filter = $Filter
    $saveFileDialog.ShowHelp = $True
    
    $result = $saveFileDialog.ShowDialog()
    if ($result -eq "OK") {
        $saveFileDialog.FileName
    }
}