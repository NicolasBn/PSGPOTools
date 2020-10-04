
$AdmxURI = 'https://download.microsoft.com/download/9/2/0/9200837E-1415-40C0-BE02-BDE308606DC5/Administrative%20Templates%20(.admx)%20for%20Windows%2010%20May%202019%20Update%20v3.msi'
$Target = 'output\AdmxW10_1903.msi'

(new-object System.Net.WebClient).DownloadFile($AdmxUri,$Target)

$MSIPath = (Get-Item -Path $Target).FullName
$ExtractPath  = '{0}\Admx' -f $(Split-Path $MSIPath)

msiexec /a $MSIPath /qb TARGETDIR=$ExtractPath
