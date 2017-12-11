Param ( 
    [Parameter(Mandatory=$true, 
        Position=0, 
        ValueFromPipeline=$true, 
        HelpMessage="DN or ObjectGUID of the AD Group." 
    )] 
    [string]$groupIdentity, 
    [switch]$showTree 
    ) 
ErrorActionPreference = 'SilentlyContinue'
$global:numberOfRecursiveGroupMemberships = 0 
$lastGroupAtALevelFlags = @() 
function Get-GroupNesting ([string] $identity, [int] $level, [hashtable] $groupsVisitedBeforeThisOne, [bool] $lastGroupOfTheLevel) 
{ 
    $group = $null 
    $group = Get-ADObject -Identity $identity -Properties "member"    
    if($lastGroupAtALevelFlags.Count -le $level) 
    { 
        $lastGroupAtALevelFlags = $lastGroupAtALevelFlags + 0 
    } 
    if($group -ne $null) 
    { 
        if($showTree) 
        { 
            for($i = 0; $i -lt $level - 1 ; $i++) 
            { 
                if($lastGroupAtALevelFlags[$i] -ne 0) 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "  " 
                } 
                else 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "│ " 
                } 
            } 
            if($level -ne 0) 
            { 
                if($lastGroupOfTheLevel) 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "└─" 
                } 
                else 
                { 
                    Write-Host -ForegroundColor Yellow -NoNewline "├─" 
                } 
            } 
            Write-Host -ForegroundColor Yellow $group.Name -NoNewline
            $new_str=$group.Name.replace("`"","")

            $SID = New-Object System.Security.Principal.SecurityIdentifier ($new_str) -ErrorAction SilentlyContinue
            $username = $SID.Translate([System.Security.Principal.NTAccount]) 
            Write-Host -ForegroundColor Yellow " " $username 
            $foreignUser = $username.Value.split('\')[1]
            $Server = $username.Value.split('\')[0] 
            $foreignGroup = Get-ADGroup -Server $Server -Identity $foreignUser
            #Write-Host $foreignGroup.distinguishedname
            $magic = Get-ADObject -Server $Server -Identity $foreignGroup.DistinguishedName -Properties 'member'
            foreach($tempgroup in $magic.member){
                $newGroup = Get-ADGroup -Server $Server -Identity $tempgroup
                $username = $newGroup.Name
                Write-host $username
                $magic2 = Get-ADObject -Server $Server -Identity $newGroup.DistinguishedName -Properties 'member'
                Write-Host $magic2.member
            }
            #Write-Host $magic.member     
        } 
        $groupsVisitedBeforeThisOne.Add($group.distinguishedName) 
        $global:numberOfRecursiveGroupMemberships ++ 
        $groupMemberShipCount = $group.member.Count 
        if ($groupMemberShipCount -gt 0) 
        { 
            $maxMemberGroupLevel = 0 
            $count = 0 
            foreach($groupDN in $group.member) 
            { 
                $count++ 
                $lastGroupOfThisLevel = $false 
                if($count -eq $groupMemberShipCount){$lastGroupOfThisLevel = $true; $lastGroupAtALevelFlags[$level] = 1} 
                if(!$groupsVisitedBeforeThisOne.Contains($groupDN)) #prevent cyclic dependancies 
                { 
                    $memberGroupLevel = Get-GroupNesting -Identity $groupDN -Level $($level+1) -GroupsVisitedBeforeThisOne $groupsVisitedBeforeThisOne -lastGroupOfTheLevel $lastGroupOfThisLevel 
                    if ($memberGroupLevel -gt $maxMemberGroupLevel){$maxMemberGroupLevel = $memberGroupLevel} 
                } 
            } 
            $level = $maxMemberGroupLevel 
        } 
        else #we've reached the top level group, return it's height 
        { 
            return $level 
        } 
        return $level 
    } 
} 
$global:numberOfRecursiveGroupMemberships = 0 
$groupObj = $null 
$groupObj = Get-ADObject -Identity $groupIdentity
if($groupObj) 
{ 
    [int]$maxNestingLevel = Get-GroupNesting -Identity $groupIdentity -Level 0 -GroupsVisitedBeforeThisOne @{} -lastGroupOfTheLevel $false
    Add-Member -InputObject $groupObj -MemberType NoteProperty  -Name MaxNestingLevel -Value $maxNestingLevel -Force 
    Add-Member -InputObject $groupObj -MemberType NoteProperty  -Name NestedGroupMembershipCount -Value $($global:numberOfRecursiveGroupMemberships - 1) -Force 
    $groupObj 
}
$group


#Usage:

#PS C:\> New-PSDrive -PSProvider ActiveDirectory -Server <dc/domain name> -Root "" –GlobalCatalog –Name GC
#PS C:\> cd GC:
#PS GC:\>

#1Get-ADGroupNesting.ps1 'Domain Admins'
#Get-ADGroupNesting.ps1 'Domain Admins' –ShowTree
#Get-ADPrincipalGroupMembership Install | % {Get-ADGroupNesting $_} | FT Name,GroupCategory,NestedGroupMembershipCount,MaxNestingLevel –A
#Get-ADPrincipalGroupMembership Install | Where {$_.GroupCategory -eq "Security"} | % {Get-ADGroupNesting $_ -ShowTree | FT Name,GroupCategory,NestedGroupMembershipCount,MaxNestingLevel -A}
#(Get-ADUser Install -Properties Member).Member | % {Get-ADGroupNesting.ps1 $_ -ShowTree} | FL DistinguishedName,NestedGroupMembershipCount,MaxNestingLevel