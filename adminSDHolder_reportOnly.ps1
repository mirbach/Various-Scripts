# adminSDholder

# protected objects (well-known):
#   users 
#     Administrator                 S-1-5-21-<domain>-500
#     Krbtgt                        S-1-5-21-<domain>-502
#   groups
#     Domain Admins                 S-1-5-21-<domain>-512
#     Domain Controllers            S-1-5-21-<domain>-516
#     Read-only Domain Controllers  S-1-5-21-<domain>-521
#     Schema Admins                 S-1-5-21-<root-domain>-518
#     Enterprise Admins             S-1-5-21-<root-domain>-519
#     Account Operators             S-1-5-32-548
#     Server Operators              S-1-5-32-549
#     Administrators                S-1-5-32-544
#     Print Operators               S-1-5-32-550
#     Backup Operators              S-1-5-32-551
#     Replicator                    S-1-5-32-552

Import-Module ActiveDirectory
$DCcurrentDomain = Get-ADDomainController -Discover -NextClosestSite -Service ADWS
$DCforest = Get-ADDomainController -Discover -NextClosestSite -Service ADWS -DomainName $DCdomain.Forest

$forest = Get-ADForest -Server $DCforest
$objRootDomain = Get-ADDomain -Server $DCforest.Hostname[0]
[hashtable]$protectedObject = @{}
    $protectedObject.Add(('{0}\{1}-518' -f@($DCforest.Domain,$objRootDomain.DomainSID)),[psobject] @{
        Name = 'Schema Admins';
        objectSID = ('{0}-518' -f@($objRootDomain.DomainSID));
        DistinguishedName = '';
        server = $DCforest
        }) # Schema Admins
    $protectedObject.Add(('{0}\{1}-519' -f@($DCforest.Domain,$objRootDomain.DomainSID)),[psobject] @{
        Name = 'Enterprise Admins';
        objectSID = ('{0}-519' -f@($objRootDomain.DomainSID));
        DistinguishedName = '';
        server = $DCforest
        }) # Enterprise Admins

foreach ($domain in $forest.Domains) {
    $DCdomain = Get-ADDomainController -Discover -NextClosestSite -Service ADWS -DomainName $domain
    $objDomain = Get-ADDomain -Server $DCdomain.Hostname[0]
    $protectedObject.Add(('{0}\{1}-500' -f@($DCdomain.Domain,$objDomain.DomainSID)),[psobject] @{
        Name = 'Administrator';
        objectSID = ('{0}-500' -f@($objDomain.DomainSID));
        DistinguishedName = '';
        server = $DCdomain
        }) # Administrator
    $protectedObject.Add(('{0}\{1}-502' -f@($DCdomain.Domain,$objDomain.DomainSID)),[psobject] @{
        Name = 'Krbtgt';
        objectSID = ('{0}-502' -f@($objDomain.DomainSID));
        DistinguishedName = '';
        server = $DCdomain
        }) # Krbtgt
    $protectedObject.Add(('{0}\{1}-512' -f@($DCdomain.Domain,$objDomain.DomainSID)),[psobject] @{
        Name = 'Domain Admins';
        objectSID = ('{0}-512' -f@($objDomain.DomainSID));
        DistinguishedName = '';
        server = $DCdomain
        }) # Domain Admins
    $protectedObject.Add(('{0}\{1}-516' -f@($DCdomain.Domain,$objDomain.DomainSID)),[psobject] @{
        Name = 'Domain Controllers';
        objectSID = ('{0}-516' -f@($objDomain.DomainSID));
        DistinguishedName = '';
        server = $DCdomain
        }) # Domain Controllers
    $protectedObject.Add(('{0}\{1}-521' -f@($DCdomain.Domain,$objDomain.DomainSID)),[psobject] @{
        Name = 'Read-only Domain Controllers';
        objectSID = ('{0}-521' -f@($objDomain.DomainSID));
        DistinguishedName = '';
        server = $DCdomain
        }) # Read-only Domain Controllers
    $protectedObject.Add(('{0}\S-1-5-32-548' -f @($DCdomain.Domain)),[psobject] @{
        Name = 'Account Operators';
        objectSID = 'S-1-5-32-548';
        DistinguishedName = '';
        server = $DCdomain
        }) # Account Operators
    $protectedObject.Add(('{0}\S-1-5-32-549' -f @($DCdomain.Domain)),[psobject] @{
        Name = 'Server Operators';
        objectSID = 'S-1-5-32-549';
        DistinguishedName = '';
        server = $DCdomain
        }) # Server Operators
    $protectedObject.Add(('{0}\S-1-5-32-544' -f @($DCdomain.Domain)),[psobject] @{
        Name = 'Administrators';
        objectSID = 'S-1-5-32-544';
        DistinguishedName = '';
        server = $DCdomain
        }) # Administrators
    $protectedObject.Add(('{0}\S-1-5-32-550' -f @($DCdomain.Domain)),[psobject] @{
        Name = 'Print Operators';
        objectSID = 'S-1-5-32-550';
        DistinguishedName = '';
        server = $DCdomain
        }) # Print Operators
    $protectedObject.Add(('{0}\S-1-5-32-551' -f @($DCdomain.Domain)),[psobject] @{
        Name = 'Backup Operators';
        objectSID = 'S-1-5-32-551';
        DistinguishedName = '';
        server = $DCdomain
        }) # Backup Operators
    $protectedObject.Add(('{0}\S-1-5-32-552' -f @($DCdomain.Domain)),[psobject] @{
        Name = 'Replicator';
        objectSID = 'S-1-5-32-552';
        DistinguishedName = '';
        server = $DCdomain
        }) # Replicator
}

foreach ($objKey in $protectedObject.Keys) {
    $obj = $protectedObject[$objKey]
    $obj.DistinguishedName = (Get-ADObject -LDAPFilter ('objectSid={0}' -f @($obj.objectSID)) -Server $obj.server.HostName[0]).DistinguishedName
}

$adminSdFilter =  ('(&(!(|(DistinguishedName={0})))(|(memberof:1.2.840.113556.1.4.1941:={1})))' -f @(($protectedObject.Values.distinguishedName -join ')(DistinguishedName='),($protectedObject.Values.distinguishedName -join ')(memberof:1.2.840.113556.1.4.1941:=')))
$orphanedFilter = ('(&(adminCount=1)(!(|(DistinguishedName={0})(memberof:1.2.840.113556.1.4.1941:={1}))))' -f @(($protectedObject.Values.distinguishedName -join ')(DistinguishedName='),($protectedObject.Values.distinguishedName -join ')(memberof:1.2.840.113556.1.4.1941:=')))

$orphanedObjects = @()
$adminSdObjects = @()
foreach ($domain in $forest.Domains) {
    $DCdomain = Get-ADDomainController -Discover -NextClosestSite -Service ADWS -DomainName $domain
    $orphanedObjects += Get-ADObject -LDAPFilter $orphanedFilter -Server $DCdomain
    $adminSdObjects  += Get-ADObject -LDAPFilter $adminSdFilter  -Server $DCdomain
}
Write-Host ('orphaned AD objects, protected by Admin SD Holder process: (count: {0})' -f @($orphanedObjects.count)) -NoNewline
$orphanedObjects| ft -Property @('DistinguishedName','Name','ObjectClass','ObjectGUID') -AutoSize

Write-Host ('legitimate AD objects, protected by Admin SD Holder process: (count: {0})' -f @($adminSdObjects.count)) -NoNewline
$adminSdObjects | ft -Property @('DistinguishedName','Name','ObjectClass','ObjectGUID') -AutoSize
