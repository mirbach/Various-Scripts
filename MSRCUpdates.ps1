Set-MSRCApiKey -ApiKey  



$id = Get-MsrcCvrfDocument -ID '2017-Nov'
$affsw = Get-MsrcCvrfAffectedSoftware -Vulnerability $id.Vulnerability -ProductTree $id.ProductTree
$affsw
$cvesum = Get-MsrcCvrfCVESummary -Vulnerability $id.Vulnerability -ProductTree $id.ProductTree
$cvesum
$explind = Get-MsrcCvrfExploitabilityIndex -Vulnerability $id.Vulnerability
$explind

Get-MsrcVulnerabilityReportHtml -Vulnerability $id.Vulnerability -ProductTree $id.ProductTree | Out-File -FilePath "C:\temp\$($id.documenttitle).html"
Invoke-Item -Path "c:\temp\$($id.documenttitle).html"