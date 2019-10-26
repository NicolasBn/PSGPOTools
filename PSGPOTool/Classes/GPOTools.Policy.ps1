
class GpoToolsPolicy {
    [string]$Path
    [string]$Name
    [string]$FullName
    [string]$State
    [string]$ID
    [GpoToolsPolicyOptions]$Options
    [ScopePolicy]$Scope
    [GpoToolsRegistry]$Registry
    Hidden [GpoToolscategory]$Category

    static [Hashtable]$SupportOnTable = @{}
    static [System.Collections.ArrayList]$Categories = @()
    #static [String[]]$DependenciesLoad

    GpoToolsPolicy(
            [System.Collections.Generic.List[GpoToolsAdmx]]$Admxs,
            [System.Collections.Generic.List[GpoToolsAdml]]$Admls
        ){
        $Admxs | Where-Object {$null -ne $_.SupportedOnDefinition} | ForEach-Object {
            [GpoToolsPolicy]::GenerateSupportOnTable($_,$Admls)
        }

        $Admxs | Where-Object {$null -ne $_.Categories} | ForEach-Object {
            [GpoToolsPolicy]::GenerateCategories($_,$Admls)
        }

    }

    GpoToolsPolicy([GpoToolsAdmx]$Admx,[GpoToolsAdml]$Adml){

    }

    static [void]GenerateCategories ([GpoToolsAdmx]$Admxs,[System.Collections.Generic.List[GpoToolsAdml]]$Admls){

    }

    static [void]GenerateSupportOnTable ([GpoToolsAdmx]$Admxs,[System.Collections.Generic.List[GpoToolsAdml]]$Admls){
        $Adl = $Admls | Where-Object {$_.BaseName -eq $_.BaseName}
        $Admxs.SupportedOnDefinition | Foreach-Object {
            $DisplayName = $Adl.StringTable."$($_.DisplayNameVar)"

            if([GpoToolsPolicy]::SupportOnTable.ContainsKey($_.Name)){
                Write-Error -Message ("The key {0} is present in SupportOnTable static property" -f $_.Name)
            }Else{
                [GpoToolsPolicy]::SupportOnTable.Add($_.Name,$DisplayName)
            }
        }
    }
}

class GpoToolscategory {
    [string]$Name
    [string]$DisplayName
    [GpoToolscategory]$ParentCategory

    #Générer le path dans les classe du dessus
    GeneratePath() {

    }
}

class GpoToolsPolicyOptions {
    $Name
    $Value
    $Type
    [GpoToolsRegistry]$Registry

}

class GPOToolsRegistry {
    $Path
    $Key
    $Value
    $DefaultValue
}