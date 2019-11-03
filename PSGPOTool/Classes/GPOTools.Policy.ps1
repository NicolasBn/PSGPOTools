
class GpoToolsPolicy {
    [string]$Path
    [string]$Name
    [string]$FullName
    [string]$State
    [string]$ID
    [GpoToolsPolicyOptions]$Options
    [ScopePolicy]$Scope
    [GpoToolsRegistry]$Registry
    Hidden [string]$FilePath
    Hidden [GpoToolscategory]$Category

    static [Hashtable]$SupportOnTable = @{}
    static [System.Collections.ArrayList]$Categories = @()
    #static [String[]]$DependenciesLoad



    GpoToolsPolicy([AdmxPolicy]$Policy,[GpoToolsAdml]$Adml){
        $this.name = $this.GetStringTableContent($Adml,$Policy.Name)
        $this.ID = $Policy.Name
        if ($Policy.Class -eq 'Machine'){
            $this.scope = [ScopePolicy]::Machine
        }Else{
            $this.scope = [ScopePolicy]::User
        }
        $this.FilePath = $Adml.FilePath
    }

    static [GpoToolsPolicy[]]ReadAdmxAdmlFiles(
        [System.Collections.Generic.List[GpoToolsAdmx]]$Admxs,
        [System.Collections.Generic.List[GpoToolsAdml]]$Admls
    ){
    $Admxs | Where-Object {$null -ne $_.SupportedOnDefinition} | ForEach-Object {
        return [GpoToolsPolicy]::GenerateSupportOnTable($_,$Admls)
    }

    $Admxs | Where-Object {$null -ne $_.Categories} | ForEach-Object {
        [GpoToolsPolicy]::GenerateCategories($_,$Admls)
    }

    return $Admxs | Foreach-Object {
        $Admx = $_
        $Adml = $Admls | Where-Object {$_.BaseName -eq $Admx.BaseName}
        $Admx.Policies | Foreach-Object {
            [GpoToolsPolicy]::New($_,$Adml)
        }
    }
}

    static [void]GenerateCategories ([GpoToolsAdmx]$Admxs,[System.Collections.Generic.List[GpoToolsAdml]]$Admls){

    }

    static [void]GenerateSupportOnTable ([GpoToolsAdmx]$Admx,[System.Collections.Generic.List[GpoToolsAdml]]$Admls){
        $Adl = $Admls | Where-Object {$_.BaseName -eq $Admx.BaseName}
        $Admx.SupportedOnDefinition | Foreach-Object {
            $DisplayName = $Adl.StringTable."$($_.DisplayNameVar)"

            if([GpoToolsPolicy]::SupportOnTable.ContainsKey($_.Name)){
                Write-Warning -Message ("The key {0} is already present in SupportOnTable static property" -f $_.Name)
            }Else{
                [GpoToolsPolicy]::SupportOnTable.Add($_.Name,$DisplayName)
            }
        }
    }

    [string]GetStringTableContent ([GpoToolsAdml]$Adml,[string]$VarName) {
            $Traduct = $Adml.StringTable."$VarName"
            return $Traduct
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