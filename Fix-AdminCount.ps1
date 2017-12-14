$users = Get-ADUser -ldapfilter “(objectclass=user)” -searchbase “DC=forest1,DC=net”

#Get domain values
$domain = Get-ADDomain 
$domainPdc = $domain.PDCEmulator
$domainDn = $domain.DistinguishedName

#HashTable to be used for the reset
$replaceAttributeHashTable = New-Object HashTable 
$replaceAttributeHashTable.Add("AdminCount",0)

$isProtected = $false ## allows inheritance
$preserveInheritance = $true ## preserve inheritance rules


ForEach($user in $users)
{
    # Binding the users to DS
    $ou = [ADSI](“LDAP://” + $user)
    $sec = $ou.psbase.objectSecurity

    if ($sec.get_AreAccessRulesProtected())
    {
		#Changes AdminCount back to &lt;not set&gt;
        Get-ADuser $user.DistinguishedName -Properties "admincount" | Set-ADUser -Remove $replaceAttributeHashTable  -Server $domainPdc
        #Change security and commit
		$sec.SetAccessRuleProtection($isProtected, $preserveInheritance)
        $ou.psbase.commitchanges()
    }
}