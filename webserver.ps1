Configuration WebServer
{
    param(
        [string[]]$ComputerName="localhost"
    )

    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
    # Import-DSCResource -ModuleName @{ModuleName="xSQLServer";ModuleVersion="1.4.0.0"}
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

        xWebAppPool NewWebAppPool 
        { 
            Name   = "MyWebAppPool"
            Ensure = "Present" 
            State  = "Started" 
        } 

        # File WebContent 
        # { 
        #     Ensure          = "Present" 
        #     SourcePath      = $SourcePath 
        #     DestinationPath = $DestinationPath 
        #     Recurse         = $true 
        #     Type            = "Directory" 
        #     DependsOn       = "[WindowsFeature]AspNet45" 
        # }

        xWebsite DefaultWebSite 
        {
            Ensure          = "Present" 
            Name            = "Default Web Site" 
            State           = "Stopped" 
            PhysicalPath    = "C:\inetpub\wwwroot" 
            DependsOn       = "[WindowsFeature]IIS"  
        }

        # xWebsite MyWebSite 
        # {
        #     Ensure          = "Present" 
        #     Name            = "MyWebSite" 
        #     State           = "Started" 
        #     PhysicalPath    = $DestinationPath 
        #     BindingInfo     = MSFT_xWebBindingInformation 
        #                     { 
        #                         Protocol = "HTTP" 
        #                         Port     = 80
        #                     }
        #     DependsOn       = "[File]WebContent" 
        # }

    }
}
WebServer