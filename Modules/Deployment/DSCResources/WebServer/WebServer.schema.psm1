Configuration WebServer
{
    param
    (
        [Parameter(Mandatory=$true)]
        [String]$ComputerName
    )
    # Do it manually if it's not a Server OS
    $osCaption = (Get-WmiObject -ComputerName $ComputerName -class Win32_OperatingSystem).Caption
    $isServerOs = $osCaption.Contains("Server")

    if ($isServerOs)
    {
        Import-DscResource -ModuleName xPSDesiredStateConfiguration
        xWindowsFeature DotNetFramework35
        {
            Name = "NET-Framework-Features"
            IncludeAllSubFeature = $true
        }

        xWindowsFeature DotNetFramework45
        {
            Name = "NET-Framework-45-Features"
            IncludeAllSubFeature = $true
        }

        xWindowsFeature IIS
        {
            Name = "Web-Server"
        }

        xWindowsFeature IISDirectoryBrowsing
        {
            Name = "Web-Dir-Browsing"
        }

        xWindowsFeature IISStaticContent
        {
            Name = "Web-Static-Content"
        }

        xWindowsFeature IISManagmentConsole
        {
            Name = "Web-Mgmt-Console"
        }

        xWindowsFeature AspNet45 
        { 
            Name = "Web-Asp-Net45" 
        }
    }
    else
    {
        # xWindowsFeature is giving me grief on windows 10
        Script Install_IIS
        {
            GetScript = {
                return @{ "FeatureState" = (Get-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer").State }
            }

            TestScript = {
                return (Get-WindowsOptionalFeature -Online -FeatureName "IIS-WebServer").State -eq "Enabled"
            }

            SetScript = {
                $featureState = @{}
                $featureList = Get-WindowsOptionalFeature -Online
                foreach ($f in $featureList)
                { 
                    $featureState.Add($f.FeatureName,($f.State -eq 'Enabled'))
                }

                function Check-Feature-Enabled($feature)
                {
                    # return (Get-WindowsOptionalFeature -FeatureName $feature -Online).State -eq 'Enabled'
                    return $featureState[$feature]
                }

                function Enable-Features($featureNames)
                {
                    foreach ($featureName in $featureNames)
                    {
                        if (-not (Check-Feature-Enabled $featureName))
                        {
                            Write-Host "Enabling $featureName"
                            Enable-WindowsOptionalFeature -Online -FeatureName $featureName -All
                        }
                        else 
                        {
                            Write-Host "$featureName already enabled"
                        }
                        if ($LASTEXITCODE -ne 0)
                        {
                            Write-Verbose "Exit code: $LASTEXITCODE"
                            throw
                        }
                    }
                }

                $features = @(
                    "IIS-WebServer",
                    "NetFx4-AdvSrvs",
                    "NetFx4Extended-ASPNET45"
                    "IIS-ManagementConsole",                                          
                    "IIS-ManagementService",   
                    "IIS-WebServerRole",
                    "IIS-CommonHttpFeatures",
                    "IIS-HttpErrors",
                    "IIS-HttpRedirect",
                    "IIS-ApplicationDevelopment",
                    "IIS-NetFxExtensibility45",
                    "IIS-HealthAndDiagnostics",
                    "IIS-HttpLogging",
                    "IIS-LoggingLibraries",
                    "IIS-RequestMonitor",
                    "IIS-HttpTracing",
                    "IIS-Security",                                       
                    "IIS-URLAuthorization",
                    "IIS-RequestFiltering",                                           
                    "IIS-IPSecurity",
                    "IIS-Performance",                                                
                    "IIS-HttpCompressionDynamic",
                    "IIS-WebServerManagementTools",                                   
                    "IIS-ManagementScriptingTools",                                   
                    "IIS-IIS6ManagementCompatibility",
                    "IIS-Metabase",
                    "IIS-HostableWebCore",                              
                    "IIS-StaticContent",                                              
                    "IIS-DirectoryBrowsing",                                          
                    "IIS-WebDAV",
                    "IIS-WebSockets",
                    "IIS-ApplicationInit",
                    "IIS-ASP",                                                       
                    "IIS-CGI",                                                       
                    "IIS-ISAPIExtensions",
                    "IIS-ISAPIFilter",
                    "IIS-ServerSideIncludes",
                    "IIS-CustomLogging",
                    "IIS-BasicAuthentication",
                    "IIS-HttpCompressionStatic",                                                                        
                    "IIS-WMICompatibility",
                    "IIS-LegacyScripts",
                    "IIS-LegacySnapIn",
                    "IIS-FTPServer",
                    "IIS-FTPSvc",
                    "IIS-FTPExtensibility",
                    "IIS-ASPNET45",
                    "IIS-ASPNET",
                    "IIS-NetFxExtensibility"

                )
                Enable-Features $features
            }
        }
    }
}
