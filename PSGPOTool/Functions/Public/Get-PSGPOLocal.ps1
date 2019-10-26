
Param(
    [ValidateScript( { Test-Path -Path $_ })]
    [String]$Path = "$Env:windir\PolicyDefinitions\",

    [cultureinfo]$UICulture = [cultureinfo]::CurrentUICulture
)

### VAR ###
$ADMLPath = "$Path\$UICulture"

$ADMXFiles = Get-ChildItem -Path $Path -Filter *.admx
$ADMLFiles = Get-ChildItem -Path $ADMLPath -Filter *.admx

### MAIN ###
