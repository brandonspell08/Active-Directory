Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module powershellmodule

configuration NewDomain             
{             
   param             
    (             
        [Parameter()]             
        [pscredential]$Creds = (New-Object -TypeName pscredential -ArgumentList 'Administrator',$(ConvertTo-SecureString -String "Armorsupport!1" -AsPlainText -Force))
    )             
            
#region DSC Resources
    Import-DSCresource -ModuleName PSDesiredStateConfiguration,xActiveDirectory,xComputerManagement
    
#region Domain Controller config
    Node $AllNodes.Where{$_.Role -eq "Primary DC"}.Nodename             
    {
        $domaincreds = New-Object -TypeName pscredential -ArgumentList 'armorsupportlab.local\Administrator',$(ConvertTo-SecureString -String "Armorsupport!1" -AsPlainText -Force)     
        
        xComputer ComputerName { 
            Name = $Node.NodeName 
        }            
         
        LocalConfigurationManager            
        {            
            ActionAfterReboot = 'ContinueConfiguration'            
            ConfigurationMode = 'ApplyOnly'            
            RebootNodeIfNeeded = $true            
        }            
                    
        
        foreach ($feature in @(
                'DNS',
                'AD-Domain-Services',
                'RSAT-AD-Tools',
                'RSAT-AD-PowerShell'
                'GPMC',
                'RSAT-DNS-Server',                     
                'RSAT-AD-AdminCenter',
                'RSAT-ADDS-Tools'
        )){
            WindowsFeature $feature.Replace('-','') {
                    Ensure = 'Present';
                    Name = $feature;
                    IncludeAllSubFeature = $false
                }
        }
                              
        # No slash at end of folder paths            
        xADDomain FirstDS             
        {             
            DomainName = $Node.DomainName             
            DomainAdministratorCredential = $creds
            DomainNetbiosName = 'ASL'
            SafemodeAdministratorPassword = $creds
            DatabasePath = 'C:\NTDS'
            LogPath = 'C:\NTDS'
            SysvolPath = 'C:\Sysvol'
            DependsOn = '[WindowsFeature]ADDomainServices'
        }
    }
#endregion

              
}            

            
# Configuration Data for AD              
$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "AD1"             
            Role = "Primary DC"             
            DomainName = "armorsupportlab.local"             
            RetryCount = 20              
            RetryIntervalSec = 30            
            PsDscAllowPlainTextPassword = $true
            PsDscallowDomainuser=$true           
        }            
    )             
}             

#install psget and nuget
'nuget.org','psgallery' | foreach{
$p = $_
try{
$pkg = Get-PackageSource -Name $p -ErrorAction Stop
if(!($pkg.istrusted)){
    $pkg | Set-PackageSource -Trusted -ForceBootstrap -Confirm:$false -Force | Out-Null
        }
    }
catch{
Find-PackageProvider -Name NUGET -Force | Install-PackageProvider -Force | Register-PackageSource -Trusted -ForceBootstrap -Confirm:$false
}
}
#check and disable IPV6 if needed
$ipv6 = try{Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters -Name DisabledComponents -ErrorAction stop}catch{$false}
if(!$ipv6){Set-ItemProperty -Path hklm:\SYSTEM\CurrentControlSet\services\TCPIP6\Parameters -name DisabledComponents -value 0xffffffff}

'xActiveDirectory','xComputerManagement','xPendingReboot' | foreach{Install-Module -Name $_ -Force}
           
NewDomain -ConfigurationData $ConfigData         
            
# Make sure that LCM is set to continue configuration after reboot            
Set-DSCLocalConfigurationManager -Path .\NewDomain –Verbose            
            
# Build the domain            
Start-DscConfiguration -Wait -Force -Path .\NewDomain -Verbose       