$GroupImport = ($env:USERPROFILE + '\Documents\Groups.txt')

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
            #$DisplayName = Get-ADUser -Identity $PSItem | Select-Object DisplayName
            $result = [pscustomobject]@{
            ID = $global:ID
            ParentID = $ParentID
            Name = $_.Name
            DisplayName = (Get-ADUser $_  -Properties DisplayName).Displayname
            SamAccountName = $_.SamAccountName
            DistinguishedName = $_.DistinguishedName
            FromGroup = $GroupName
            objectClass = $_.objectClass
            Level = [int]$level
            }
        }
        elseif($_.objectClass -eq 'group') 
        {         
            #$ID++
            $result = [pscustomobject]@{
            ID = $global:ID
            ParentID = $ParentID
            Name = $_.Name
            DisplayName = (Get-ADGroup $_  -Properties DisplayName).Displayname
            SamAccountName = $_.SamAccountName
            DistinguishedName = $_.DistinguishedName
            FromGroup = $GroupName
            objectClass = $_.objectClass
            Level = [int]$level
            }
            Get-NestedGroups -Server $domain -Groupname $_.DistinguishedName -ParentID $ID       
        }  
        $result
    }
}

function buildTree {
param (
    [array]$objList,
    [string]$prefix=''
)
    $objCount = $objList.count
    for ($i = 0; $i -lt $objCount; $i++) {
        $obj = $objList[$i]
        $isLastOnLevel = (($i + 1) -eq $objCount)
        $ChildObjects = ($list | where {$_.ParentID -eq $obj.id})
        if ($isLastOnLevel) {
            $char = '└'
            $nextPrefix = $prefix + ' '
        } else {
            $char = '├'
            $nextPrefix = $prefix + '|'
        }
        Write-Output ("{0}{1}{2}" -f @($prefix,$char,$obj.Name)) 
        if ((([array]($ChildObjects)).count) -gt 0) {
            buildTree -level ($level + 1) -objList ($ChildObjects) -prefix $nextPrefix 
        }
    }
}

$GroupNames = Get-Content -Path $GroupImport | Sort-Object
foreach($group in $GroupNames)
{
    $DetailedExport = ($env:USERPROFILE + '\Documents\' + $group + '_Groups.csv')
    $ExportTree = ($env:USERPROFILE + '\Documents\' + $group + '_GroupTree.txt')

    $DNs = Get-ADGroup -Identity $group | Sort-Object
    $DNs = $DNs -join "." -replace ("@{distinguishedName=", "")
    $DNs = $DNs -join "." -replace ("}", "")
    
    Get-NestedGroups -GroupName $DNs -outfile $group | Export-Csv -Path $DetailedExport -NoTypeInformation
       
    $list = Import-Csv -Path $DetailedExport
    buildTree -objList ($list | where {$_.ParentID -eq 0}) | Out-File -FilePath $ExportTree
}

$global:id = $null
$global:ParentID = $null