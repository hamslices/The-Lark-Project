<#
.SYNOPSIS
    An automated test plan for the LarkTool command-line utility.

.DESCRIPTION
    This script runs a series of predefined tests against the LarkTool.exe executable,
    providing a visually rich, real-time-updated test report using 100% compatible
    ASCII characters and precise text-only coloring for a professional look on any terminal.

.PARAMETER BuildConfiguration
    Specifies the build configuration to test (e.g., 'Debug' or 'Release').

.PARAMETER Verbose
    Enables verbose output from both the test script and the LarkTool executable.
    
.PARAMETER Section
    A quoted, comma-separated string of section numbers to run (e.g., -Section "1,2,5").

.EXAMPLE
    # Run all tests against the Debug build with verbose output.
    .\unit_test.ps1 -BuildConfiguration Debug -Verbose

.EXAMPLE
    # Run all tests in sections 1 and 2.
    .\unit_test.ps1 -Section "1,2"
	
.NOTES
    Author:      HamSlices 2025
    Version:     1.4
	
#>

# ============================================================================
# ==                       SCRIPT PARAMETERS                                ==
# ============================================================================
param(
    [ValidateSet('Debug', 'Release')]
    [string]$BuildConfiguration = 'Debug',

    [Alias('v')]
    [switch]$Verbose,

    # Accept a single string to avoid PowerShell's array parsing issues.
    [string]$Section
)

# ============================================================================
# ==                       CONFIGURATION SECTION                            ==
# ============================================================================
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExecutableName = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath "x64\$BuildConfiguration\LarkTool.exe")).Path
$ExecFilenameOnly = Split-Path -Path $ExecutableName -Leaf

# --- Add the executable's directory to the PATH ---
# This allows the OS to find the executable and all its required DLLs without
# needing to change the script's working directory.
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

$PrintJobDelay   = 600 # Milliseconds to wait for a print to finish

# --- File Paths ---
$ImageFile = "test_files\sm_bird.png"
$PdfFile   = "test_files\sample.pdf"
$TextFile  = "test_files\doc.txt"
$FontFile  = "C:\Windows\Fonts\consola.ttf"
$SpacedImageFile = "test_files\test image with spaces.png"
$EmptyTextFile = "test_files\empty.txt"
$CorruptImageFile = "test_files\corrupt.png"

$PreviewDir = "unit_test_output"
$ImagePreviewThreshold   = Join-Path $PreviewDir "preview_image_threshold.png"
$ImagePreviewBayer       = Join-Path $PreviewDir "preview_image_bayer.png"
$ImagePreviewFloyd       = Join-Path $PreviewDir "preview_image_floyd.png"
$PdfPreviewBase          = Join-Path $PreviewDir "preview_pdf.png"
$TextPreviewOut          = Join-Path $PreviewDir "preview_text.png"
$ImagePreviewRotated     = Join-Path $PreviewDir "preview_image_rotated.png"
$TextPreviewRotatedPadded= Join-Path $PreviewDir "preview_text_rotated_padded.png"
$ImagePreviewFlipH       = Join-Path $PreviewDir "preview_image_flip_h.png"
$ImagePreviewFlipV       = Join-Path $PreviewDir "preview_image_flip_v.png"
$ImagePreviewFlipHV      = Join-Path $PreviewDir "preview_image_flip_hv.png"
$TextPreviewComposed     = Join-Path $PreviewDir "preview_text_composed.png"
$ImagePreviewScaleUniform= Join-Path $PreviewDir "preview_image_scale_uniform.png"
$ImagePreviewScaleNonUniform = Join-Path $PreviewDir "preview_image_scale_nonuniform.png"
$TextPreviewScaleComposed= Join-Path $PreviewDir "preview_text_scale_composed.png"
$PdfPreviewPage1         = Join-Path $PreviewDir "preview_pdf_page1.png"
$PdfPreviewPageLast      = Join-Path $PreviewDir "preview_pdf_page_last.png"
$PdfPreviewPageAll       = Join-Path $PreviewDir "preview_pdf_all_pages.png"
$TextPreviewAlignLeft    = Join-Path $PreviewDir "preview_text_align_left.png"
$TextPreviewAlignCenter  = Join-Path $PreviewDir "preview_text_align_center.png"
$TextPreviewAlignRight   = Join-Path $PreviewDir "preview_text_align_right.png"
$TextDocPreviewAlignLeft = Join-Path $PreviewDir "preview_text_doc_align_left.png"
$TextDocPreviewAlignCenter = Join-Path $PreviewDir "preview_text_doc_align_center.png"
$TextDocPreviewAlignRight  = Join-Path $PreviewDir "preview_text_doc_align_right.png"
$TextPreviewWrapOff      = Join-Path $PreviewDir "preview_text_wrap_disabled.png"
$TextPreviewWrapOn       = Join-Path $PreviewDir "preview_text_wrap_enabled.png"
$KitchenSinkPreview      = Join-Path $PreviewDir "preview_kitchen_sink.png"
$BenchmarkPreview        = Join-Path $PreviewDir "preview_benchmark.png"
$SpacedImagePreview      = Join-Path $PreviewDir "preview_spaced_image.png"
$TextPreviewEmpty        = Join-Path $PreviewDir "preview_text_empty.png"
$ImagePreviewBrighter    = Join-Path $PreviewDir "preview_image_brighter.png"
$ImagePreviewDarker      = Join-Path $PreviewDir "preview_image_darker.png"
$ImagePreviewHighContrast= Join-Path $PreviewDir "preview_image_high_contrast.png"
$ImagePreviewLowContrast = Join-Path $PreviewDir "preview_image_low_contrast.png"
$TextPreviewAdjusted     = Join-Path $PreviewDir "preview_text_adjusted.png"
$CalibrateDarknessPreview= Join-Path $PreviewDir "preview_calibrate_darkness.png"
$BasePreviewNameDashed   = Join-Path $PreviewDir "preview_dashed.png"
$BasePreviewNameDotted   = Join-Path $PreviewDir "preview_dotted.png"
$BasePreviewNameTriangle = Join-Path $PreviewDir "preview_triangle.png"

$KitchenSinkText = "Complex\nLayout\nTest\nLarkToll.exe Rocks!"

# ============================================================================
# ==                      INITIALIZATION AND CHECKS                         ==
# ============================================================================
Clear-Host
Write-Host "Lark Device - Automated Test Plan" -ForegroundColor $Flair.SummaryColor

$global:TestsPassed  = 0
$global:TestsFailed  = 0
$global:TestsSkipped = 0

if (-not (Test-Path $ExecutableName)) {
    Write-Error "Executable not found! Please ensure the project has been built."
    exit 1
}

# --- Manually parse the -Section string into a reliable array ---
$SectionFilter = @()
if ($Section) {
    try {
        $SectionFilter = $Section.Split(',') | ForEach-Object { [int]$_.Trim() }
    } catch {
        Write-Error "Invalid format for -Section. Please provide a comma-separated list of numbers (e.g., ""1,2,5"")."
        exit 1
    }
}

# ============================================================================
# ==                      HELPER FUNCTIONS                                  ==
# ============================================================================
$global:SectionCounter = 0
$global:ShouldRunCurrentSection = $true

function Start-Section ($Title) {
    $global:SectionCounter++
    $global:ShouldRunCurrentSection = $true
    
    if ($SectionFilter.Count -gt 0) {
        if ($SectionFilter -contains $global:SectionCounter) {
            $global:ShouldRunCurrentSection = $true
        } else {
            $global:ShouldRunCurrentSection = $false
        }
    }
    
    if ($global:ShouldRunCurrentSection) {
        $width = $Title.Length + 4
        $border = "+$("-" * $width)+";
        Write-Host "`n$border" -ForegroundColor $Flair.HeaderColor
        Write-Host "|  $Title  |" -ForegroundColor $Flair.HeaderColor
        Write-Host "$border" -ForegroundColor $Flair.HeaderColor
    }
}

function Run-Test {
    param(
        [string]$Dependency,
        [string]$Description,
        [string]$ExpectedResult,
        [string[]]$Arguments,
        [switch]$NoDefaultArgs
    )

    if (-not $global:ShouldRunCurrentSection) {
        return
    }

    Write-Host "`n--- TEST: $Description" -ForegroundColor $Flair.TitleColor

    if ($Dependency -ne "N/A" -and (-not (Test-Path $Dependency))) {
        Write-Host "    Status: " -NoNewline
        Write-Host "$($Flair.Skip)" -ForegroundColor $Flair.SkipColor -NoNewline
        Write-Host " - Required file not found: $Dependency"
        $global:TestsSkipped++
        return
    }

    $finalArgs = @()
    if (-not $NoDefaultArgs -and $Verbose) { $finalArgs += "-v" }
    $finalArgs += $Arguments

    Write-Host "    Action: $ExecFilenameOnly $($finalArgs -join ' ')" -ForegroundColor $Flair.CommandColor
    
    if ($Verbose) {
        Write-Host "    Output:"
        & $ExecFilenameOnly @finalArgs 2>&1 | ForEach-Object {
            Write-Host "      $_"
        }
    } else {
        $null = & $ExecFilenameOnly @finalArgs 2>&1
    }
    $exitCode = $LASTEXITCODE

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
if ($Section) {
    Write-Host "[INFO] Filtering run to section(s): $($SectionFilter -join ', ')" -ForegroundColor $Flair.SummaryColor
}
Write-Host "[SETUP] Ensuring preview directory exists..."
if (-not (Test-Path $PreviewDir)) { New-Item -ItemType Directory -Path $PreviewDir | Out-Null }

Write-Host "[SETUP] Cleaning up old preview files..."
Remove-Item -Path (Join-Path $PreviewDir "*.png") -ErrorAction SilentlyContinue
Write-Host ""

# ============================================================================
# ==                     TEST SECTIONS START HERE                           ==
# ============================================================================

Start-Section "TEST 1: BASIC COMMANDS"
Run-Test "N/A" "Help Command" "PASS" @("--help")
Run-Test "N/A" "Tool Version" "PASS" @("--version")
Run-Test "N/A" "Firmware Hash" "PASS" @("--verify-firmware")

Start-Section "TEST 2: DEVICE STATUS"
Run-Test "N/A" "Device Status" "PASS" @("--status")

Start-Section "TEST 3: CONFIGURATION GET/SET"
Run-Test "N/A" "Get Metric Config" "PASS" @("--get-config", "--units", "metric")
Run-Test "N/A" "Set Metric Config" "PASS" @("--set-config", "--units", "metric", "--speed", "203.2", "--current", "750", "--darkness", "100.0")
Run-Test "N/A" "Set Imperial Config" "PASS" @("--set-config", "--units", "imperial", "--resolution", "quarter", "--direction", "forward")

Start-Section "TEST 4: NON-VOLATILE FLASH MEMORY"
Run-Test "N/A" "Erase Non-Volatile Memory" "PASS" @("--flash-erase")
Run-Test "N/A" "Set Specific Config for Flash Test" "PASS" @("--set-config", "--units", "metric", "--speed", "150", "--current", "850", "--darkness", "50.0")
Run-Test "N/A" "Save Config to Flash" "PASS" @("--flash-save", "--units", "metric")
Run-Test "N/A" "Load Config from Flash" "PASS" @("--flash-load", "--units", "metric")

Start-Section "TEST 5: MOVEMENT"
Run-Test "N/A" "Move Metric Forward (+25.4mm)" "PASS" @("--move", "25.4", "--units", "metric")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test "N/A" "Move Imperial Forward (+1.0in)" "PASS" @("--move", "1.0", "--units", "imperial")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test "N/A" "Move Metric Reverse (-10.0mm)" "PASS" @("--move", "-10.0", "--units", "metric")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test "N/A" "Move Imperial Reverse (-0.5in)" "PASS" @("--move", "-0.5", "--units", "imperial")
Start-Sleep -Milliseconds $PrintJobDelay

Start-Section "TEST 6: PHYSICAL FILE PRINTING (Connect Device)"
if ($global:ShouldRunCurrentSection) {
    Write-Host "The next commands will print various files. Please ensure media is loaded."
}
Run-Test $PdfFile   "Physical PDF Print" "PASS" @("--print", $PdfFile, "--dither", "threshold")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test $TextFile  "Physical Text Doc Print" "PASS" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "24", "--units", "imperial", "--padding-left", "0.5")
Start-Sleep -Milliseconds $PrintJobDelay

Start-Section "TEST 7: PRINT PREVIEW GENERATION"
Run-Test $ImageFile "Image Preview (Threshold)" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewThreshold, "--dither", "threshold")
Run-Test $ImageFile "Image Preview (Bayer)" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewBayer, "--dither", "bayer")
Run-Test $ImageFile "Image Preview (Floyd)" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewFloyd, "--dither", "floyd")
Run-Test $PdfFile   "PDF Preview" "PASS" @("--print", $PdfFile, "--print-preview", $PdfPreviewBase)
Run-Test $TextFile  "Text Doc Preview" "PASS" @("--print", $TextFile, "--print-preview", $TextPreviewOut, "--font-path", $FontFile, "--font-size", "24")

Start-Section "TEST 8: PDF PAGE RANGE"
Run-Test $PdfFile "PDF Range Preview (First Page Only)" "PASS" @("--print", $PdfFile, "--print-preview", $PdfPreviewPage1, "--dither", "threshold", "--page-start", "1", "--page-end", "1")
Run-Test $PdfFile "PDF Range Preview (Last Page Only)" "PASS" @("--print", $PdfFile, "--print-preview", $PdfPreviewPageLast, "--dither", "threshold", "--page-start", "2", "--page-end", "-1")
Run-Test $PdfFile "PDF Range Preview (All Pages)" "PASS" @("--print", $PdfFile, "--print-preview", $PdfPreviewPageAll, "--dither", "threshold", "--page-start", "1", "--page-end", "-1")

Start-Section "TEST 9: ROTATION PREVIEW"
Run-Test $ImageFile "Rotated Image Preview (15 deg)" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewRotated, "--rotation", "15.0")
Run-Test $TextFile  "Rotated/Padded Text Preview (-10 deg)" "PASS" @("--print", $TextFile, "--print-preview", $TextPreviewRotatedPadded, "--font-path", $FontFile, "--font-size", "20", "--units", "metric", "--padding-left", "10", "--rotation", "-10.0")

Start-Section "TEST 10: FLIPPING PREVIEW"
Run-Test $ImageFile "Flip Horizontal Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewFlipH, "--flip-horizontal")
Run-Test $ImageFile "Flip Vertical Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewFlipV, "--flip-vertical")
Run-Test $ImageFile "Flip Both Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewFlipHV, "--flip-horizontal", "--flip-vertical")
Run-Test $TextFile  "Composed Transform (Flip/Rotate/Pad)" "PASS" @("--print", $TextFile, "--print-preview", $TextPreviewComposed, "--font-path", $FontFile, "--font-size", "20", "--rotation", "5.0", "--flip-horizontal")

Start-Section "TEST 11: SCALING PREVIEW"
Run-Test $ImageFile "Uniform Scale Preview (1.5x)" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewScaleUniform, "--scale", "1.5")
Run-Test $ImageFile "Non-Uniform Scale Preview (1.5x, 0.75y)" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewScaleNonUniform, "--scale-x", "1.5", "--scale-y", "0.75")
Run-Test $TextFile  "Composed Transform (Scale/Rotate/Pad)" "PASS" @("--print", $TextFile, "--print-preview", $TextPreviewScaleComposed, "--font-path", $FontFile, "--font-size", "24", "--rotation", "8.0", "--scale", "0.8")

Start-Section "TEST 12: TEXT ALIGNMENT PREVIEW"
Run-Test $FontFile "Text Preview (Left Align)" "PASS" @("--text", "LarkTool.exe", "--font-path", $FontFile, "--font-size", "32", "--print-preview", $TextPreviewAlignLeft, "--align", "left")
Run-Test $FontFile "Text Preview (Center Align)" "PASS" @("--text", "LarkTool.exe", "--font-path", $FontFile, "--font-size", "32", "--print-preview", $TextPreviewAlignCenter, "--align", "center")
Run-Test $FontFile "Text Preview (Right Align)" "PASS" @("--text", "LarkTool.exe", "--font-path", $FontFile, "--font-size", "32", "--print-preview", $TextPreviewAlignRight, "--align", "right")

Start-Section "TEST 13: TEXT DOCUMENT ALIGNMENT"
Run-Test $TextFile "Text Doc Preview (Left Align)" "PASS" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "24", "--print-preview", $TextDocPreviewAlignLeft, "--align", "left")
Run-Test $TextFile "Text Doc Preview (Center Align)" "PASS" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "24", "--print-preview", $TextDocPreviewAlignCenter, "--align", "center")
Run-Test $TextFile "Text Doc Preview (Right Align)" "PASS" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "24", "--print-preview", $TextDocPreviewAlignRight, "--align", "right")

Start-Section "TEST 14: WORD WRAPPING PREVIEW"
Run-Test $TextFile "Text Preview (Word Wrap Disabled)" "PASS" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "30", "--print-preview", $TextPreviewWrapOff, "--align", "center")
Run-Test $TextFile "Text Preview (Word Wrap Enabled)" "PASS" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "30", "--print-preview", $TextPreviewWrapOn, "--align", "center", "--word-wrap")

Start-Section "TEST 15: COMPLEX FEATURE INTERACTION"
Run-Test $FontFile "Kitchen Sink Transform" "PASS" @("--text", $KitchenSinkText, "--font-path", $FontFile, "--font-size", "24", "--print-preview", $KitchenSinkPreview, "--units", "metric", "--padding-left", "10", "--padding-top", "5", "--padding-bottom", "5", "--rotation", "10", "--scale", "1.2", "--flip-horizontal", "--word-wrap", "--align", "center", "--process-escape-chars")

Start-Section "TEST 16: IMAGE & TEXT ADJUSTMENTS"
Run-Test $ImageFile "Increase Brightness Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewBrighter, "--brightness", "50", "--dither", "floyd")
Run-Test $ImageFile "Decrease Brightness Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewDarker, "--brightness", "-50", "--dither", "floyd")
Run-Test $ImageFile "Increase Contrast Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewHighContrast, "--contrast", "60", "--dither", "floyd")
Run-Test $ImageFile "Decrease Contrast Preview" "PASS" @("--print", $ImageFile, "--print-preview", $ImagePreviewLowContrast, "--contrast", "-60", "--dither", "floyd")
Run-Test $FontFile "Adjust Text Preview (Darker, High Contrast)" "PASS" @("--text", "Adjusted!", "--font-path", $FontFile, "--font-size", "36", "--print-preview", $TextPreviewAdjusted, "--brightness", "-30", "--contrast", "50")

Start-Section "TEST 17: BENCHMARKING"
Run-Test $FontFile "Benchmarking" "PASS" @("--benchmark", "--print-preview", $BenchmarkPreview)

Start-Section "TEST 18: INVALID COMMANDS (Negative Testing)"
Run-Test "N/A" "Disallow --move with --print-preview" "FAIL" @("--move", "10", "--print-preview", $ImagePreviewThreshold)
Run-Test "N/A" "Disallow --status with --print-preview" "FAIL" @("--status", "--print-preview", $ImagePreviewThreshold)
Run-Test "N/A" "Disallow --set-config with --print-preview" "FAIL" @("--set-config", "--print-preview", $ImagePreviewThreshold)
Run-Test "N/A" "Disallow --reset with --print-preview" "FAIL" @("--reset", "--print-preview", $ImagePreviewThreshold)
Run-Test "N/A" "Require file for --print" "FAIL" @("--print")
Run-Test "N/A" "Non-existent file for --print" "FAIL" @("--print", "non_existent_file.png")
Run-Test $PdfFile "Invalid page range (start > end)" "FAIL" @("--print", $PdfFile, "--page-start", "2", "--page-end", "1")
Run-Test $PdfFile "Invalid page range (start = 0)" "FAIL" @("--print", $PdfFile, "--page-start", "0", "--page-end", "1")
Run-Test "N/A" "No action command specified" "FAIL" @("--units", "metric", "--speed", "100")
Run-Test "N/A" "Move with non-numeric distance" "FAIL" @("--move", "abc", "--units", "metric")
Run-Test $ImageFile "Scale with a negative value" "FAIL" @("--print", $ImageFile, "--print-preview", $ImagePreviewScaleUniform, "--scale", "-1.5")
Run-Test $FontFile "Text with a zero font size" "FAIL" @("--text", "tiny", "--font-path", $FontFile, "--font-size", "0", "--print-preview", $TextPreviewOut)
Run-Test $ImageFile "Print with invalid dither algorithm" "FAIL" @("--print", $ImageFile, "--dither", "random", "--print-preview", $ImagePreviewThreshold)
Run-Test $TextFile "Print with invalid alignment" "FAIL" @("--print", $TextFile, "--font-path", $FontFile, "--font-size", "24", "--align", "justify", "--print-preview", $TextDocPreviewAlignCenter)
Run-Test "N/A" "Set Motor Current to 2000" "FAIL" @("--set-config", "--units", "imperial", "--current", "2000")
Run-Test "N/A" "Set Step Direction to backwards" "FAIL" @("--set-config", "--units", "imperial", "--direction", "backward")
Run-Test "N/A" "Set IPS (speed) to 10" "FAIL" @("--set-config", "--units", "imperial", "--speed", "10.0")
Run-Test $ImageFile "Brightness value too high" "FAIL" @("--print", $ImageFile, "--print-preview", $ImagePreviewBrighter, "--brightness", "101")
Run-Test $ImageFile "Contrast value too low" "FAIL" @("--print", $ImageFile, "--print-preview", $ImagePreviewLowContrast, "--contrast", "-101")

Start-Section "TEST 19: FILE & PATH EDGE CASES"
Run-Test $SpacedImageFile "Print file with spaces in name" "PASS" @("--print", $SpacedImageFile, "--print-preview", $SpacedImagePreview)
Run-Test $EmptyTextFile "Print an empty text file" "PASS" @("--print", $EmptyTextFile, "--font-path", $FontFile, "--font-size", "24")
Run-Test $CorruptImageFile "Print a zero-byte (corrupt) image file" "FAIL" @("--print", $CorruptImageFile)
Run-Test "N/A" "Fail gracefully when font file is not found" "FAIL" @("--text", "test", "--font-path", "C:\non_existent_font.ttf", "--font-size", "24", "--print-preview", $TextPreviewOut)
Run-Test $FontFile "Handle an empty string input via --text" "PASS" @("--text", '""', "--font-path", $FontFile, "--font-size", "24", "--print-preview", $TextPreviewEmpty)

Start-Section "TEST 20: VERBOSITY LEVELS"
Run-Test "N/A" "Info Verbosity Flag (-v)" "PASS" @("--status", "-v") -NoDefaultArgs
Run-Test "N/A" "Debug Verbosity Flag (-vv)" "PASS" @("--status", "-vv") -NoDefaultArgs

Start-Section "TEST 21: DEVICE DIAGNOSTICS"
Run-Test "N/A" "Get CPU Temperature" "PASS" @("--temperature")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test "N/A" "Clear All Faults" "PASS" @("--clear-faults")
Start-Sleep -Milliseconds 1000
Run-Test "N/A" "Purge Buffers" "PASS" @("--purge")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test "N/A" "Get Fault Log" "PASS" @("--get-fault-log")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test "N/A" "Run Device Self-Test" "PASS" @("--self-test")
Start-Sleep -Milliseconds 6000

Start-Section "TEST 22: CALIBRATION"
Run-Test "N/A" "Generate Darkness Calibration Preview" "PASS" @("--calibrate-darkness", "--units", "imperial", "--speed", "4.0", "--resolution", "quarter", "--print-preview", $CalibrateDarknessPreview)

Start-Section "TEST 23: FINISHING OPTIONS"
Write-Host "`n    --- Testing the full preview generation workflow ---" -ForegroundColor $Flair.CommandColor
Run-Test $ImageFile "Generate a main preview, rename it, and create a separate bar preview" "PASS" @("--print", $ImageFile, "--print-preview", $BasePreviewNameDashed, "--cutoff-style", "dashed", "--move-after-print", "10", "--units", "metric")
Run-Test $ImageFile "Generate DOTTED preview, rename it, and create a separate bar preview" "PASS" @("--print", $ImageFile, "--print-preview", $BasePreviewNameDotted, "--cutoff-style", "dotted", "--move-after-print", "5", "--units", "metric")
Run-Test $ImageFile "Generate TRIANGLE preview, rename it, and create a separate bar preview" "PASS" @("--print", $ImageFile, "--print-preview", $BasePreviewNameTriangle, "--cutoff-style", "triangle", "--move-after-print", "15", "--units", "metric")
Write-Host "`n    --- Testing for correct failure on invalid argument combinations ---" -ForegroundColor $Flair.CommandColor
Run-Test $ImageFile "FAIL: Use an invalid cutoff style name" "FAIL" @("--print", $ImageFile, "--cutoff-style", "solid")
Run-Test $ImageFile "FAIL: Require --units for --move-after-print" "FAIL" @("--print", $ImageFile, "--move-after-print", "10")
Write-Host "`n    --- Testing the physical print workflow with finishing options ---" -ForegroundColor $Flair.CommandColor
Run-Test $ImageFile "Physical print with DOTTED cutoff and final move" "PASS" @("--print", $ImageFile, "--cutoff-style", "dotted", "--move-after-print", "12.7", "--units", "metric")
Start-Sleep -Milliseconds $PrintJobDelay
Run-Test $ImageFile "Physical print with TRIANGLE cutoff only" "PASS" @("--print", $ImageFile, "--cutoff-style", "triangle")
Start-Sleep -Milliseconds $PrintJobDelay

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

        Write-Host "|" -ForegroundColor $Flair.SummaryColor -NoNewline
        Write-Host $leftPad -ForegroundColor $Flair.SummaryColor -NoNewline
        Write-Host $coloredPart -ForegroundColor $StatusColor -NoNewline
        Write-Host $uncoloredPart -ForegroundColor $Flair.SummaryColor -NoNewline
        Write-Host $flexiblePadding -ForegroundColor $Flair.SummaryColor -NoNewline
        Write-Host $rightPad -ForegroundColor $Flair.SummaryColor -NoNewline
        Write-Host "|" -ForegroundColor $Flair.SummaryColor
    }
    
    $titleText = "ALL TESTS COMPLETED - SUMMARY"
    if ($Section) {
        $titleText = "FILTERED TEST RUN - SUMMARY"
    }
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
        if ($Section) {
             Write-Host "           Selected tests passed successfully!           " -ForegroundColor $Flair.PassColor
        } else {
             Write-Host "                  All tests passed successfully!                  " -ForegroundColor $Flair.PassColor
        }
        exit 0
    }
}

Write-Summary-Box
Write-Host ""
pause