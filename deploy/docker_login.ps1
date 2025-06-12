Write-Host ""

# Check if Docker Desktop is running and the engine/context is correct
try {
    $dockerInfo = docker info 2>&1
    $dockerInfoStr = $dockerInfo -join "`n"
    if ($dockerInfoStr -match "error during connect") {
        Write-Host "Docker Desktop is NOT running or the Docker engine/context is not correct."
        Write-Host "Please start Docker Desktop and ensure the correct engine (Linux/Windows) is selected."
        return $false
    }
    Write-Host "Docker Desktop is running."
}
catch {
    Write-Host "Docker Desktop is NOT running."
    return $false
}

Write-Host "Logging in docker..."

# Logout (no sudo needed in Windows PowerShell, leave sudo out for Linux/WSL PowerShell)
docker logout

# Set required environment variables
$DEPLOYMENT_IAM_API_KEY = $env:DEPLOYMENT_IAM_API_KEY
$BROKER_ICR_NAMESPACE_URL = $env:BROKER_ICR_NAMESPACE_URL
$ICR_IMAGE = $env:ICR_IMAGE

# Compose the login server URL
$server = "$BROKER_ICR_NAMESPACE_URL/$ICR_IMAGE"

# Login
docker login -u iamapikey -p $DEPLOYMENT_IAM_API_KEY $server

return $true
