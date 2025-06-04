$configFile = "deploy/ce/ce.config.properties"

# Helper to get value by key from properties file and put it on environment variable
function Get-PropValuePutOnEnv($file, $key) {
    $match = Select-String -Path $file -Pattern "^$key=" | Select-Object -First 1
    if ($match) {
        $value = $match.Line.Split('=')[1].Trim()
        Set-Item -Path "Env:$key" -Value $value
        return $value
    }
    return ""
}

# Read config values from file
$APP_NAME                 = Get-PropValuePutOnEnv $configFile "APP_NAME"
$BROKER_USERNAME          = Get-PropValuePutOnEnv $configFile "BROKER_USERNAME"
$BROKER_PASSWORD          = Get-PropValuePutOnEnv $configFile "BROKER_PASSWORD"
$BROKER_ICR_NAMESPACE_URL = Get-PropValuePutOnEnv $configFile "BROKER_ICR_NAMESPACE_URL"
$CE_REGION                = Get-PropValuePutOnEnv $configFile "CE_REGION"
$CE_RESOURCE_GROUP        = Get-PropValuePutOnEnv $configFile "CE_RESOURCE_GROUP"
$CE_PROJECT               = Get-PropValuePutOnEnv $configFile "CE_PROJECT"
$CE_REGISTRY_SECRET_NAME  = Get-PropValuePutOnEnv $configFile "CE_REGISTRY_SECRET_NAME"
$ICR_IMAGE                = Get-PropValuePutOnEnv $configFile "ICR_IMAGE"
Get-PropValuePutOnEnv $configFile "DB_HOST"
Get-PropValuePutOnEnv $configFile "DB_PORT"
Get-PropValuePutOnEnv $configFile "DB_USER"
Get-PropValuePutOnEnv $configFile "DB_USER_PWD"
Get-PropValuePutOnEnv $configFile "DB_NAME"
Get-PropValuePutOnEnv $configFile "DB_CERT"

$EMPTY = '""'

Write-Host ""
Write-Host "---------- Checking configuration ----------"
Write-Host ""

$missingConfig = @()
if (-not $ICR_IMAGE -or $ICR_IMAGE -eq $EMPTY)                     { $missingConfig += "ICR_IMAGE" }
if (-not $CE_REGISTRY_SECRET_NAME -or $CE_REGISTRY_SECRET_NAME -eq $EMPTY) { $missingConfig += "CE_REGISTRY_SECRET_NAME" }
if (-not $BROKER_USERNAME -or $BROKER_USERNAME -eq $EMPTY)         { $missingConfig += "BROKER_USERNAME" }
if (-not $BROKER_PASSWORD -or $BROKER_PASSWORD -eq $EMPTY)         { $missingConfig += "BROKER_PASSWORD" }
if (-not $BROKER_ICR_NAMESPACE_URL -or $BROKER_ICR_NAMESPACE_URL -eq $EMPTY) { $missingConfig += "BROKER_ICR_NAMESPACE_URL" }
if (-not $CE_REGION -or $CE_REGION -eq $EMPTY)                     { $missingConfig += "CE_REGION" }
if (-not $APP_NAME -or $APP_NAME -eq $EMPTY)                       { $missingConfig += "APP_NAME" }
if (-not $CE_RESOURCE_GROUP -or $CE_RESOURCE_GROUP -eq $EMPTY)     { $missingConfig += "CE_RESOURCE_GROUP" }
if (-not $CE_PROJECT -or $CE_PROJECT -eq $EMPTY)                   { $missingConfig += "CE_PROJECT" }

if ($missingConfig.Count -gt 0) {
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "deploy config properties not set!"
    Write-Host "Missing: $($missingConfig -join ', ')"
    Write-Host "refer README to set values"
    Write-Host "Exiting..."
    Write-Host "*******************************************************************************"
    Write-Host ""
    exit 1
} else {
    Write-Host "Ok"
}

Write-Host ""
Write-Host "---------- Checking secrets ----------"
Write-Host ""
if (-not $env:DEPLOYMENT_IAM_API_KEY -or $env:DEPLOYMENT_IAM_API_KEY -eq $EMPTY) {
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "secrets not set!"
    Write-Host "make sure DEPLOYMENT_IAM_API_KEY is provided!"
    Write-Host "refer README to set values"
    Write-Host "Exiting..."
    Write-Host "*******************************************************************************"
    Write-Host ""
    exit 1
} else {
    Write-Host "Ok"
}

Write-Host ""
Write-Host "---------- Checking METERING_API_KEY ----------"
Write-Host ""
if (-not $env:METERING_API_KEY -or $env:METERING_API_KEY -eq $EMPTY) {
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "METERING_API_KEY is not provided!"
    Write-Host "send metric option will not be available"
    Write-Host "refer README to set values"
    Write-Host "Exiting..."
    Write-Host "*******************************************************************************"
    Write-Host ""
} else {
    Write-Host "Ok"
}
