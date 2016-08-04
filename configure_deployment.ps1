$configScript = ".\webserver.ps1"
$configName = "webserver"

# Clean old .mof files
if (Test-Path ".\$configName") {
    Remove-Item ".\$configName\*.mof" -force
}


# Load and compile the DSC
& $configScript

# Run the DSC
Start-DscConfiguration -Force -Verbose -Wait -Path ".\$configName"