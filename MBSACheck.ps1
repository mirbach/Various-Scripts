Set-Location "C:\Program Files\Microsoft Baseline Security Analyzer 2\"
cmd.exe /c mbsacli.exe /catalog .\wsusscn2.cab /nvc /nd /n os+iis+sql+password /listfile .\computernames.txt

Set-Location "C:\Users\anmirb\SecurityScans"
$MBSAScan = Get-Content ".\EUROPE - ANMIRBPRIME (2-28-2017 2-15 PM).mbsa"
$xml= [xml]$MBSAScan

$xml = $xml.SecScan.Check | Select-Object Name,Advice,Detail
$result = $xml.Detail.UpdateData | ? { $_.IsInstalled -eq "false"} | Select-Object BulletinID,Title
$result