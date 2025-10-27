<#
.SYNOPSIS
    An automated physical print test suite for the LarkTool command-line utility.

.DESCRIPTION
    This script runs a comprehensive matrix of physical print tests against the 
    LarkTool.exe executable. It iterates through all combinations of resolutions, 
    speeds, and darkness levels. The output provides a real-time summary of 
    the pass/fail status for each test.

.PARAMETER BuildConfiguration
    Specifies the build configuration to test (e.g., 'Debug' or 'Release').

.PARAMETER ResolutionFilter
    An array of strings to filter which resolutions to test (e.g., -ResolutionFilter "quarter","eighth").

.PARAMETER Verbose
    Enables verbose output from the LarkTool executable for each test.

.EXAMPLE
    # Run the full test suite against the Release build.
    .\run_physical_print_suite.ps1 -BuildConfiguration Release

.EXAMPLE
    # Run tests for only 'quarter' and 'eighth' resolutions with verbose output.
    .\run_physical_print_suite.ps1 -ResolutionFilter "quarter","eighth" -Verbose
	
.NOTES
    Author:      HamSlices 2025
    Version:     1.1
	
#>

# ============================================================================
# ==                       SCRIPT PARAMETERS                                ==
# ============================================================================
param(
    [ValidateSet('Debug', 'Release')]
    [string]$BuildConfiguration = 'Release',

    [string[]]$ResolutionFilter,
    
    [Alias('v')]
    [switch]$Verbose
)

# ============================================================================
# ==                       CONFIGURATION SECTION                            ==
# ============================================================================
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExecutableName = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "x64\$BuildConfiguration\LarkTool.exe")).Path
$ExecFilenameOnly = Split-Path -Path $ExecutableName -Leaf

# --- Add the executable's directory to the PATH for DLL resolution ---
$ExecDirectory = Split-Path -Path $ExecutableName -Parent
$env:PATH = "$ExecDirectory;$($env:PATH)"

# --- Visual Flair Configuration ---
$Flair = @{
    Pass          = "[PASS]"
    Fail          = "[FAIL]"
    PassColor     = "Green"
    FailColor     = "Red"
    HeaderColor   = "Cyan"
    TitleColor    = "White"
    CommandColor  = "Gray"
    SummaryColor  = "Yellow"
}

# --- Test Matrix Configuration ---
$TestImageFile   = "test_files\star.png"
$PrintJobDelay   = 800 # Milliseconds to wait for a print to finish
$ConstantArgs    = @("--dither", "threshold", "--units", "imperial")

# Strobe mode is removed as it's no longer a feature.
$Resolutions     = @('full', 'half', 'quarter', 'eighth')
$Speeds          = @(1, 2, 3, 4, 5, 6, 7, 8) 
$DarknessLevels  = @(0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100) 

# ============================================================================
# ==                      INITIALIZATION AND CHECKS                         ==
# ============================================================================
Clear-Host
Write-Host "Lark Device - Physical Print Test Suite" -ForegroundColor $Flair.SummaryColor

$global:TestsPassed = 0
$global:TestsFailed = 0

if (-not (Test-Path $ExecutableName)) {
    Write-Error "Executable not found at '$ExecutableName'. Please ensure the project has been built."
    exit 1
}

# --- Filter the resolution list if a filter is provided ---
if ($PSBoundParameters.ContainsKey('ResolutionFilter')) {
    $Resolutions = $Resolutions | Where-Object { $_ -in $ResolutionFilter }
}

$TotalTests = ($Resolutions.Count * $Speeds.Count * $DarknessLevels.Count)
$TestCounter = 0

# ============================================================================
# ==                      HELPER FUNCTIONS                                  ==
# ============================================================================

function Run-Print-Test {
    param(
        [string]$Resolution,
        [int]$Speed,
        [int]$Darkness
    )

    $global:TestCounter++
    $description = "Res=$Resolution, Speed=$($Speed).0ips, Dark=$($Darkness).0%"
    Write-Host "`n--- TEST [$global:TestCounter / $TotalTests]: $description" -ForegroundColor $Flair.TitleColor

    $finalArgs = @("--print", $TestImageFile) + $ConstantArgs + @(
        "--resolution", $Resolution,
        "--speed", "$($Speed).0",
        "--darkness", "$($Darkness).0"
    )
    if ($Verbose) { $finalArgs += "-v" }

    Write-Host "    Action: $ExecFilenameOnly $($finalArgs -join ' ')" -ForegroundColor $Flair.CommandColor
    
    $output = ""
    try {
        # Execute the command, capturing all output streams into the $output variable
        $output = & $ExecutableName @finalArgs 2>&1 | Out-String
    } catch {
        # This catches terminating errors from PowerShell itself
        $output = $_.Exception.Message
    }
    
    $exitCode = $LASTEXITCODE

    if ($Verbose -and $output) {
        Write-Host "    Output:"
        $output.Trim() -split "`r`n" | ForEach-Object { Write-Host "      $_" }
    }
    
    $testPassed = ($exitCode -eq 0)

    Write-Host "    Status: " -NoNewline
    if ($testPassed) {
        Write-Host "$($Flair.Pass)" -ForegroundColor $Flair.PassColor -NoNewline
        $global:TestsPassed++
    } else {
        Write-Host "$($Flair.Fail)" -ForegroundColor $Flair.FailColor -NoNewline
        $global:TestsFailed++
    }
    Write-Host " (Got Exit Code: $exitCode)"

    Write-Host "    Waiting $PrintJobDelay milliseconds for print to complete..."
    Start-Sleep -Milliseconds $PrintJobDelay
}

# ============================================================================
# ==                         TEST EXECUTION                                 ==
# ============================================================================

Write-Host "This script will run a total of $TotalTests test combinations."
Read-Host -Prompt "Press Enter to begin the automated tests"

foreach ($res in $Resolutions) {
    foreach ($speed in $Speeds) {
        foreach ($darkness in $DarknessLevels) {
            Run-Print-Test -Resolution $res -Speed $speed -Darkness $darkness
        }
    }
}

# ============================================================================
# ==                              SUMMARY                                   ==
# ============================================================================
function Write-Summary-Box {
    $width = 61
    
    function Write-Summary-Line ($StatusText, $Count, $StatusColor) {
        $leftPad = "  "; $rightPad = "  "
        $coloredPart = $StatusText; $uncoloredPart = ": " + $Count
        $contentLength = $leftPad.Length + $coloredPart.Length + $uncoloredPart.Length + $rightPad.Length
        $flexiblePadding = " " * ($width - $contentLength)

        Write-Host "|" -ForegroundColor $Flair.SummaryColor -NoNewline; Write-Host $leftPad -NoNewline
        Write-Host $coloredPart -ForegroundColor $StatusColor -NoNewline
        Write-Host $uncoloredPart -NoNewline; Write-Host $flexiblePadding -NoNewline
        Write-Host $rightPad -NoNewline; Write-Host "|" -ForegroundColor $Flair.SummaryColor
    }
    
    $titleText = "PHYSICAL PRINT TEST SUITE - SUMMARY"
    if ($PSBoundParameters.ContainsKey('ResolutionFilter')) { $titleText = "FILTERED TEST RUN - SUMMARY" }
    $paddingWidth = $width - $titleText.Length; $leftPad = [math]::Floor($paddingWidth / 2); $rightPad = [math]::Ceiling($paddingWidth / 2)
    $titlePadded = (" " * $leftPad) + $titleText + (" " * $rightPad)

    $topBorder = "+$("=" * $width)+"; $bottomBorder = $topBorder; $separator = "+$("-" * $width)+"

    Write-Host "`n$topBorder" -ForegroundColor $Flair.SummaryColor
    Write-Host "|$titlePadded|" -ForegroundColor $Flair.SummaryColor
    Write-Host $separator -ForegroundColor $Flair.SummaryColor
    
    Write-Summary-Line $Flair.Pass $global:TestsPassed $Flair.PassColor
    Write-Summary-Line $Flair.Fail $global:TestsFailed $Flair.FailColor
    
    Write-Host $bottomBorder -ForegroundColor $Flair.SummaryColor; Write-Host ""

    if ($global:TestsFailed -gt 0) {
        Write-Host "********************** SOME TESTS FAILED! **********************" -ForegroundColor $Flair.FailColor
        exit 1
    } else {
        Write-Host "          All physical print tests passed successfully!         " -ForegroundColor $Flair.PassColor
        exit 0
    }
}

Write-Summary-Box