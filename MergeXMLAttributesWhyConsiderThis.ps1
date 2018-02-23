$Content = $Null
$CFCcontent = $Null
$Names = $Null
$Name = $Null
$OldValue = $Null

[xml]$Content = Get-Content -Path C:\Users\anmirb\OneDrive\Desktop\IPDev\ADSec.Survey.Content.ippkg\MasterConfig.xml
[xml]$CFCcontent = Get-Content -Path C:\Users\anmirb\OneDrive\Desktop\IPDev\NewCFC\ADSec.Survey.Content.CFC.ippkg\MasterConfig.xml

$Names = $CFCcontent.IPConfiguration.ContentDefinitions.ContentDefinition
foreach($Name in $Names)
{
    $OldValue = Select-Xml -xml $Content -XPath "/IPConfiguration/ContentDefinitions/ContentDefinition[@Name = '$($Name.Name)']"  
    
    if ($OldValue)
    {
        $FinalTag = $OldValue.Node.Attributes['DescriptionFormat'].'#text'
        $Name.Attributes['WhyConsiderThis'].InnerText = $FinalTag 
    }  
}
$CFCcontent.Save('C:\Users\anmirb\OneDrive\Desktop\IPDev\NewCFC\ADSec.Survey.Content.CFC.ippkg\NewMasterConfig.xml')