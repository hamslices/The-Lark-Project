<#
.SYNOPSIS
    A colorful and robust test script for the LarkTool DFU update capability.

.DESCRIPTION
    This script automates the process of running the LarkTool's DFU update command.
    It uses relative paths, provides clear color-coded status checks, and reports
    a final success or failure message based on the LarkTool's exit code.

.NOTES
    Author:     HamSlices
    Version:    2.2 (Path-Fix)
    Usage:      Run from the root of your 'LarkProject' directory with: .\test_dfu_update.ps1
#>

# --- Configuration ---
Clear-Host
$PSScriptRoot = Get-Location

# Relative path to the LarkTool executable
$larkToolRelativePath = "x64\Release\LarkTool.exe"

$firmwareRelativePath = "test_files\app_Slim.hex"

# Set to $true to enable simple sound alerts on completion.
$enableSound = $false

# --- ASCII Banner ---
Write-Host @'

        |
       / \
      / _ \
     |.o '.|
     |'._.'|
     |     |
   ,'|  |  |`.
  /  |  |  |  \
  |,-'--|--'-.|

'@ -ForegroundColor Cyan
Write-Host "--- LARK DFU FIRMWARE UPDATE TESTER ---" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor White
Write-Host ""


# --- Phase 1: Pre-flight Checks ---
Write-Host "PHASE 1: PRE-FLIGHT CHECKS" -ForegroundColor Yellow

$larkToolPath = Join-Path $PSScriptRoot $larkToolRelativePath
$firmwarePath = Join-Path $PSScriptRoot $firmwareRelativePath
$allChecksPassed = $true

# 1. Check for LarkTool.exe
Write-Host "Verifying LarkTool executable..." -NoNewline
if (Test-Path $larkToolPath) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "  LarkTool.exe not found at '$larkToolPath'" -ForegroundColor Red
    Write-Host "  Please ensure the project is compiled in x64 Release mode." -ForegroundColor Red
    $allChecksPassed = $false
}

# 2. Check for firmware file
Write-Host "Verifying firmware file..." -NoNewline
if (Test-Path $firmwarePath) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [FAIL]" -ForegroundColor Red
    Write-Host "  Firmware 'app.hex' not found at '$firmwarePath'" -ForegroundColor Red
    $allChecksPassed = $false
}

# Abort if any check failed
if (-not $allChecksPassed) {
    Write-Host "`nOne or more critical checks failed. Aborting script." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}


# --- Phase 2: Execution ---
Write-Host "`nPHASE 2: AWAITING USER CONFIRMATION" -ForegroundColor Yellow
Write-Host "All checks passed. Please connect your Lark device in normal operating mode."
Read-Host "Press ENTER to begin the DFU update process..."

Write-Host "`nPHASE 3: EXECUTING UPDATE" -ForegroundColor Yellow
Write-Host "Launching LarkTool.exe... see output below."
Write-Host "--------------------------------------------" -ForegroundColor Gray

$arguments = @(
    "--dfu-update",
    $firmwarePath,
    "-v"  # Verbose logging for detail
)

$process = $null
try {
    # Execute the command and wait for it to complete.
    $process = Start-Process -FilePath $larkToolPath -ArgumentList $arguments -Wait -PassThru -NoNewWindow
}
catch {
    Write-Host "`nAn unexpected script error occurred while trying to run LarkTool.exe." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}


# --- Phase 4: Results ---
Write-Host "--------------------------------------------" -ForegroundColor Gray
Write-Host "`nPHASE 4: RESULTS" -ForegroundColor Yellow

if ($null -eq $process) {
     Write-Host "[FAIL] Critical script failure: Process could not be started." -ForegroundColor Red
}
elseif ($process.ExitCode -eq 0) {
    Write-Host "[OK] SUCCESS: DFU Update process completed successfully!" -ForegroundColor Green
    Write-Host "  LarkTool exited with code 0."
    if ($enableSound) { [System.Media.SystemSounds]::Asterisk.Play() }
}
else {
    Write-Host "[FAIL] FAILURE: DFU Update process failed." -ForegroundColor Red
    Write-Host "  LarkTool exited with error code: $($process.ExitCode)." -ForegroundColor Red
    Write-Host "  Please review the log messages above for details."
    if ($enableSound) { [System.Media.SystemSounds]::Hand.Play() }
}

Write-Host ""
