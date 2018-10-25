configuration NewDomain
{
    $passwd = ConvertTo-SecureString -String 'L1nk1np@rk' -AsPlainText -Force
    $credential = New-Object -TypeName pscredential -ArgumentList Administrator,$passwd
    
    Import-DscResource -ModuleName  'PSDesiredStateConfiguration',
                                    'ComputerManagementDsc',
                                    'NetworkingDsc',
                                    'WebAdministrationDsc',
                                    'xComputerManagement',
                                    'xActiveDirectory',
                                    'xDnsServer',
                                    'xNetworking',
                                    'xPendingReboot',
                                    'SqlServerDsc',
                                    'xFailOverCluster'


    node $allnodes.nodename
    {

        $domaincreds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ("$($node.DomainName)\$($Credential.UserName)", $Credential.Password)

        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyOnly'
            AllowModuleOverwrite = $true
            ActionAfterReboot = 'ContinueConfiguration'
        }

        DnsServerAddress PrimaryDNSClient
        {
            InterfaceAlias = $node.InterfaceAlias
            AddressFamily = 'IPv4'
            Address = $node.DNSAddress
        }

        Computer NewName
        {
            Name = $node.NewNodeName
            DependsOn = '[DnsServerAddress]PrimaryDNSClient'

        }

        foreach ($feature in @(
                'DNS',                           
                'AD-Domain-Services',
                'RSAT-AD-Tools', 
                'RSAT-AD-PowerShell',
                'GPMC'
                'RSAT-DNS-Server',                     
                'RSAT-AD-AdminCenter',
                'RSAT-ADDS-Tools'

            )) 
        {
            WindowsFeature $feature.Replace('-','') 
            {
                Ensure = 'Present'
                Name = $feature
                IncludeAllSubFeature = $False
                DependsOn = '[Computer]NewName'
            }
        }

        

        xADDomain FirstDC
        {
            DomainName = $node.DomainName
            DomainAdministratorCredential = $domaincreds
            SafemodeAdministratorPassword = $domaincreds
            DomainNetbiosName = $node.NetBiosName
            DatabasePath = $node.DCDatabasePath
            LogPath = $node.DCLogPath
            SysvolPath = $node.SysvolPath
            DependsOn = '[WindowsFeature]ADDomainServices'
        }

        xADUser bspell
        {
            DomainName = $node.DomainName
            Path = "CN=Users,$($node.DomainDN)"
            UserName = 'bspell'
            DisplayName = 'Brandon Spell'
            Enabled = $true
            Ensure = 'Present'
            Password = $Credential
            PasswordNeverExpires = $true
            DomainAdministratorCredential = $Credential
            DependsOn = '[xADDomain]FirstDC'
        }

        xADGroup DomainAdmins
        {
            GroupName = 'Domain Admins'
            Path = "CN=Users,$($node.DomainDN)"
            Category = 'Security'
            GroupScope = 'Global'
            MembersToInclude = 'bspell'
            DependsOn = '[xADUser]bspell'
        }

        xDnsServerADZone ReverseDNS
        {
            Name = '1.168.192.in-addr.arpa'
            DynamicUpdate = 'Secure'
            ReplicationScope = 'Forest'
            Ensure = 'Present'
            DependsOn = '[xADDomain]FirstDC'
        }
        
    }
}