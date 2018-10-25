
#enable PS Remoting
Enable-PSRemoting –force -SkipNetworkProfileCheck -Confirm:$false
Set-Service WinRM -StartMode Automatic
Set-Item WSMan:localhost\client\trustedhosts -value * -Force

#Install Nuget and secure PSGallery. Then Install PowershellModule installer to do the rest...
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Get-PackageSource -Name PSGallery | Set-PackageSource -Trusted -Force -ForceBootstrap | Out-Null

$modules = 'powershellmodule',
    'xComputerManagement',
    'xActiveDirectory',
    'xDnsServer',
    'xNetworking',
    'xPendingReboot',
    'NetworkingDsc',
    'WebAdministrationDsc',
    'SqlServerDsc',
    'xFailOverCluster',
    'ComputerManagementDsc'
Install-Module -Name $modules -Confirm:$false

$configdata = @{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            NewNodeName = 'bsad01'
            Password = 'L1nk1np@rk'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser = $true
            DomainName = "spellingb.local"
            DomainDN = "DC=spellingb,DC=local"
            DCDatabasePath = "C:\NTDS"
            DCLogPath = "C:\NTDS"
            SysvolPath = "C:\Sysvol"
            InterfaceAlias = "Ethernet0"
            IPAddress = "192.168.1.10"
            DNSAddress = "192.168.1.10"
            GatewayAddress = "192.168.1.1"
        }
    )
}

#Import DSC Configs
#Import-Module .\ModInstall.ps1

#DSC Install Modules
#ModInstall  | Out-Null
#Start-DscConfiguration -Wait -Force -Path .\ModInstall\ 


Import-Module .\NewDomain.ps1
NewDomain -ConfigurationData $configdata | Out-Null
Set-DSCLocalConfigurationManager -Path .\NewDomain –Verbose
Start-DscConfiguration -Wait -Force -Path .\NewDomain\ -Verbose