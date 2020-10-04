function Get-PSGPOCategory {
    [cmdletbinding()]
    Param()

    ### VAR ###
    ### MAIN ###
    $Categories =  [GpoToolsUtility]::Categories
    If ($null -eq $Categories){
        Write-Warning "Initiate ADMX and ADML files with Initialize-PSGPOAdmx cmdlet."
    }Else{
        return $Categories
    }
}