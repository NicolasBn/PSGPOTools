function Get-PSGPOPolicy {
    [cmdletbinding()]
    Param()

    ### VAR ###
    ### MAIN ###
    $Policies =  [GpoToolsUtility]::Policies
    If ($null -eq $Policies){
        Write-Warning "Initiate ADMX and ADML files with Initialize-PSGPOAdmx cmdlet."
    }Else{
        return $Policies
    }
}