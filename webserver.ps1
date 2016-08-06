Configuration WebServer
{
    param(
        [string[]]$ComputerName="localhost"
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    Import-DSCResource -ModuleName @{ModuleName="xWebAdministration";ModuleVersion="1.9.0.0"}

    Node $ComputerName
    {
        WindowsFeature DotNetFramework35
        {
            Name = "NET-Framework-Features"
            IncludeAllSubFeature = $true
        }

        WindowsFeature DotNetFramework45
        {
            Name = "NET-Framework-45-Features"
            IncludeAllSubFeature = $true
        }

        WindowsFeature IIS
        {
            Ensure  = "Present"
            Name    = "Web-Server"
        }

        WindowsFeature IISDirectoryBrowsing
        {
            Ensure  = "Present"
            Name    = "Web-Dir-Browsing"
        }

        WindowsFeature IISStaticContent
        {
            Ensure  = "Present"
            Name    = "Web-Static-Content"
        }

        WindowsFeature IISManagmentConsole
        {
            Ensure  = "Present"
            Name    = "Web-Mgmt-Console"
        }

        WindowsFeature AspNet45 
        { 
            Ensure  = "Present" 
            Name    = "Web-Asp-Net45" 
        } 

        xWebAppPool RedditFollowerAppPool 
        { 
            Name   = "RedditFollowerAppPool"
            Ensure = "Present" 
            State  = "Started" 
            managedPipelineMode = "Integrated"
            managedRuntimeVersion = "v4.0"
            identityType = "ApplicationPoolIdentity"
            startMode = "AlwaysRunning"
        } 

        xWebsite DefaultWebSite 
        {
            Ensure          = "Present" 
            Name            = "Default Web Site" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\wwwroot" 
            DependsOn       = "[WindowsFeature]IIS"  
        }

        xWebsite RedditFollower 
        {
            Ensure          = "Present" 
            Name            = "RedditFollower" 
            State           = "Started" 
            PhysicalPath    = "C:\RedditFollower"
            BindingInfo     = MSFT_xWebBindingInformation 
                            { 
                                Protocol = "HTTP" 
                                Port     = 80
                            }
            DependsOn       = "[xWebAppPool]RedditFollowerAppPool" 
            ApplicationPool = "RedditFollowerAppPool"
        }

        xWebApplication RedditFollowerWeb
        {
            Name = "RedditFollowerWeb"
            Website = "RedditFollower"
            Ensure = "Present" 
            PhysicalPath = "C:\RedditFollower\RedditFollowerWeb"
            WebAppPool = "RedditFollowerAppPool"
            DependsOn = "[xWebsite]RedditFollower" 
        }

        xWebApplication RedditFollowerApi
        {
            Name = "RedditFollowerApi"
            Website = "RedditFollower"
            Ensure = "Present" 
            PhysicalPath = "C:\RedditFollower\RedditFollowerApi"
            WebAppPool = "RedditFollowerAppPool"
            DependsOn = "[xWebsite]RedditFollower" 
        }

    }
}
WebServer