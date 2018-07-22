function Get-Enlightenment {
    <#
	.NOTES
		Name: Get-Enlightenment
		Author: vexx32
	.SYNOPSIS
		Reflect on your progress and check your answers.
	.DESCRIPTION
        Get-Enlightenment executes Pester against the koans to evaluate if you have made the necessary
        corrections for success.
	.PARAMETER Meditate
		Opens your local koan folder.
	.PARAMETER Reset
        Resets everything in your local koan folder to a blank slate. Use with caution.
    .EXAMPLE
        PS> Get-Enlightenment

        Assesses the results of the Pester tests, and builds the meditation prompt.
    .EXAMPLE
        PS> rake

        Assesses the results of the Pester tests, and builds the meditation prompt.
    .EXAMPLE
        PS> rake -Meditate

        Opens the user's koans folder, housed in $home\PSKoans
    .EXAMPLE
        PS> rake -Reset

        Prompts for confirmation, before wiping out the user's koans folder and restoring it back
        to its initial state.
	#>
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "Default")]
    [Alias('Rake', 'Invoke-PSKoans', 'Test-Koans')]
    param(
        [Parameter(Mandatory, ParameterSetName = "Meditate")]
        [switch]
        $Meditate,

        [Parameter(Mandatory, ParameterSetName = "Reset")]
        [switch]
        $Reset
    )
    switch ($PSCmdlet.ParameterSetName) {
        "Reset" {
            Initialize-KoanDirectory
        }
        "Meditate" {
            Invoke-Item $script:KoanFolder
        }
        "Default" {
            Clear-Host

            Write-MeditationPrompt -Greeting

            $PesterTestCount = Invoke-Pester -Script $script:KoanFolder -PassThru -Show None |
                Select-Object -ExpandProperty TotalCount

            $SortedKoanList = Get-ChildItem "$script:KoanFolder" -Recurse -Filter '*.Tests.ps1' |
                Get-Command {$_.FullName} |
                Where-Object {$_.ScriptBlock.Attributes.TypeID -match 'KoanAttribute'} |
                Sort-Object {$_.ScriptBlock.Attributes.Where{$_.TypeID -match 'KoanAttribute'}.Position} |
                Select-Object -ExpandProperty Path

            $KoansPassed = 0

            foreach ($KoanFile in $SortedKoanList) {
                $PesterTests = Invoke-Pester -Script $KoanFile -PassThru -Show None
                $KoansPassed += $PesterTests.PassedCount

                if ($PesterTests.FailedCount -gt 0) {
                    break
                }
            }

            if ($PesterTests.FailedCount -gt 0) {
                $NextKoanFailed = $PesterTests.TestResult |
                    Where-Object Result -eq 'Failed' |
                    Select-Object -First 1

                $Meditation = @{
                    DescribeName = $NextKoanFailed.Describe
                    Expectation  = $NextKoanFailed.ErrorRecord
                    ItName       = $NextKoanFailed.Name
                    Meditation   = $NextKoanFailed.StackTrace
                    KoansPassed  = $KoansPassed
                    TotalKoans   = $PesterTestCount
                }
                Write-MeditationPrompt @Meditation
            }
            else {
                $Meditation = @{
                    Complete    = $true
                    KoansPassed = $KoansPassed
                    TotalKoans  = $PesterTestCount
                }
                Write-MeditationPrompt @Meditation
            }
        }
    }
} # end function
function Get-Blank {
	[Alias('__', 'FILL_ME_IN')]
	param()
	$null
}
function Write-MeditationPrompt {
    <#
	.NOTES
		Name: Write-MeditationPrompt
		Author: vexx32
	.SYNOPSIS
		Provides "useful" output for enlightenment results.
	.DESCRIPTION
		Provides a mechanism for Get-Enlightenment to write clean output.
	#>
    [CmdletBinding(DefaultParameterSetName = 'Meditation')]
    param(
        [Parameter(Mandatory, ParameterSetName = "Meditation")]
        [ValidateNotNullOrEmpty()]
        [string]
        $DescribeName,

        [Parameter(Mandatory, ParameterSetName = "Meditation")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Expectation,

        [Parameter(Mandatory, ParameterSetName = "Meditation")]
        [ValidateNotNullOrEmpty()]
        [string]
        $ItName,

        [Parameter(Mandatory, ParameterSetName = "Meditation")]
        [ValidateNotNullOrEmpty()]
        [string]
        $Meditation,

        [Parameter(Mandatory, ParameterSetName = "Meditation")]
        [Parameter(Mandatory, ParameterSetName = 'Enlightened')]
        [ValidateNotNull()]
        [int]
        $KoansPassed,

        [Parameter(Mandatory, ParameterSetName = "Meditation")]
        [Parameter(Mandatory, ParameterSetName = 'Enlightened')]
        [ValidateNotNull()]
        [int]
        $TotalKoans,

        [Parameter(Mandatory, ParameterSetName = 'Greeting')]
        [switch]
        $Greeting,

        [Parameter(Mandatory, ParameterSetName = 'Enlightened')]
        [switch]
        $Complete
    )

    $Red = @{ForegroundColor = "Red"}
    $Blue = @{ForegroundColor = "Cyan"}
    $Koan = $Script:ZenSayings | Get-Random
    $SleepTime = @{Milliseconds = 50}

    #region Prompt Text
    $Prompts = @{
        Welcome        = @"
    Welcome, seeker of enlightenment.
    Please wait a moment while we examine your karma...

"@
        Describe       = @"
{Describe "$DescribeName"} has damaged your karma.
"@
        TestFailed     = @"

    You have not yet reached enlightenment.

    The answers you seek...

"@
        Expectation    = $Expectation
        Meditate       = @"

    Please meditate on the following code:

"@
        Subject        = @"
[It] $ItName
$Meditation
"@
        Wisdom         = @"

    $($Koan -replace "`n","`n    ")

    Your path thus far:

"@
        OpenFolder     = @"

You may run 'rake -Meditate' to begin your meditation.

"@
        Completed      = @"
    Congratulations! You have taken the first steps towards enlightenment.

    You cast your gaze back upon the path that you have walked:

"@
        BookSuggestion = @"

    If you would like to further your studies in this manner, consider investing in
    'PowerShell by Mistake' by Don Jones - https://leanpub.com/powershell-by-mistake
"@
    }
    #endregion Prompt Text

    switch ($PSCmdlet.ParameterSetName) {
        'Greeting' {
            Write-Host -ForegroundColor Cyan $Prompts['Welcome']
            break
        }
        'Meditation' {
            Write-Host @Red $Prompts['Describe']
            Start-Sleep @SleepTime
            Write-Host @Blue $Prompts['TestFailed']
            Write-Host @Red $Prompts['Expectation']
            Start-Sleep @SleepTime
            Write-Host @Blue $Prompts['Meditate']
            Write-Host @Red $Prompts['Subject']
            Start-Sleep @SleepTime
            Write-Host @Blue $Prompts['Wisdom']

            $ProgressAmount = "$KoansPassed/$TotalKoans"
            [int]$ProgressWidth = $host.UI.RawUI.WindowSize.Width * 0.8 - ($ProgressAmount.Length + 4)
            $PortionDone = ($KoansPassed / $TotalKoans) * $ProgressWidth

            " [{0}{1}] {2}" -f @(
                "$([char]0x25a0)" * $PortionDone
                "$([char]0x2015)" * ($ProgressWidth - $PortionDone)
                $ProgressAmount
            ) | Write-Host @Blue

            Write-Host @Blue $Prompts['OpenFolder']
            break
        }
        'Enlightened' {
            Write-Host @Blue $Prompts['Completed']

            $ProgressAmount = "$KoansPassed/$TotalKoans"
            [int]$ProgressWidth = $host.UI.RawUI.WindowSize.Width * 0.8 - ($ProgressAmount.Length + 4)
            $PortionDone = ($KoansPassed / $TotalKoans) * $ProgressWidth

            " [{0}{1}] {2}" -f @(
                "$([char]0x25a0)" * $PortionDone
                "$([char]0x2015)" * ($ProgressWidth - $PortionDone)
                $ProgressAmount
            ) | Write-Host @Blue

            Write-Host @Blue $Prompts['BookSuggestion']
            break
        }
    }
}
function Initialize-KoanDirectory {
    <#
	.NOTES
		Name: Initialize-KoanDirectory
		Author: vexx32
	.SYNOPSIS
		Provides a blank slate for Koans.
	.DESCRIPTION
        If Koans folder already exists, the folder(s) are overwritten. Otherwise a new folder
        structure is produced.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param()
    if ($PSCmdlet.ShouldProcess($script:KoanFolder, "Restore the koans to a blank slate")) {
        if (Test-Path -Path $script:KoanFolder) {
            Write-Verbose "Removing the entire koans folder..."
            Remove-Item -Recurse -Path $script:KoanFolder -Force
        }
        Write-Debug "Copying koans to folder"
        Copy-Item -Path "$PSScriptRoot/Koans" -Recurse -Destination $script:KoanFolder
        Write-Verbose "Koans copied to '$script:KoanFolder'"
    }
    else {
        Write-Verbose "Operation cancelled; no modifications made to koans folder."
    }
}

$script:ZenSayings = Import-CliXml -Path ($PSScriptRoot | Join-Path -ChildPath "Data/Meditations.clixml")
$script:KoanFolder = $Home | Join-Path -ChildPath 'PSKoans'

if (-not (Test-Path -Path $script:KoanFolder)) {
	Initialize-KoanDirectory -Confirm:$false
}