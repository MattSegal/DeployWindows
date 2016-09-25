# Copy this script onto the server and run it
# TODO: Use PSSession to do this remotely

try 
{
    $ErrorActionPreference = "Stop"

    Write-Host "Applying 'RemoteSigned' execution policy."
    # You may have to run this manually
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
    
    #  Chocolately
    $isChocoInstalled =  $env:ChocolateyInstall.Length -gt 0
    if(!$isChocoInstalled) 
    {
        Write-Host "Installing Chocolatey package manager."
        $ChocolateyBootstrapUrl = 'https://chocolatey.org/install.ps1'
        Invoke-WebRequest $ChocolateyBootstrapUrl -UseBasicParsing | Invoke-Expression
    }

    # Load Chocolatey environment variables
    RefreshEnv

    choco install dotnet4.5 -y
    choco install powershell -y

    if ($PSVersionTable.PSVersion.Major -lt 5) 
    {
        Write-Host "Bootstrap half done. Press 'r' to restart, press any other key to close."
        $userInput = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        $isRestartUserInput = $userInput.Character -eq 'r'
        if ($isRestartUserInput)
        {
            Invoke-Reboot
        }
        else 
        {
            exit 0
        }
    }

    # Setup PowerShell DSC
    Write-Host "Installing PackageManagement module"
    Import-Module PackageManagement
    Get-PackageProvider -Name NuGet -Force -ForceBootstrap
    Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

    Write-Host "Installing DSC modules"
    Install-Module xWebAdministration
    Install-Module xPSDesiredStateConfiguration
    Install-Module cChoco

    # Try load git into path
    RefreshEnv

    # Show hidden files and folders (need to restart Windows Explorer)
    $key = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty $key Hidden 1
    Set-ItemProperty $key HideFileExt 0
    Set-ItemProperty $key ShowSuperHidden 1

    # Pull setup scripts
    $scriptsDir = "C:\Setup"
    if (Test-Path "$scriptsDir\.git")
    {
        Write-Host "Pulling latest version of setup code"
        $here = Get-Location
        cd $scriptsDir
        git pull
        cd $here
    }
    else 
    {
        Write-Host "Cloning setup code into $scriptsDir"
        Start-Process -FilePath git -ArgumentList "clone https://github.com/MattSegal/DeployWindows.git $scriptsDir" -Wait
    }

    # Add setup modules to PSModulePath
    $setupModules = Join-Path $scriptsDir "Modules"
    if (-Not (Test-Path $setupModules))
    {
        throw "$setupModules not found"
    }
    $PSModulePath = [Environment]::GetEnvironmentVariable("PSModulePath","Machine")
    $PSModulePath = "$PSModulePath;$setupModules"
    [Environment]::SetEnvironmentVariable("PSModulePath",$PSModulePath,"Machine")
    $env:PSModulePath = [Environment]::GetEnvironmentVariable("PSModulePath","Machine")

    # Pull web app
    $here = Get-Location
    $appDir = "C:\RedditFollower"
    cd $appDir
    if (-not ((Test-Path $appDir) -and (Test-Path $appDir\.git))) 
    {
        if (-not (Test-Path $appDir))
        {
            New-Item $appDir -type directory
        }
        
        git clone https://github.com/MattSegal/RedditFollowerDeploy.git .
    } 
    else
    {
        git pull "https://github.com/MattSegal/RedditFollowerDeploy.git"
    } 
    cd $here 

    Write-Host "Add PowerShell profile"
    $customProfile = Join-Path $scriptsDir "\Scripts\profile.ps1"
    Copy-Item $customProfile $profile

    Write-Host "Applying DSC"
    $RedditFollowerDSC = Join-Path $scriptsDir "\Configurations\RedditFollower.ps1"
    &  $RedditFollowerDSC -ApplicationRoot $appDir
} 
catch 
{
    $logDir = "C:\Temp"
    $logPath = "$logDir\bootstrap.log"
    if (!(Test-Path $logDir))
    {
        New-Item -Type Directory -Path $logDir
    }
    Write-Host "Logging exception at $logPath"
    Out-File -FilePath $logPath -InputObject ($Error[0] | Out-String)
    exit 1
}



