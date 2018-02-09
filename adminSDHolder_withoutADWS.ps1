# adminSDholder
# https://msdn.microsoft.com/en-us/library/dd240052.aspx
# https://technet.microsoft.com/en-us/library/2009.09.sdadminholder.aspx
#
# protected objects (well-known):
#   users                           sid                    exclude? version
#     Administrator                 S-1-5-21-<domain>-500          all
#     Krbtgt                        S-1-5-21-<domain>-502          all
#   groups
#     Schema Admins                 S-1-5-21-<root-domain>-518     all
#     Enterprise Admins             S-1-5-21-<root-domain>-519     all
#     Domain Admins                 S-1-5-21-<domain>-512          all
#     Domain Controllers            S-1-5-21-<domain>-516          > Windows 2000 Server SP4
#     Cert Publishers               S-1-5-21-<domain>-517          > Windows 2000 Server SP4 && < Windows Server 2003 SP1
#     Read-only Domain Controllers  S-1-5-21-<domain>-521          > Windows Server 2008
#     Account Operators             S-1-5-32-548                0  > Windows 2000 Server SP4
#     Server Operators              S-1-5-32-549                1  > Windows 2000 Server SP4
#     Administrators                S-1-5-32-544                   > Windows 2000 Server SP4
#     Print Operators               S-1-5-32-550                2  > Windows 2000 Server SP4
#     Backup Operators              S-1-5-32-551                3  > Windows 2000 Server SP4
#     Replicator                    S-1-5-32-552                   > Windows 2000 Server SP4

$triggerSdHolder = $false
$doCleanup = $false

$runProtectAdminGroupsTaskFile = [io.path]::GetTempFileName()            
Set-Content -Path $runProtectAdminGroupsTaskFile -Value @'
dn:
changetype: modify
add: runProtectAdminGroupsTask
runProtectAdminGroupsTask: 1
-
'@             

$Searcher = New-Object System.DirectoryServices.DirectorySearcher 
$Searcher.PageSize = 1000 
$Searcher.SearchScope = 'SubTree'
# Attributes to be retrieved. 
$Searcher.PropertiesToLoad.Add('distinguishedName') | Out-Null
$Searcher.PropertiesToLoad.Add('objectSID') | Out-Null 
$Searcher.PropertiesToLoad.Add('sAMAccountName') | Out-Null 
$Searcher.PropertiesToLoad.Add('objectCategory') | Out-Null
$Searcher.PropertiesToLoad.Add('adminCount') | Out-Null
$Searcher.PropertiesToLoad.Add('ObjectGUID') | Out-Null


$forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest() 
$forestRootSid = [string]((New-Object System.Security.Principal.SecurityIdentifier (([adsi]('LDAP://{0}' -f @($forest.RootDomain.PdcRoleOwner.GetDirectoryEntry()).serverReference))).objectSid[0], 0)).AccountDomainSid
$objRootDomain = $forest.RootDomain
$objRootDomainPdc = ([adsi]('LDAP://{0}' -f @($objRootDomain.PdcRoleOwner.GetDirectoryEntry()).serverReference))

[hashtable]$protectedObject = @{}
    $protectedObject.Add(('{0}\{1}-518' -f@($objRootDomain.Name,$forestRootSid)),[psobject] @{
        Name = 'Schema Admins';
        objectSID = ('{0}-518' -f@($forestRootSid));
        DistinguishedName = '';
        object = $null
        domainPDC = $objRootDomainPdc
        domain = $objRootDomain
        type = 'group'
        }) # Schema Admins
    $protectedObject.Add(('{0}\{1}-519' -f@($objRootDomain.Name,$forestRootSid)),[psobject] @{
        Name = 'Enterprise Admins';
        objectSID = ('{0}-519' -f@($forestRootSid));
        DistinguishedName = '';
        object = $null
        domainPDC = $objRootDomainPdc
        domain = $objRootDomain
        type = 'group'
        }) # Enterprise Admins

foreach ($domain in $forest.Domains) {
    $objDomainPdc = ([adsi]('LDAP://{0}' -f @($domain.PdcRoleOwner.GetDirectoryEntry()).serverReference)) # $domain.PdcRoleOwner #Get-ADComputer -Identity ([string]($domain.PdcRoleOwner.GetDirectoryEntry().serverreference)) -Properties @('OperatingSystem','OperatingSystemHotfix','OperatingSystemServicePack','OperatingSystemVersion') -Server $DCdomain.Hostname[0]

    $DomainSid = [string]((New-Object System.Security.Principal.SecurityIdentifier $objDomainPdc.objectSid[0], 0)).AccountDomainSid

    if (($triggerSdHolder) -and (Test-Path -Path 'C:\Windows\system32\ldifde.exe' -PathType Leaf)) {
        Write-Host ('{1}: Initiate runProtectAdminGroupsTask on PDC "{0}"' -f @($domain.PdcRoleOwner.Name,$domain.Name))
        C:\Windows\system32\ldifde.exe -s $domain.PdcRoleOwner.Name -i -f $runProtectAdminGroupsTaskFile
    } else { Write-Host ('{0}: Not triggering adminSDHolder Process' -f @($domain.Name)) -ForegroundColor Yellow }

    # Administrator, krgtgt, Domain Admins and forest wide entries (Schema admins, Enterprise admins) are in any version relevant!
    $protectedObject.Add(('{0}\{1}-500' -f@($domain.Name,$DomainSID)),[psobject] @{
        Name = 'Administrator';
        objectSID = ('{0}-500' -f@($DomainSID));
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'user'
        }) # Administrator
    $protectedObject.Add(('{0}\{1}-502' -f@($Domain.Name,$DomainSID)),[psobject] @{
        Name = 'Krbtgt';
        objectSID = ('{0}-502' -f@($DomainSID));
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'user'
        }) # Krbtgt
    $protectedObject.Add(('{0}\{1}-512' -f@($domain.Name,$DomainSID)),[psobject] @{
        Name = 'Domain Admins';
        objectSID = ('{0}-512' -f@($DomainSID));
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Domain Admins
 <#  
    # Windows 2000 Server SP4
    if (($objDomainPdc.OperatingSystemVersion -like '5.0*') -and (($objDomainPdc.OperatingSystemServicePack -eq 'Service Pack 4') -or ($objDomainPdc.OperatingSystemHotfix -eq '327825'))) {
        $protectedGroups = @('Domain Controllers','Administrators','Replicator','Account Operators','Server Operators','Print Operators','Backup Operators')
    }
    # Windows 2000 Server SP4 && < Windows Server 2003 SP1
    if (($objDomainPdc.OperatingSystemVersion -like '5.0*') -and (($objDomainPdc.OperatingSystemServicePack -eq 'Service Pack 4') -or ($objDomainPdc.OperatingSystemHotfix -eq '327825'))) {
        $protectedGroups = @('Domain Controllers','Administrators','Replicator','Account Operators','Server Operators','Print Operators','Backup Operators')
    }
        
    }
#>
    $protectedObject.Add(('{0}\{1}-516' -f@($Domain.Name,$DomainSID)),[psobject] @{
        Name = 'Domain Controllers';
        objectSID = ('{0}-516' -f@($DomainSID));
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Domain Controllers
    $protectedObject.Add(('{0}\{1}-521' -f@($domain.name,$DomainSID)),[psobject] @{
        Name = 'Read-only Domain Controllers';
        objectSID = ('{0}-521' -f@($DomainSID));
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Read-only Domain Controllers
    $protectedObject.Add(('{0}\S-1-5-32-548' -f @($Domain.Name)),[psobject] @{
        Name = 'Account Operators';
        objectSID = 'S-1-5-32-548';
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Account Operators
    $protectedObject.Add(('{0}\S-1-5-32-549' -f @($domain.Name)),[psobject] @{
        Name = 'Server Operators';
        objectSID = 'S-1-5-32-549';
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Server Operators
    $protectedObject.Add(('{0}\S-1-5-32-544' -f @($Domain.Name)),[psobject] @{
        Name = 'Administrators';
        objectSID = 'S-1-5-32-544';
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Administrators
    $protectedObject.Add(('{0}\S-1-5-32-550' -f @($Domain.Name)),[psobject] @{
        Name = 'Print Operators';
        objectSID = 'S-1-5-32-550';
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Print Operators
    $protectedObject.Add(('{0}\S-1-5-32-551' -f @($domain.Name)),[psobject] @{
        Name = 'Backup Operators';
        objectSID = 'S-1-5-32-551';
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Backup Operators
    $protectedObject.Add(('{0}\S-1-5-32-552' -f @($Domain.Name)),[psobject] @{
        Name = 'Replicator';
        objectSID = 'S-1-5-32-552';
        DistinguishedName = '';
        object = $null
        domainPDC = $objDomainPdc
        domain = $domain
        type = 'group'
        }) # Replicator
}

rm -Path $runProtectAdminGroupsTaskFile

foreach ($objKey in $protectedObject.Keys) {
    $obj = $protectedObject[$objKey]
    $ldap = ('LDAP://{1}/<SID={0}>' -f @($obj.objectSID,$obj.domainPDC.dNSHostName[0]))
    $obj.DistinguishedName = ([adsi]$ldap).DistinguishedName
}

$adminSdFilter =  ('(&(!(|(DistinguishedName={0})))(|(memberof:1.2.840.113556.1.4.1941:={1})))' -f @(($protectedObject.Values.distinguishedName -join ')(DistinguishedName='),($protectedObject.Values.distinguishedName -join ')(memberof:1.2.840.113556.1.4.1941:=')))
#$adminSdFilter =  ('(|(DistinguishedName={0})(memberof:1.2.840.113556.1.4.1941:={1}))' -f @(($protectedObject.Values.distinguishedName -join ')(DistinguishedName='),($protectedObject.Values.distinguishedName -join ')(memberof:1.2.840.113556.1.4.1941:=')))
$orphanedFilter = ('(&(adminCount=1)(!(|(DistinguishedName={0})(memberof:1.2.840.113556.1.4.1941:={1}))))' -f @(($protectedObject.Values.distinguishedName -join ')(DistinguishedName='),($protectedObject.Values.distinguishedName -join ')(memberof:1.2.840.113556.1.4.1941:=')))

$orphanedObjects = @()
$adminSdObjects = @()

if ($triggerSdHolder) {
    Write-Host ('Pause to wait for finishing the adminSDHolder process(es)') -ForegroundColor Cyan
    $continue = Read-Host ('Please press return/enter key to continue...') -AsSecureString
}

foreach ($domain in $forest.Domains) {
    $Searcher.SearchRoot = ('LDAP://{0}' -f @(($Domain.GetDirectoryEntry()).distinguishedName))
    $Searcher.Filter = $orphanedFilter
    $orphanedObjects += $Searcher.FindAll()

    $Searcher.Filter = $adminSdFilter
    $adminSdObjects  += $Searcher.FindAll()
}

$table = @(@{Expression={$_.properties.samaccountname[0]};Label='sAMAccountname'}, @{Expression={$_.properties.distinguishedname[0]};Label='DistinguishedName'},@{Expression={(($_.properties.objectcategory[0] -split ',')[0]).Remove(0,3)};Label='objectCategory'})

Write-Host ('orphaned AD objects, protected by Admin SD Holder process: (count: {0})' -f @($orphanedObjects.count)) -NoNewline
$orphanedObjects | ft -Property $table -AutoSize

Write-Host ('legitimate AD objects, protected by Admin SD Holder process: (count: {0})' -f @($adminSdObjects.count)) -NoNewline
$adminSdObjects | ft -Property $table -AutoSize

if ($doCleanup) {

}