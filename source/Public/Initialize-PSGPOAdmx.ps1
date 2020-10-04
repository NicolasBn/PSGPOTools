function Initialize-PSGPOAdmx {
    [cmdletbinding()]
    Param(
        [ValidateScript( { Test-Path -Path $_ })]
        [String]$Path = "$Env:windir\PolicyDefinitions\",

        [cultureinfo]$UICulture = [cultureinfo]::CurrentUICulture
    )

    ### VAR ###
    $Item = Get-Item -Path $Path
    ### MAIN ###
    # Empty Statics properties
    [GPOToolsUtility]::RemoveAll()
    [GpotoolsUtility]::InitiateAdmxAdml($Item,$UICulture)
}