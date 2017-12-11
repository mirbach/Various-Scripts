function Get-NestedGroups {
param 
(
    [Parameter()]
    [String]$Server,
    [String]$GroupName,
    [String]$outfile,
    [Int]$ParentID
)
    $domain = $GroupName -Split "," | ? {$_ -like "DC=*"}
    $domain = $domain -join "." -replace ("DC=", "")
    $domain = $domain -join "." -replace ("}", "")
    
    $groups = Get-ADGroupMember -Server $domain -Identity $GroupName
    $level++
    $groups | ForEach-Object {
        $global:ID++
        if($_.ObjectClass -eq 'user')
        {          
            #$ID++
            $result = [pscustomobject]@{
            ID = $global:ID
            ParentID = $ParentID
            Anzeigename = $_.SamAccountName
            Name = $_.DistinguishedName
            FromGroup = $GroupName
            objectClass = $_.objectClass
            Level = [int]$level
            }
            #Write-Host -ForegroundColor Yellow $_.ID $_.Name
        }
        elseif($_.objectClass -eq 'group') 
        {         
            #$ID++
            $result = [pscustomobject]@{
            ID = $global:ID
            ParentID = $ParentID
            Anzeigename = $_.SamAccountName
            Name = $_.DistinguishedName
            FromGroup = $GroupName
            objectClass = $_.objectClass
            Level = [int]$level
            }
            Get-NestedGroups -Server $domain -Groupname $_.DistinguishedName -ParentID $ID
            #Write-Host -ForegroundColor Yellow $_.Name             
        }  
        $result
    }
}

$GroupNames = Get-Content -Path ($env:USERPROFILE + '\Documents\Groups.txt')
foreach($group in $Groupnames)
{
    $DNs = Get-ADGroup -Identity $group
    $DNs = $DNs -join "." -replace ("@{distinguishedName=", "")
    $DNs = $DNs -join "." -replace ("}", "")
    Get-NestedGroups -GroupName $DNs -outfile $group | Export-Csv -Path ($env:USERPROFILE + '\Documents\' + $group + '_Groups.csv') -NoTypeInformation
    $final = Import-Csv -Path ($env:USERPROFILE + '\Documents\' + $group + '_Groups.csv')
    foreach ($f in $final){
        if ($f.ParentID -eq 0){
            Write-Host $f
            if ($f.objectClass -eq 'group'){
                $p = $f.ID
            }
            foreach($f2 in $f){
                if ($f2.ParentID -eq $p)
                {
                    write-host "---" + $f
                }            
            }
        }
    }


    $global:id = $null
    $global:ParentID = $null
}

