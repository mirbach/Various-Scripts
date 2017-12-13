<# 
Disclaimer
This module and it's scripts are not supported under any Microsoft standard support program or service.
The scripts are provided AS IS without warranty of any kind.
Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability
or of fitness for a particular purpose.
The entire risk arising out of the use or performance of the scripts and documentation remains with you.
In no event shall Microsoft, its authors, or anyone else involved in the creation, production,
or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages
for loss of business profits, business interruption, loss of business information, or other pecuniary loss)
arising out of the use of or inability to use the sample scripts or documentation,
even if Microsoft has been advised of the possibility of such damages.
 
SYNOPSIS:
This script is intended to recursively enumerate AD Group memberships.
The Scipt reads a file with input groups and detects all nested users and groups.
The detailed output will go into a *.csv file. A nesting tree will go into a *.txt file.

AUTHOR:

Andreas Mirbach (MSFT), Heinrich Peters(MSFT)
#>

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
    $domain = $GroupName -Split "," | Where-Object {$_ -like "DC=*"}
    $domain = $domain -join "." -replace ("DC=", "")
    $domain = $domain -join "." -replace ("}", "")
   
    $groups = Get-ADGroupMember -Server $domain -Identity $GroupName
    $level++
    $groups | ForEach-Object {
        $global:ID++
        if ($_.ObjectClass -eq 'user') {          
            $result = [pscustomobject]@{
                ID                = $global:ID
                ParentID          = $ParentID
                Name              = $_.Name
                DisplayName       = (Get-ADUser $_  -Properties DisplayName).Displayname
                SamAccountName    = $_.SamAccountName
                DistinguishedName = $_.DistinguishedName
                FromGroup         = $GroupName
                objectClass       = $_.objectClass
                Level             = [int]$level
            }
        }
        elseif ($_.objectClass -eq 'group') {         
            $result = [pscustomobject]@{
                ID                = $global:ID
                ParentID          = $ParentID
                Name              = $_.Name
                DisplayName       = (Get-ADGroup $_  -Properties DisplayName).Displayname
                SamAccountName    = $_.SamAccountName
                DistinguishedName = $_.DistinguishedName
                FromGroup         = $GroupName
                objectClass       = $_.objectClass
                Level             = [int]$level
            }
            Get-NestedGroups -Server $domain -Groupname $_.DistinguishedName -ParentID $ID       
        }  
        $result
    }
}

function buildTree {
    param (
        [array]$objList,
        [string]$prefix = ''
    )
    $objCount = $objList.count
    for ($i = 0; $i -lt $objCount; $i++) {
        $obj = $objList[$i]
        $isLastOnLevel = (($i + 1) -eq $objCount)
        $ChildObjects = ($list | Where-Object {$_.ParentID -eq $obj.id})
        if ($isLastOnLevel) {
            $char = '└'
            $nextPrefix = $prefix + ' '
        }
        else {
            $char = '├'
            $nextPrefix = $prefix + '|'
        }
        Write-Output ("{0}{1}{2}" -f @($prefix, $char, $obj.Name)) 
        if ((([array]($ChildObjects)).count) -gt 0) {
            buildTree -level ($level + 1) -objList ($ChildObjects) -prefix $nextPrefix 
        }
    }
}

$GroupNames = Get-Content -Path $GroupImport | Sort-Object
foreach ($group in $GroupNames) {
    $DetailedExport = ($env:USERPROFILE + '\Documents\' + $group + '_Groups.csv')
    $ExportTree = ($env:USERPROFILE + '\Documents\' + $group + '_GroupTree.txt')

    $DNs = Get-ADGroup -Identity $group | Sort-Object
    $DNs = $DNs -join "." -replace ("@{distinguishedName=", "")
    $DNs = $DNs -join "." -replace ("}", "")
    
    Get-NestedGroups -GroupName $DNs -outfile $group | Export-Csv -Path $DetailedExport -NoTypeInformation
       
    $list = Import-Csv -Path $DetailedExport
    buildTree -objList ($list | Where-Object {$_.ParentID -eq 0}) | Out-File -FilePath $ExportTree
}

$global:id = $null
$global:ParentID = $null