# run_all_tests.ps1
# Smart Student Platform - E2E Testing Suite Runner

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "      Smart Student Platform - E2E Testing Suite Runner   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$WorkspaceRoot = "d:\smart_student_platform"
$SeleniumDir = "$WorkspaceRoot\selenium_tests"
$VenvPath = "$SeleniumDir\.venv"

# 1. Ensure virtual environment exists
if (!(Test-Path -Path $VenvPath)) {
    python -m venv $VenvPath
}

# 2. Activate venv and install requirements
& "$VenvPath\Scripts\Activate.ps1"
pip install -r "$SeleniumDir\requirements.txt"

# 3. Generate test cases (data‑driven)
python "$SeleniumDir\generate_test_cases.py"

# 4. Run pytest for E2E tests and produce JUnit XML
pytest -m e2e --junitxml="$SeleniumDir\reports\junit.xml"

# 5. Generate Excel report from pytest results
python "$SeleniumDir\utils\generate_excel_report.py"

Write-Host "All steps completed successfully." -ForegroundColor Green

# 2. Check if something is already listening on port 8080
Write-Host "Checking if local server is listening on port 8080..." -ForegroundColor Gray
$PortActive = $false
try {
    $Socket = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8080)
    $Socket.Close()
    $PortActive = $true
    Write-Host "Port 8080 is active. Using the already running server." -ForegroundColor Green
} catch {
    Write-Host "Port 8080 is idle." -ForegroundColor Yellow
}

if (-not $PortActive) {
    Write-Host "Starting Vite local server in background..." -ForegroundColor Cyan
    
    # Start Vite using cmd.exe /c to handle script execution correctly on Windows
    try {
        $ViteProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npx vite --port 8080 --host 127.0.0.1" `
            -WorkingDirectory $ViteAppDir -NoNewWindow -PassThru
    } catch {
        Write-Host "Failed to start Vite via npx. Trying npm run dev..." -ForegroundColor Yellow
        $ViteProcess = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm run dev -- --port 8080 --host 127.0.0.1" `
            -WorkingDirectory $ViteAppDir -NoNewWindow -PassThru
    }
    
    Write-Host "Waiting for Vite server to initialize..." -ForegroundColor Gray
    
    # Poll for server response (up to 30 seconds)
    $TimeoutSec = 30
    $ElapsedTime = 0
    $ServerLoaded = $false
    
    while ($ElapsedTime -lt $TimeoutSec) {
        Start-Sleep -Seconds 1
        $ElapsedTime++
        try {
            $Socket = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8080)
            $Socket.Close()
            $ServerLoaded = $true
            break
        } catch {
            # Continue waiting
        }
    }
    
    if ($ServerLoaded) {
        Write-Host "Vite server started successfully in background (Process ID: $($ViteProcess.Id))" -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not verify if local server loaded within $TimeoutSec seconds. Attempting to run tests anyway." -ForegroundColor Yellow
    }
}

# 3. Create necessary results directories
New-Item -ItemType Directory -Path "$WorkspaceRoot\Test Results" -Force | Out-Null

# 4. Activate Venv and run Pytest
Write-Host "Activating Python virtual environment and running test suite..." -ForegroundColor Cyan

try {
    # Activate virtual environment
    $env:PATH = "$VenvPath\Scripts;" + $env:PATH
    
    # Run pytest
    Write-Host "Running pytest on 106 test cases..." -ForegroundColor Gray
    pytest -v --junitxml="$WorkspaceRoot\Test Results\report.xml" "$SeleniumDir\tests\test_all_components.py"
    Write-Host "Pytest run finished." -ForegroundColor Green
} catch {
    Write-Host "An error occurred during pytest execution: $_" -ForegroundColor Red
}

# 5. Generate Excel Report
Write-Host "Generating premium Excel report..." -ForegroundColor Cyan
try {
    python "$SeleniumDir\utils\report_generator.py" "$WorkspaceRoot\Test Results\report.xml"
    Write-Host "Excel and markdown reports generated successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to generate report: $_" -ForegroundColor Red
}

# 6. Tear down Vite server if we started it
if ($ViteProcess -ne $null) {
    Write-Host "Stopping background Vite server..." -ForegroundColor Cyan
    try {
        Stop-Process -Id $ViteProcess.Id -Force
        Write-Host "Vite server stopped." -ForegroundColor Green
    } catch {
        # Process might have ended already
    }
}

# 7. Print Console Summary
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "                  TEST EXECUTION COMPLETED                " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
if (Test-Path "$WorkspaceRoot\Test Results\Summary\summary.md") {
    Get-Content "$WorkspaceRoot\Test Results\Summary\summary.md" | ForEach-Object {
        Write-Host $_
    }
} else {
    Write-Host "Test execution complete, but summary markdown file was not found." -ForegroundColor Yellow
}
Write-Host "Excel Report saved in: $WorkspaceRoot\Test Results\Excel\" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
