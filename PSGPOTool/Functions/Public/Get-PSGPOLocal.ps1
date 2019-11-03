function Get-PSGPOLocal {
    [cmdletbinding()]
    Param(
        [ValidateScript( { Test-Path -Path $_ })]
        [String]$Path = "$Env:windir\PolicyDefinitions\",

        [cultureinfo]$UICulture = [cultureinfo]::CurrentUICulture
    )

    ### VAR ###
    $ADMLPath = "$Path\$UICulture"

    $ADMX = [GpoToolsAdmx]::ImportFromFolder($Path)
    $ADML = [GpoToolsAdml]::ImportFromFolder($ADMLPath)

    ### MAIN ###
    $Policy = [GpoToolsPolicy]::ReadAdmxAdmlFiles($ADMX,$ADML)

    return $Policy
}