

Param(
    [ValidateScript( { Test-Path -Path $_ })]
    [String]$Path = "$Env:windir\PolicyDefinitions\",

    [cultureinfo]$UICulture = [cultureinfo]::CurrentUICulture
)


$Pattern = '\$\(string\.(.*)\)', '$1'
