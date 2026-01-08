# Test SFTP connection using curl
$hostname = "20.86.180.225"
$port = 8922
$username = "9pq09noto4lkjl0jqhrr3cp417dmx3"
$password = "xH%U!#Ga4VWLjbJzgLd!7Bn%34YUQj"

Write-Host "Testing SFTP connection with curl..." -ForegroundColor Cyan
Write-Host "Note: curl's SFTP support may be limited" -ForegroundColor Yellow
Write-Host ""

# Note: curl doesn't natively support SFTP authentication well
# But let's try to see what happens
$url = "sftp://${username}:${password}@${hostname}:${port}/"

Write-Host "Attempting connection to: $url" -ForegroundColor Cyan
curl -v --insecure $url 2>&1 | Select-String -Pattern "connected|error|fail" -Context 0,2

