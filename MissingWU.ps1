$Ergebnis=@()

$UpdateSession = New-Object -comobject Microsoft.Update.Session
$UpdateServiceManager = New-Object -comobject Microsoft.Update.ServiceManager

Try
{$UpdateService = $UpdateServiceManager.AddScanPackageService("Offline Sync Service", "$scriptPath\wsusscn2.cab")}
Catch
{
    Write-Log "Fehler: AddScanPackageService - wsusscn2.cab nicht gefunden"
    Write-Log $Error[0].exception.message
    Get-Log | Stop-Log #End Log
    Exit -1
}

Try
{$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()}
Catch
{
    Write-Log "Fehler: CreateUpdateSearcher"
    Write-Log $Error[0].exception.message
    Get-Log | Stop-Log #End Log
    Exit -1
}

Try
{$UpdateSearcher.ServerSelection = 3}
Catch
{
    Write-Log "Fehler: Setzen der ServerSelection"
    Write-Log $Error[0].exception.message
    Get-Log | Stop-Log #Logging beenden
    Exit -1
}

Try
{$UpdateSearcher.ServiceID = $UpdateService.ServiceID}
Catch
{
    Write-Log "Fehler: Setzen der ServiceID"
    Write-Log $Error[0].exception.message
    Get-Log | Stop-Log #Logging beenden
    Exit -1
}

Try
{$SearchResult = $UpdateSearcher.Search("IsInstalled=0")}
Catch
{
    Write-Log "Fehler: UpdateSearcher.Search IsInstalled=0"
    Write-Log $Error[0].exception.message
    Get-Log | Stop-Log #Logging beenden
    Exit -1
}

$Updates = $SearchResult.Updates
If ($Updates.Count -le 0) 
{
    Write-Host "No missing Updates ..."
    $Erg = New-Object psobject
    $Erg | Add-Member -MemberType NoteProperty -Name Computername -Value $ComputerLocal
    $Erg | Add-Member -MemberType NoteProperty -Name StartDate -Value (Get-Date).ToString('yyyy-MM-dd-HH-mm-ss')
    $Erg | Add-Member -MemberType NoteProperty -Name Update -Value "No missing Updates ..."
    $Ergebnis+=$Erg#Ermittelter Eintrag wird dem Ergebnis hinzugefuegt
    $LogResult = $LogDirectory+$env:COMPUTERNAME+"-"+$Startzeitpunkt+"-No missing Updates-"+($MyInvocation.MyCommand.name).Replace(".ps1",".log")
}
else
{
    
    foreach ($Update in $Updates)
    {        
        $Erg = New-Object psobject
        $Erg | Add-Member -MemberType NoteProperty -Name Computername -Value $ComputerLocal
        $Erg | Add-Member -MemberType NoteProperty -Name StartDate -Value (Get-Date).ToString('yyyy-MM-dd-HH-mm-ss')
        Write-Host $Update.Title
        $Erg | Add-Member -MemberType NoteProperty -Name Missing-Update -Value $Update.Title
        $Ergebnis+=$Erg#Ermittelter Eintrag wird dem Ergebnis hinzugefuegt
    }
}