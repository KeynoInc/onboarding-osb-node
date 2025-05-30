# Ensure required env vars are present
$missingVars = @()
if (-not $env:ICR_NAMESPACE_REGION) { $missingVars += "ICR_NAMESPACE_REGION" }
if (-not $env:DEPLOYMENT_IAM_API_KEY) { $missingVars += "DEPLOYMENT_IAM_API_KEY" }
if (-not $env:ICR_RESOURCE_GROUP) { $missingVars += "ICR_RESOURCE_GROUP" }
if (-not $env:BROKER_ICR_NAMESPACE_URL) { $missingVars += "BROKER_ICR_NAMESPACE_URL" }

if ($missingVars.Count -gt 0) {
    Write-Host "Missing required environment variables: $($missingVars -join ', ')"
    exit 1
}

$LOGIN_RESULT = ""
$TARGET_RESULT = ""

if ($env:ICR_NAMESPACE_REGION -eq "global" -or $env:ICR_NAMESPACE_REGION -eq "Global") {
    ibmcloud config --check-version=false | Out-Null
    $LOGIN_RESULT = ibmcloud login --apikey $env:DEPLOYMENT_IAM_API_KEY --no-region 2>&1
    if ($LOGIN_RESULT -match "FAILED") {
        $LOGIN_RESULT | Write-Host
        Write-Host "Error with ibmcloud login. Check the logs above."
        exit 1
    } else {
        $LOGIN_RESULT | Write-Host
        Write-Host ""
    }

    $TARGET_RESULT = ibmcloud target -g $env:ICR_RESOURCE_GROUP 2>&1
    if ($TARGET_RESULT -match "FAILED") {
        $TARGET_RESULT | Write-Host
        Write-Host "Error with ibmcloud target. Check the logs above."
        exit 1
    } else {
        $TARGET_RESULT | Write-Host
        Write-Host ""
    }
    Write-Host ""
} else {
    ibmcloud config --check-version=false | Out-Null
    $LOGIN_RESULT = ibmcloud login --apikey $env:DEPLOYMENT_IAM_API_KEY -r $env:ICR_NAMESPACE_REGION -g $env:ICR_RESOURCE_GROUP 2>&1
    if ($LOGIN_RESULT -match "FAILED") {
        $LOGIN_RESULT | Write-Host
        Write-Host "Error with ibmcloud login. Check the logs above."
        exit 1
    } else {
        $LOGIN_RESULT | Write-Host
        Write-Host ""
    }

    $TARGET_RESULT = ibmcloud target -r $env:ICR_NAMESPACE_REGION -g $env:ICR_RESOURCE_GROUP 2>&1
    if ($TARGET_RESULT -match "FAILED") {
        $TARGET_RESULT | Write-Host
        Write-Host "Error with ibmcloud target. Check the logs above."
        exit 1
    } else {
        $TARGET_RESULT | Write-Host
        Write-Host ""
    }
}

# Parse namespace from BROKER_ICR_NAMESPACE_URL
$strarr = $env:BROKER_ICR_NAMESPACE_URL -split '/'
$NAMESPACE = $strarr[1]

Write-Host "checking namespace."
Write-Host "new namespace will be created if failed to find namespace with name $NAMESPACE"

$create_namespace = ibmcloud cr namespace-add -g $env:ICR_RESOURCE_GROUP $NAMESPACE 2>&1

if ($create_namespace -match "OK") {
    Write-Host "OK"
    Write-Host ""
} else {
    $create_namespace | Write-Host 
    Write-Host "Error with namespace creation. check the logs above."
    exit 1
}
