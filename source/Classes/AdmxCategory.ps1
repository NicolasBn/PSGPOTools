#Classe utilise dans GPOToolsAdmx pour les categories des fichiers admx
class AdmxCategory {
    [string]$Name
    [string]$DisplayName
    [AdmxNamespace]$target
    [string]$explainText
    [hashtable]$ParentCategory

    AdmxCategory ($Category,[AdmxNamespace]$target){
        $this.Name = $Category.Name
        $this.DisplayName = $Category.DisplayName -replace '\$\(string\.(.*)\)', '$1'
        $this.target = $target
        $this.explainText = $Category.explainText -replace '\$\(string\.(.*)\)', '$1'
        if ($Category.parentcategory.ref -ne $null){
            $SplitResult = $Category.parentcategory.ref -split ':'
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
            Write-Verbose ("[AdmxCategory] No parent category found for {0} category" -f $Category.Name)
        }
    }
}
