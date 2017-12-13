function Get-Tree {
    param
    (
        $obj
    )

    Write-Host $obj.GetType().FullName
    
    Get-Recursive $obj -name otto
}

function Get-Recursive {
    param
    (
        $obj,
        $name
    )
    $excludedProperties = @(
        'SyncRoot'
        'Length'
        'Count'
        'value__'
        'LongLength'
        'Rank'
        'IsReadOnly'
        'IsFixedSize'
        'IsSynchronized'
        'CimClass'
        'CimInstanceProperties'
    )
    $string = if ($depth -eq 0) { "$($name):$($obj)" } else { "`n$(' ' * $depth)|$('-' * $depth) $($name):$($obj)" }
    Write-Host $string -NoNewline

    $depth++

    if ( $obj.Count -gt 1) {
        $obj.GetEnumerator() | ForEach-Object {
            $_.psobject.properties.getenumerator() | ForEach-Object { 
                if ($_.Name -notin $excludedProperties -and ($_.TypeNameOfValue -notin 'System.DateTime', 'System.TimeSpan', 'System.String')) {
                    Get-Recursive $_.Value -name $_.Name 
                }
            }
        }            
    }

    if ($obj.Psobject.properties) {
        $obj.psobject.properties.getenumerator() | ForEach-Object { 
            if ($_.Name -notin $excludedProperties -and ($_.TypeNameOfValue -notin 'System.DateTime', 'System.TimeSpan', 'System.String')) {
                Get-Recursive $_.Value -name $_.Name 
            }
        }
    }
    $depth--
}

get-Tree (Get-Service | Select-Object -first 1) 
