# Set the range and generate a random number between 10000 and 32767
$min = 10000
$max = 32767
$random = Get-Random -Minimum $min -Maximum ($max + 1)

# Get current date in MM-dd-yyyy format
$dateStr = Get-Date -Format "MM-dd-yyyy"

# Combine for build number
$BUILD_NUMBER = "$random-$dateStr"

Write-Output $BUILD_NUMBER
