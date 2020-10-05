#Classe utilisee dans GPOToolsAdmx  pour lire les policy
class AdmxPolicy {
    $Name
    $Class
    $DisplayName
    $explainText
    $RegKey
    $ValueName
    [hashtable]$ParentCategory
    $SupportedOn
    $enableValue
    $disableValue
    $presentation
    $elements
    #Enabledlist
    #disabledlist

    AdmxPolicy ($Policy,[AdmxNamespace]$target){
        $this.Name = $policy.Name
        $this.Class = $policy.Class
        $this.DisplayName = $policy.DisplayName -replace '\$\(string\.(.*)\)', '$1'
        $this.explainText = $policy.explainText -replace '\$\(string\.(.*)\)', '$1'
        $this.RegKey = $policy.Key
        $this.ValueName = $policy.ValueName
        $this.SupportedOn = $policy.SupportedOn
        $this.enableValue = $policy.enabledValue.decimal.Value
        $this.disableValue = $policy.disabledValue.decimal.Value
        $this.presentation = $policy.presentation -replace '\$\(presentation\.(.*)\)', '$1'
        if ($policy.ParentCategory.ref -ne $null){
            $SplitResult = $policy.ParentCategory.ref -split ':'
            if ($SplitResult.count -eq 1){
                $this.ParentCategory = @{
                    prefix = $target.prefix
                    name = $SplitResult[0]
                }
            }Else{
                $this.ParentCategory = @{
                    prefix = $SplitResult[0]
                    name = $SplitResult[1]
                }
            }
        }Else{
            Write-Verbose ("[AdmxPolicy] No parent category found for {0} policy" -f $policy.Name)
        }
        $this.elements = $policy.elements
    }
}

