ibmcloud config --check-version=false | Out-Null

$LOGIN_RESULT = ibmcloud login --apikey $env:DEPLOYMENT_IAM_API_KEY -r $env:CE_REGION -g $env:CE_RESOURCE_GROUP 2>&1
if ($LOGIN_RESULT -match "FAILED") {
    $LOGIN_RESULT  | Write-Host
    Write-Host "Error with ibmcloud login. check the logs above."
    exit 1
} else {
    $LOGIN_RESULT | Write-Host
    Write-Host ""
}

$TARGET_RESULT = ibmcloud target -r $env:CE_REGION -g $env:CE_RESOURCE_GROUP 2>&1
if ($TARGET_RESULT -match "FAILED") {
    $TARGET_RESULT | Write-Host
    Write-Host "Error with ibmcloud target. check the logs above."
    exit 1
} else {
    $TARGET_RESULT | Write-Host
    Write-Host ""
}

Write-Host "checking project. new project will be created if failed to find project with name $env:CE_PROJECT"

$get_project = ibmcloud ce project get -n $env:CE_PROJECT 2>&1
if ($get_project -match "OK") {
    Write-Host "`nProject found."
} else {
    Write-Host "`n$env:CE_PROJECT does not exist."
    Write-Host "`ncreating $env:CE_PROJECT."
    $create_project = ibmcloud ce project create -n $env:CE_PROJECT 2>&1
    if ($create_project -match "OK") {
        Write-Host "`nProject created."
    } else {
        Write-Host "`n$create_project"
        Write-Host "Error with project creation. check the logs above."
        exit 1
    }
}
