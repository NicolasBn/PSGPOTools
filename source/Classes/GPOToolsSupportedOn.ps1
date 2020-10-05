#Classe SupportedOn
class GPOToolsSupportedOn {
    [string]$Name
    [string]$DisplayName

    GPOToolsSupportedOn(
        [AdmxSupportedOn]$Support,
        [GpoToolsAdml]$Adml
    ){
        $this.Name = $Support.Name
        $this.DisplayName = $Adml.StringTable."$($Support.DisplayName)"
    }

    static [Array]LoadAdmxAdml(
        [GpoToolsAdmx]$Admx,
        [GpoToolsAdml]$Adml
    ){
        $Result = $Admx.SupportedOnDefinition | Foreach-Object {
            [GPOToolsSupportedOn]::New($_,$Adml)
        }
        return $Result
    }
}
<#
class GPOToolsSupportedOnDefinition : GPOToolsSupportedOn {
    [system.collections.ArrayList]$Or
    [system.collections.Arraylist]$And
}
class GPOToolsSupportedOnProduct : GPOToolsSupportedOn {
    $MajorVersion
}
#>
