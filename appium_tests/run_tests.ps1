# ================================================================
# Smart Student Platform — Appium Test Runner (PowerShell)
# Usage: .\run_tests.ps1
#        .\run_tests.ps1 -Suite auth
#        .\run_tests.ps1 -ReportOnly
# ================================================================
param(
    [string]$Suite = "all",
    [switch]$ReportOnly,
    [string]$Device = "emulator-5554",
    [string]$Android = "14.0"
)

$Host.UI.RawUI.WindowTitle = "Smart Student Platform — Appium Tests"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

function Write-Banner {
    Write-Host "`n================================================================" -ForegroundColor Cyan
    Write-Host "  SMART STUDENT PLATFORM — APPIUM E2E TEST RUNNER" -ForegroundColor Cyan
    Write-Host "  Suite   : $Suite" -ForegroundColor White
    Write-Host "  Device  : $Device" -ForegroundColor White
    Write-Host "  Android : $Android" -ForegroundColor White
    Write-Host "================================================================`n" -ForegroundColor Cyan
}

function Install-Dependencies {
    Write-Host "📦 Installing Python dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt --quiet
    # Try to install pytest-json-report for better report parsing
    pip install pytest-json-report --quiet 2>$null
    pip install pytest-html --quiet
    Write-Host "  Dependencies installed." -ForegroundColor Green
}

function Create-Directories {
    $dirs = @(
        "Test Results\Excel",
        "Test Results\HTML",
        "Test Results\JSON",
        "Test Results\Screenshots",
        "Test Results\Summary",
        "Test Results\Logs"
    )
    foreach ($dir in $dirs) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    Write-Host "  Report directories ready." -ForegroundColor Green
}

Write-Banner
Install-Dependencies
Create-Directories

if ($ReportOnly) {
    Write-Host "`n📊 Running report generation only..." -ForegroundColor Cyan
    python generate_excel_report.py
} else {
    Write-Host "`n🧪 Starting Appium test execution..." -ForegroundColor Cyan
    $env:DEVICE_NAME = $Device
    $env:ANDROID_VERSION = $Android

    python run_appium_tests.py --suite $Suite --device $Device --android $Android
}

Write-Host "`n================================================================" -ForegroundColor Green
Write-Host "  DONE! Check 'Test Results' folder for reports." -ForegroundColor Green
Write-Host "================================================================`n" -ForegroundColor Green

# Open Excel report if it exists
$excelReport = "Test Results\Excel\Appium_E2E_Test_Report_SmartStudent.xlsx"
if (Test-Path $excelReport) {
    Write-Host "Opening Excel report..." -ForegroundColor Cyan
    Start-Process $excelReport
}
