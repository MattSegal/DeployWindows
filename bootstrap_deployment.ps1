$BootstrapSettngs = @{
    DeploymentDir               = "C:\Deploy"
    SetupDir                    = "C:\Setup"
    SetExecutionPolicy          = $false;
    InstallSqlServer            = $false;
    InstallDotNet               = $true;
    InstallDSC                  = $true;
    InstallUtils                = $true;
    EnableConvenienceFeatures   = $false;
}

try {
    $ErrorActionPreference = "Stop"

    # Execution Policy
    if ($BootstrapSettngs.SetExecutionPolicy) {
        Write-Host "Applying 'Bypass' execution policy."
        Set-ExecutionPolicy Bypass
    }
    
    # Deployment Directory
    if ((Test-Path $BootstrapSettngs.DeploymentDir) -eq $false) {
        New-Item $BootstrapSettngs.DeploymentDir -type Directory
    }

    # Setup Directory
    if ((Test-Path $BootstrapSettngs.SetupDir) -eq $false) {
        New-Item $BootstrapSettngs.SetupDir -type Directory
    }

    #  Chocolately
    $isChocoInstalled =  $env:ChocolateyInstall.Length -gt 0
    if(!$isChocoInstalled) {
        Write-Host "Installing Chocolatey package manager."
        $ChocolateyBootstrapUrl = 'https://chocolatey.org/install.ps1'
        Invoke-WebRequest $ChocolateyBootstrapUrl -UseBasicParsing | Invoke-Expression
    }

    # .NET 4.5
    if($BootstrapSettngs.InstallDotNet) {
        Write-Host "Installing .NET 4.5."
        choco install dotnet4.5 -y
    }
    
    # PowerShell
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Host "Installing PowerShell and WMF 5."
        choco install powershell -y
    }

    # SQL Server
    if ($BootstrapSettngs.InstallSqlServer) {
        Write-Host "Installing MS SQL Server Express 2014."
        # choco install mssql2014express-defaultinstance -y
        Start-Process .\SqlLocalDB.msi
        # msiexec /i ".\SqlLocalDB.msi"
    }
    
    # PowerShell DSC
    if($BootstrapSettngs.InstallDSC) {
        Write-Host "Installing PackageManagement module"
        Import-Module PackageManagement
        Get-PackageProvider -Name NuGet -Force -ForceBootstrap
        Set-PSRepository -InstallationPolicy Trusted -Name PSGallery

        Write-Host "Installing DSC modules"
    #     Install-Module xStorage -RequiredVersion 2.4.0.0
        Install-Module xWebAdministration -RequiredVersion 1.9.0.0
    #     Install-Module xNetworking -RequiredVersion 2.7.0.0 
    #     Install-Module xCertificate -RequiredVersion 1.1.0.0
    #     Install-Module "xPSDesiredStateConfiguration" -RequiredVersion 3.7.0.0
    #     Install-Module Carbon -RequiredVersion 2.0.1
    #     Install-Module cChoco -RequiredVersion 2.0.5.22
    #     Install-Module cMsmq -RequiredVersion 1.0.3
        Install-Module xSQLServer -RequiredVersion 1.4.0.0
    }

    # Utilities
    if ($BootstrapSettngs.InstallUtils) {
        choco install git
        choco install python2
    }

    # Convenience Features
    if ($BootstrapSettngs.EnableConvenienceFeatures) {
        Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions
        Disable-UAC
        Disable-BingSearch
        choco install sublimetext3 -y
    }

} catch {
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


Write-Host "Bootstrap done. Press 'r' to restart, press any other key to close."
$userInput = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

$isRestartUserInput = $userInput.Character -eq 'r'
if ($isRestartUserInput)
{
    Invoke-Reboot
}