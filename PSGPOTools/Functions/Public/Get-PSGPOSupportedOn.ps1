function Get-PSGPOSupportedOn {
    [cmdletbinding()]
    Param()

    ### VAR ###
    ### MAIN ###
    $Support =  [GpoToolsUtility]::SupportOnTable
    If ($null -eq $Support){
        Write-Warning "Initiate ADMX and ADML files with Initialize-PSGPOAdmx cmdlet."
    }Else{
        return $Support
    }
}