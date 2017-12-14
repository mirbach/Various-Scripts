#Set Variable users to get all User objects within OU specified in searchbase
$users = Get-ADUser -ldapfilter “(objectclass=user)” -searchbase “DC=forest1,DC=net”
$CSVPath = ($env:USERPROFILE + '\Documents\AdminSDHolder.txt')
$list = @()

ForEach($user in $users)
{
    # Binding the users to DS
    $ou = [ADSI](“LDAP://” + $user)
    $sec = $ou.psbase.objectSecurity

    if ($sec.get_AreAccessRulesProtected()) #If the account is protected. The statement returns true and runs the script block.
    {
	    $list += get-aduser $user.DistinguishedName -Properties "admincount" | select Name,
        @{N="AdminCount"; E={$_.AdminCount}}        
    }
}
$list | Export-Csv $CSVPath -NoTypeInformation