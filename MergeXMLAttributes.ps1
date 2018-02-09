$Content = $Null
$CFCcontent = $Null
$Names = $Null
$Name = $Null
$OldTags = $Null

[xml]$Content = Get-Content -Path C:\Users\anmirb\OneDrive\Desktop\IPDev\ADSec.Survey.Content.ippkg\MasterConfig.xml
[xml]$CFCcontent = Get-Content -Path C:\Users\anmirb\OneDrive\Desktop\IPDev\NewCFC\ADSec.Survey.Content.CFC.ippkg\MasterConfig.xml

$Names = $CFCcontent.IPConfiguration.ContentDefinitions.ContentDefinition
foreach($Name in $Names)
{
    $OldTags = Select-Xml -xml $Content -XPath "/IPConfiguration/ContentDefinitions/ContentDefinition[@Name = '$($Name.Name)']"  
    
    if ($OldTags)
    {
        $FinalTag = $Name.Attributes['Tags'].'#text'  += (';' + $OldTags.Node.Attributes['Tags'].'#text')
        $Name.Attributes['Tags'].InnerText = $FinalTag 
    }  
}
$CFCcontent.Save('C:\Users\anmirb\OneDrive\Desktop\IPDev\NewCFC\ADSec.Survey.Content.CFC.ippkg\NewMasterConfig.xml')