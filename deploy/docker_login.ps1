Write-Host ""
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
