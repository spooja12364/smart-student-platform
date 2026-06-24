Write-Host "Installing Locust load testing tool..."
pip install locust

Write-Host "Starting load test with 100 users for 1 minute..."
Write-Host "This will test the baseline performance."

# Set the target base URL. If the user has it set in their environment, use it. Otherwise, default to localhost:8080.
$baseUrl = $env:BASE_URL
if (-not $baseUrl) {
    $baseUrl = "http://localhost:8080"
}

Write-Host "Target URL: $baseUrl"

# Run Locust in headless mode:
# -f locustfile.py: specify the script
# --headless: run without web UI
# -u 100: peak number of concurrent Locust users
# -r 10: spawn rate (users per second)
# --run-time 1m: stop after 1 minute
# -H $baseUrl: target host
locust -f locustfile.py --headless -u 100 -r 10 --run-time 1m -H $baseUrl

Write-Host "Load test completed."
Write-Host "You should see output above containing 'Requests per second' and 'Response Time' (Average, Min, Max)."
