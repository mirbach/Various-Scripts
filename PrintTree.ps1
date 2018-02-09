# .SYNOPSIS

#     Print a tree given a key property and parent property
#
# .PARAMETER InputObject
#
#     The object to print.
#
# .PARAMETER KeyProperty
#
#     The property name that is unique in each value in InputObject
#
# .PARAMETER ParentProperty
#
#     The property name of the value that refers to the parent
#
# .PaRAMETER Formatter
#
#     An option script block to format the output.
#
# .EXAMPLE
#
#     Get-CimInstance Win32_Process |
#         print_tree.ps1 -KeyProperty ProcessId -ParentProperty ParentProcessId -Formatter { param($o) "{0} ({1})" -f $o.Name, $o.ProcessId }
#
namespace System.Collections.Generic

param(
    [Parameter(ValueFromPipeline)]
    [object[]]$InputObject,

    [Parameter(Mandatory)]
    [string] $KeyProperty,

    [Parameter(Mandatory)]
    [string] $ParentProperty,

    [Parameter()]
    [scriptblock] $Formatter
)

begin
{
    class Node
    {
        $Key
        [List[Node]]$Children = [List[Node]]::new()
        $Value
    }


    $root = [List[Node]]::new()
    $nodeLookup = @{}
}

process
{
    foreach ($obj in $InputObject)
    {
        $node = [Node]@{Key = $obj.$KeyProperty; Value = $obj}
        if ($nodeLookup[$node.Key])
        {
            Write-Warning "Ignoring duplicate: $obj"
        }
        else
        {
            $nodeLookup[$node.Key] =  $node
        }

        $parentPropertyValue = $obj.$ParentProperty
        $parent = if ($parentPropertyValue) { $nodeLookup[$parentPropertyValue] } else { $null }
        if (!$parent)
        {
            $root.Add($node)
        }
        else
        {
            $parent.Children.Add($node)
        }
    }
}

end
{
    function print_node([Node]$node, [string]$indent)
    {
        $formatted = if ($Formatter) {
            & $Formatter $node.Value
        } else {
            ($node.Value | Format-Wide | Out-String).Trim()
        }

        "{0}{1}" -f $indent, $formatted
        $indent += "| "
        foreach ($n in $node.Children)
        {
            print_node $n $indent
        }
    }

    foreach ($n in $root)
    {
        print_node $n ""
    }
}