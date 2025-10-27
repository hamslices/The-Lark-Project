<#
.SYNOPSIS
    An automated test script for the LarkTool's print profile functionality.

.DESCRIPTION
    This script tests each profile defined in 'profiles.ini' by executing a 
    corresponding print job with the '--print-preview' option. It verifies that
    LarkTool.exe can correctly parse and apply all defined profiles.

.PARAMETER BuildConfiguration
    Specifies the build configuration to test (e.g., 'Debug' or 'Release').

.PARAMETER Verbose
    Enables verbose output from both the test script and the LarkTool executable.

.EXAMPLE
    # Run all profile tests against the Debug build with verbose output.
    .\test_profiles.ps1 -BuildConfiguration Debug -Verbose

.NOTES
    Author:      HamSlices 2025
    Version:     1.0
#>

# ============================================================================
# ==                       SCRIPT PARAMETERS                                ==
# ============================================================================
param(
    [ValidateSet('Debug', 'Release')]
    [string]$BuildConfiguration = 'Debug',

    [Alias('v')]
    [switch]$Verbose
)

# ============================================================================
# ==                       CONFIGURATION SECTION                            ==
# ============================================================================
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExecutableName = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "x64\$BuildConfiguration\LarkTool.exe")).Path
$ExecFilenameOnly = Split-Path -Path $ExecutableName -Leaf

# --- Add the executable's directory to the PATH ---
$ExecDirectory = Split-Path -Path $ExecutableName -Parent
$env:PATH = "$ExecDirectory;$($env:PATH)"

# --- Visual Flair Configuration ---
$Flair = @{
    Pass          = "[PASS]"
    Fail          = "[FAIL]"
    Skip          = "[SKIP]"
    PassColor     = "Green"
    FailColor     = "Red"
    SkipColor     = "Yellow"
    HeaderColor   = "Cyan"
    TitleColor    = "White"
    CommandColor  = "Gray"
    SummaryColor  = "Yellow"
}

# --- Input File Paths (Dependencies) ---
$ImageFile = "test_files\sm_bird.png"
$PdfFile   = "test_files\sample.pdf"
$TextFile  = "test_files\doc.txt"
$HeaderText = "ATTENTION"

# --- Output Directory and Preview Filenames ---
$PreviewDir = "profile_output"

$ProfilePreviews = @{
    "text-receipt"             = Join-Path $PreviewDir "preview_profile_text-receipt.png"
    "text-notes"               = Join-Path $PreviewDir "preview_profile_text-notes.png"
    "text-header"              = Join-Path $PreviewDir "preview_profile_text-header.png"
    "image-draft"              = Join-Path $PreviewDir "preview_profile_image-draft.png"
    "image-balanced"           = Join-Path $PreviewDir "preview_profile_image-balanced.png"
    "image-high-quality"       = Join-Path $PreviewDir "preview_profile_image-high-quality.png"
    "line-art-and-qr"          = Join-Path $PreviewDir "preview_profile_line-art-and-qr.png"
    "rotated-shipping-label"   = Join-Path $PreviewDir "preview_profile_rotated-shipping-label.png"
    "mirrored-transfer"        = Join-Path $PreviewDir "preview_profile_mirrored-transfer.png"
    "metric-blueprint"         = Join-Path $PreviewDir "preview_profile_metric-blueprint.png"
    "receipt-with-tear-bar"    = Join-Path $PreviewDir "preview_profile_receipt-with-tear-bar.png"
    "event-ticket"             = Join-Path $PreviewDir "preview_profile_event-ticket.png"
    "label-cut-and-feed"       = Join-Path $PreviewDir "preview_profile_label-cut-and-feed.png"
}

# ============================================================================
# ==                      INITIALIZATION AND CHECKS                         ==
# ============================================================================
Clear-Host
Write-Host "LarkTool - Automated Profile Test Plan" -ForegroundColor $Flair.SummaryColor

$global:TestsPassed  = 0
$global:TestsFailed  = 0
$global:TestsSkipped = 0

if (-not (Test-Path $ExecutableName)) {
    Write-Error "Executable not found! Please ensure the project has been built."
    exit 1
}

# ============================================================================
# ==                      HELPER FUNCTIONS                                  ==
# ============================================================================
$global:SectionCounter = 0

function Start-Section ($Title) {
    $global:SectionCounter++
    $width = $Title.Length + 4
    $border = "+$("-" * $width)+";
    Write-Host "`n$border" -ForegroundColor $Flair.HeaderColor
    Write-Host "|  $Title  |" -ForegroundColor $Flair.HeaderColor
    Write-Host "$border" -ForegroundColor $Flair.HeaderColor
}

function Run-Test {
    param(
        [string]$Dependency,
        [string]$Description,
        [string]$ExpectedResult,
        [string[]]$Arguments,
        [switch]$NoDefaultArgs
    )

    Write-Host "`n--- TEST: $Description" -ForegroundColor $Flair.TitleColor

    if ($Dependency -ne "N/A" -and (-not (Test-Path $Dependency))) {
        Write-Host "    Status: " -NoNewline
        Write-Host "$($Flair.Skip)" -ForegroundColor $Flair.SkipColor -NoNewline
        Write-Host " - Required file not found: $Dependency"
        $global:TestsSkipped++
        return
    }

    $finalArgs = @()
    if (-not $NoDefaultArgs -and $Verbose) { $finalArgs += "-vv" } # Use -vv for profile debugging
    $finalArgs += $Arguments

    Write-Host "    Action: $ExecFilenameOnly $($finalArgs -join ' ')" -ForegroundColor $Flair.CommandColor
    
    $output = & $ExecFilenameOnly @finalArgs 2>&1
    $exitCode = $LASTEXITCODE
    
    if ($Verbose) {
        Write-Host "    Output:"
        $output | ForEach-Object { Write-Host "      $_" }
    }

    $testPassed = ($ExpectedResult -eq "PASS" -and $exitCode -eq 0) -or `
                  ($ExpectedResult -eq "FAIL" -and $exitCode -ne 0)

    Write-Host "    Status: " -NoNewline
    if ($testPassed) {
        Write-Host "$($Flair.Pass)" -ForegroundColor $Flair.PassColor -NoNewline
        $global:TestsPassed++
    } else {
        Write-Host "$($Flair.Fail)" -ForegroundColor $Flair.FailColor -NoNewline
        $global:TestsFailed++
    }
    Write-Host " (Expected: $ExpectedResult, Got Exit Code: $exitCode)"
}

# ============================================================================
# ==                         PRE-TEST SETUP                                 ==
# ============================================================================
Write-Host "[SETUP] Ensuring profile output directory exists..."
if (-not (Test-Path $PreviewDir)) { New-Item -ItemType Directory -Path $PreviewDir | Out-Null }

Write-Host "[SETUP] Cleaning up old profile preview files..."
Remove-Item -Path (Join-Path $PreviewDir "*.png") -ErrorAction SilentlyContinue
Write-Host ""

# ============================================================================
# ==                     TEST SECTIONS START HERE                           ==
# ============================================================================

Start-Section "TEST 1: TEXT PROFILES"
Run-Test $TextFile "Profile: text-receipt" "PASS" @("--print", $TextFile, "--profile", "text-receipt", "--print-preview", $ProfilePreviews["text-receipt"])
Run-Test $TextFile "Profile: text-notes" "PASS" @("--print", $TextFile, "--profile", "text-notes", "--print-preview", $ProfilePreviews["text-notes"])
Run-Test "N/A"    "Profile: text-header" "PASS" @("--text", $HeaderText, "--profile", "text-header", "--print-preview", $ProfilePreviews["text-header"])

Start-Section "TEST 2: IMAGE PROFILES"
Run-Test $ImageFile "Profile: image-draft" "PASS" @("--print", $ImageFile, "--profile", "image-draft", "--print-preview", $ProfilePreviews["image-draft"])
Run-Test $ImageFile "Profile: image-balanced" "PASS" @("--print", $ImageFile, "--profile", "image-balanced", "--print-preview", $ProfilePreviews["image-balanced"])
Run-Test $ImageFile "Profile: image-high-quality" "PASS" @("--print", $ImageFile, "--profile", "image-high-quality", "--print-preview", $ProfilePreviews["image-high-quality"])

Start-Section "TEST 3: SPECIALTY PROFILES"
Run-Test $ImageFile "Profile: line-art-and-qr" "PASS" @("--print", $ImageFile, "--profile", "line-art-and-qr", "--print-preview", $ProfilePreviews["line-art-and-qr"])
Run-Test $ImageFile "Profile: rotated-shipping-label" "PASS" @("--print", $ImageFile, "--profile", "rotated-shipping-label", "--print-preview", $ProfilePreviews["rotated-shipping-label"])
Run-Test $ImageFile "Profile: mirrored-transfer" "PASS" @("--print", $ImageFile, "--profile", "mirrored-transfer", "--print-preview", $ProfilePreviews["mirrored-transfer"])
Run-Test $PdfFile   "Profile: metric-blueprint" "PASS" @("--print", $PdfFile, "--profile", "metric-blueprint", "--print-preview", $ProfilePreviews["metric-blueprint"])

Start-Section "TEST 4: PROFILES WITH FINISHING OPTIONS"
Run-Test $TextFile "Profile: receipt-with-tear-bar" "PASS" @("--print", $TextFile, "--profile", "receipt-with-tear-bar", "--print-preview", $ProfilePreviews["receipt-with-tear-bar"])
Run-Test $ImageFile "Profile: event-ticket" "PASS" @("--print", $ImageFile, "--profile", "event-ticket", "--print-preview", $ProfilePreviews["event-ticket"])
Run-Test $ImageFile "Profile: label-cut-and-feed" "PASS" @("--print", $ImageFile, "--profile", "label-cut-and-feed", "--print-preview", $ProfilePreviews["label-cut-and-feed"])

Start-Section "TEST 5: NEGATIVE TESTING (INVALID PROFILE)"
Run-Test $ImageFile "Fail gracefully with non-existent profile" "FAIL" @("--print", $ImageFile, "--profile", "this-profile-does-not-exist")


# ============================================================================
# ==                              SUMMARY                                   ==
# ============================================================================
function Write-Summary-Box {
    $width = 61
    
    function Write-Summary-Line ($StatusText, $Count, $StatusColor) {
        $leftPad = "  "
        $rightPad = "  "
        $coloredPart = $StatusText
        $uncoloredPart = ": " + $Count
        $contentLength = $leftPad.Length + $coloredPart.Length + $uncoloredPart.Length + $rightPad.Length
        $flexiblePadding = " " * ($width - $contentLength)

        Write-Host "|" -ForegroundColor $Flair.SummaryColor -NoNewline; Write-Host $leftPad -NoNewline
        Write-Host $coloredPart -ForegroundColor $StatusColor -NoNewline; Write-Host $uncoloredPart -NoNewline
        Write-Host $flexiblePadding -NoNewline; Write-Host $rightPad -NoNewline
        Write-Host "|" -ForegroundColor $Flair.SummaryColor
    }
    
    $titleText = "PROFILE TESTS COMPLETED - SUMMARY"
    $paddingWidth = $width - $titleText.Length
    $leftPad = [math]::Floor($paddingWidth / 2)
    $rightPad = [math]::Ceiling($paddingWidth / 2)
    $titlePadded = (" " * $leftPad) + $titleText + (" " * $rightPad)

    $topBorder = "+$("=" * $width)+"
    $bottomBorder = $topBorder
    $separator = "+$("-" * $width)+"

    Write-Host "`n$topBorder" -ForegroundColor $Flair.SummaryColor
    Write-Host "|$titlePadded|" -ForegroundColor $Flair.SummaryColor
    Write-Host $separator -ForegroundColor $Flair.SummaryColor
    
    Write-Summary-Line $Flair.Pass $global:TestsPassed $Flair.PassColor
    Write-Summary-Line $Flair.Fail $global:TestsFailed $Flair.FailColor
    Write-Summary-Line $Flair.Skip $global:TestsSkipped $Flair.SkipColor
    
    Write-Host $bottomBorder -ForegroundColor $Flair.SummaryColor
    Write-Host ""

    if ($global:TestsFailed -gt 0) {
        Write-Host "********************** SOME TESTS FAILED! **********************" -ForegroundColor $Flair.FailColor
        exit 1
    } else {
        Write-Host "           All profile tests passed successfully!           " -ForegroundColor $Flair.PassColor
        exit 0
    }
}

Write-Summary-Box