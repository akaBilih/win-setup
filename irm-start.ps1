#####
# Functions
#####

#####
# Script
#####

# Set the URL of the zip file
$zipFileUrl = "https://github.com/akaBilih/win-setup/archive/refs/heads/main.zip"

# Set the temporary folder path
$tempFolder = Join-Path -Path $env:TEMP -ChildPath "WinSetupTemp"

# Check if the temporary folder already exists, and if so, delete it to avoid collisions
if (Test-Path -Path $tempFolder -PathType Container) {
    Remove-Item -Path $tempFolder -Force -Recurse
}

# Create the temporary folder
New-Item -ItemType Directory -Path $tempFolder | Out-Null

# Set the path for the downloaded zip file
$zipFilePath = Join-Path -Path $tempFolder -ChildPath "main.zip"

# Download the zip file
Invoke-WebRequest -Uri $zipFileUrl -OutFile $zipFilePath

# Set the destination path for extracting the contents
$extractedFolder = $tempFolder

# Extract the contents of the zip file to a subfolder within the extracted folder
Expand-Archive -Path $zipFilePath -DestinationPath $extractedFolder

# Get the first-level folder name within the extracted files
$firstLevelFolder = Get-ChildItem -Path $extractedFolder | Where-Object { $_.PSIsContainer } | Select-Object -First 1

# Move the content from the first-level folder to the root of the extracted folder
Get-ChildItem -Path ($firstLevelFolder.FullName + "\*") | Move-Item -Destination $extractedFolder

# Remove the first-level folder
Remove-Item -Path $firstLevelFolder.FullName -Force -Recurse

# Clean up the temporary zip file
Remove-Item -Path $zipFilePath -Force

# Execute the "setup.cmd" file in the root of the temporary folder
$setupCmdPath = Join-Path -Path $tempFolder -ChildPath "setup.cmd"
if (Test-Path -Path $setupCmdPath -PathType Leaf) {
    Write-Output "Executing setup.cmd..."
    Push-Location
    Set-Location Env:
    Set-Location $tempFolder
    $setupprcs = Start-Process -NoNewWindow -PassThru -FilePath $setupCmdPath 
    $setupprcs.WaitForExit()
    Write-Output "Setup completed."
    Pop-Location
}
else {
    Write-Output "setup.cmd not found in the root of the temporary folder."
}