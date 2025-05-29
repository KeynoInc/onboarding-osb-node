# Define URLs
$IAM_TEST_URL = "https://iam.test.cloud.ibm.com/identity/token"
$IAM_PROD_URL = "https://iam.cloud.ibm.com/identity/token"
$GC_TEST_URL = "https://globalcatalog.test.cloud.ibm.com"
$GC_PROD_URL = "https://globalcatalog.cloud.ibm.com"

Write-Host "Getting Access Token"
Write-Host "ONBOARDING ENV: $env:ONBOARDING_ENV"

if ($env:ONBOARDING_ENV -eq "stage" -or $env:ONBOARDING_ENV -eq "STAGE") {
    $IAM_URL = $IAM_TEST_URL
    $GC_URL = $GC_TEST_URL
} else {
    $IAM_URL = $IAM_PROD_URL
    $GC_URL = $GC_PROD_URL
}

# Get Access Token
$body = @{
    grant_type = "urn:ibm:params:oauth:grant-type:apikey"
    apikey = $env:ONBOARDING_IAM_API_KEY
}
try {
    $accessTokenResp = Invoke-RestMethod -Method Post -Uri $IAM_URL -Headers @{
        "Content-Type" = "application/x-www-form-urlencoded"
        "Accept" = "application/json"
    } -Body $body
    $access_token = $accessTokenResp.access_token
} catch {
    Write-Host "Failed to get access token"
    exit 1
}

Write-Host "Getting Catalog"
$catalogUri = "$GC_URL/api/v1/$($env:GC_OBJECT_ID)?include=%2A&depth=100"
try {
    $gcjson = Invoke-RestMethod -Method Get -Uri $catalogUri -Headers @{
        "accept" = "application/json"
        "Authorization" = "Bearer $access_token"
    }
} catch {
    Write-Host "Failed to get catalog from $catalogUri"
    exit 1
}

if (-not $gcjson.name) {
    exit 1
} else {
    Write-Host "Catalog Json Received"
}

Write-Host "Converting Catalog"

$plansArray = @()
foreach ($child in $gcjson.children) {
    # Pricing
    $plan_pricing_type = $child.metadata.pricing.type
    $plan_type_free = $true
    if ($plan_pricing_type -like "*free*") {
        $plan_type_free = $false
    }

    try {
        $plan_pricing = Invoke-RestMethod -Method Get -Uri $child.metadata.pricing.url -Headers @{
            "Authorization" = "Bearer $access_token"
        }
    } catch {
        $plan_pricing = @{}
    }

    $plan_costs = @{
        type = $plan_pricing.type
        metrics = $plan_pricing.metrics
    }
    $plan_metadata = @{
        created = $child.created
        updated = $child.updated
        allowInternalUsers = $child.metadata.plan.allow_internal_users
        displayName = $child.overview_ui.en.display_name
        costs = $plan_costs
    }
    $plan = @{
        name = $child.name
        id = $child.id
        metadata = $plan_metadata
        description = $child.overview_ui.en.description
        paid = $plan_type_free
    }
    $plansArray += $plan
}

# Metadata
$metadata_gen = @{
    type = $gcjson.visibility.restrictions
    longDescription = $gcjson.overview_ui.en.long_description
    displayName = $gcjson.overview_ui.en.display_name
    imageUrl = $gcjson.images.image
    featuredImageUrl = $gcjson.images.feature_image
    smallImageUrl = $gcjson.images.small_image
    mediumImageUrl = $gcjson.images.medium_image
    documentationUrl = $gcjson.metadata.ui.urls.doc_url
    termsUrl = $gcjson.metadata.ui.urls.terms_url
    instructionsUrl = $gcjson.metadata.ui.urls.instructions_url
    parameters = $gcjson.metadata.service.parameters
    created = $gcjson.created
    updated = $gcjson.updated
}

$main_json = @{
    metadata = $metadata_gen
    name = $gcjson.name
    id = $gcjson.id
    description = $gcjson.overview_ui.en.description
    bindable = $gcjson.metadata.service.bindable
    rc_compatible = $gcjson.metadata.rc_compatible
    iam_compatible = $gcjson.metadata.service.iam_compatible
    plan_updateable = $gcjson.metadata.service.plan_updateable
    unique_api_key = $gcjson.metadata.service.unique_api_key
    provisionable = $gcjson.metadata.service.rc_provisionable
    plans = $plansArray
}

Write-Host "Writing Converted Catalog Json To File"

# Save to file, formatted
$targetFile = "src/assets/data/catalog.json"
$main_json | ConvertTo-Json -Depth 10 | Set-Content $targetFile -Encoding utf8

Write-Host "Done."
