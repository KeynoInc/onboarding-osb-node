Write-Host ""
Write-Host "---------- Logging in ibmcloud ----------"
Write-Host ""

# Run build number script (assumes it returns the number as output)
$BUILD_NUMBER = & ./deploy/generate_build_number.ps1
$EMPTY = '""'

$IAM_ENDPOINT_TEST = "https://iam.test.cloud.ibm.com"
$IAM_ENDPOINT_PROD = "https://iam.cloud.ibm.com"
$USAGE_ENDPOINT_TEST = "https://billing.test.cloud.ibm.com"
$USAGE_ENDPOINT_PROD = "https://billing.cloud.ibm.com"

if ($env:ONBOARDING_ENV -eq "stage" -or $env:ONBOARDING_ENV -eq "STAGE") {
    $IAM_ENDPOINT = $IAM_ENDPOINT_TEST
    $USAGE_ENDPOINT = $USAGE_ENDPOINT_TEST
} else {
    $IAM_ENDPOINT = $IAM_ENDPOINT_PROD
    $USAGE_ENDPOINT = $USAGE_ENDPOINT_PROD
}

# Handle Code Engine project (assumes you have a .ps1 version)
& ./deploy/ce/handle_ce_project.ps1

ibmcloud config --check-version=false | Out-Null
ibmcloud login --apikey $env:DEPLOYMENT_IAM_API_KEY -r $env:CE_REGION -g $env:CE_RESOURCE_GROUP | Out-Null
ibmcloud target -r $env:CE_REGION -g $env:CE_RESOURCE_GROUP | Out-Null
ibmcloud ce project select -n $env:CE_PROJECT | Out-Null

Write-Host ""
Write-Host "---------- Checking in ce registry secret ----------"
Write-Host ""
Write-Host "checking ce registry. new registry will be created if failed to find registry with name $env:CE_REGISTRY_SECRET_NAME"

$GET_CE_REG = ibmcloud ce registry get -n $env:CE_REGISTRY_SECRET_NAME 2>&1

if ($GET_CE_REG -match "OK") {
    Write-Host "updating $env:CE_REGISTRY_SECRET_NAME..."
    ibmcloud ce registry update -n $env:CE_REGISTRY_SECRET_NAME -p $env:DEPLOYMENT_IAM_API_KEY -u iamapikey | Out-Null
} else {
    Write-Host "creating $env:CE_REGISTRY_SECRET_NAME..."
    ibmcloud ce registry create -n $env:CE_REGISTRY_SECRET_NAME -p $env:DEPLOYMENT_IAM_API_KEY -u iamapikey | Out-Null
}

Write-Host ""
Write-Host "---------- Deploying to Code Engine ----------"
Write-Host ""
Write-Host "Trying to find application on Code Engine"
Write-Host "new application will be created if failed to find application with name $env:APP_NAME"

$APP_EXISTS = ibmcloud ce application get -n $env:APP_NAME 2>&1
$RESULT = ""

$fullImage = "private.{0}/{1}:latest" -f $env:BROKER_ICR_NAMESPACE_URL, $env:ICR_IMAGE 
Write-Host "broker_image: '$fullImage'" 

if ($APP_EXISTS -match "OK") {
    Write-Host "Found"
    Write-Host "Updating Application"
    Write-Host "This might take some time..."
    if (-not $env:METERING_API_KEY -or $env:METERING_API_KEY -eq $EMPTY) {
        $RESULT = ibmcloud ce application update --name $env:APP_NAME --image $fullImage --min 1 `
            --env BROKER_USERNAME=$env:BROKER_USERNAME `
            --env BROKER_PASSWORD=$env:BROKER_PASSWORD `
            --env BUILD_NUMBER=$BUILD_NUMBER `
            --env IAM_ENDPOINT=$IAM_ENDPOINT `
            --env USAGE_ENDPOINT=$USAGE_ENDPOINT `
            --env PC_URL=$env:PC_URL `
            --rs $env:CE_REGISTRY_SECRET_NAME 2>&1
    } else {
        $RESULT = ibmcloud ce application update --name $env:APP_NAME --image $fullImage --min 1 `
            --env BROKER_USERNAME=$env:BROKER_USERNAME `
            --env BROKER_PASSWORD=$env:BROKER_PASSWORD `
            --env BUILD_NUMBER=$BUILD_NUMBER `
            --env IAM_ENDPOINT=$IAM_ENDPOINT `
            --env USAGE_ENDPOINT=$USAGE_ENDPOINT `
            --env PC_URL=$env:PC_URL `
            --env METERING_API_KEY=$env:METERING_API_KEY `
            --rs $env:CE_REGISTRY_SECRET_NAME 2>&1
    }
} else {
    Write-Host "Do not terminate..."
    Write-Host "Creating new application..."
    Write-Host "This might take some time..." 
	
    if (-not $env:METERING_API_KEY -or $env:METERING_API_KEY -eq $EMPTY) {
        $RESULT = ibmcloud ce application create --name $env:APP_NAME --image $fullImage --min 1 `
            --env BROKER_USERNAME=$env:BROKER_USERNAME `
            --env BROKER_PASSWORD=$env:BROKER_PASSWORD `
            --env BUILD_NUMBER=$BUILD_NUMBER `
            --env IAM_ENDPOINT=$IAM_ENDPOINT `
            --env USAGE_ENDPOINT=$USAGE_ENDPOINT `
            --env PC_URL=$env:PC_URL `
            --rs $env:CE_REGISTRY_SECRET_NAME 2>&1
    } else {
        $RESULT = ibmcloud ce application create --name $env:APP_NAME --image $fullImage --min 1 `
            --env BROKER_USERNAME=$env:BROKER_USERNAME `
            --env BROKER_PASSWORD=$env:BROKER_PASSWORD `
            --env BUILD_NUMBER=$BUILD_NUMBER `
            --env IAM_ENDPOINT=$IAM_ENDPOINT `
            --env USAGE_ENDPOINT=$USAGE_ENDPOINT `
            --env PC_URL=$env:PC_URL `
            --env METERING_API_KEY=$env:METERING_API_KEY `
            --rs $env:CE_REGISTRY_SECRET_NAME 2>&1
    }
}

if ($RESULT -match "OK") {
    $APP_URL = ibmcloud ce application get -n $env:APP_NAME -o url
    if (-not $env:METERING_API_KEY -or $env:METERING_API_KEY -eq $EMPTY) {
        $UPDATE_RESULT = ibmcloud ce application update --name $env:APP_NAME --image $fullImage --min 1 `
            --env BROKER_USERNAME=$env:BROKER_USERNAME `
            --env BROKER_PASSWORD=$env:BROKER_PASSWORD `
            --env BUILD_NUMBER=$BUILD_NUMBER `
            --env IAM_ENDPOINT=$IAM_ENDPOINT `
            --env USAGE_ENDPOINT=$USAGE_ENDPOINT `
            --env PC_URL=$env:PC_URL `
            --env BROKER_URL=$APP_URL `
            --env DASHBOARD_URL=$APP_URL `
            --env METERING_API_KEY=$env:METERING_API_KEY `
            --rs $env:CE_REGISTRY_SECRET_NAME 2>&1
    } else {
        $UPDATE_RESULT = ibmcloud ce application update --name $env:APP_NAME --image $fullImage --min 1 `
            --env BROKER_USERNAME=$env:BROKER_USERNAME `
            --env BROKER_PASSWORD=$env:BROKER_PASSWORD `
            --env BUILD_NUMBER=$BUILD_NUMBER `
            --env IAM_ENDPOINT=$IAM_ENDPOINT `
            --env USAGE_ENDPOINT=$USAGE_ENDPOINT `
            --env PC_URL=$env:PC_URL `
            --env BROKER_URL=$APP_URL `
            --env DASHBOARD_URL=$APP_URL `
            --rs $env:CE_REGISTRY_SECRET_NAME 2>&1
    }

    if ($UPDATE_RESULT -match "OK") {
        Write-Host ""
        Write-Host "*******************************************************************************"
        Write-Host "Congratulations your broker is deployed!"
        Write-Host ""
        Write-Host "Service is deployed on:"
        Write-Host "$APP_URL"
        Write-Host ""
        Write-Host "Use the broker url to the register in Partner Center."
        Write-Host "*******************************************************************************"
        Write-Host ""
    } else {
        Write-Host $UPDATE_RESULT
        Write-Host ""
        Write-Host "*******************************************************************************"
        Write-Host "|"
        Write-Host "|"
        Write-Host "|   Something went wrong. check the logs above."
        Write-Host "|"
        Write-Host "|"
        Write-Host "*******************************************************************************"
        Write-Host ""
    }
} else {
    Write-Host $RESULT
    Write-Host ""
    Write-Host "*******************************************************************************"
    Write-Host "|"
    Write-Host "|"
    Write-Host "|   Something went wrong. check the logs above."
    Write-Host "|"
    Write-Host "|"
    Write-Host "*******************************************************************************"
    Write-Host ""
}
