#Classe Category

class GPOToolsCategory {
    [string]$Name
    [string]$DisplayName
    [string]$ExplainText
    Hidden [Admxnamespace]$target
    [GPOToolsCategory]$ParentCategory
    # A retirer pour ne laisser qu'une liste de categories
    #static hidden [System.Collections.Generic.List[GpoToolsCategory]]$AllParentCategory = @()

    <#
        Constructeur de la classe GPOToolsCategory.
        Seulement utilise dans la methode Create() pour limiter les creations en double d'objet category
    #>
    Hidden GPOToolsCategory(
        [AdmxCategory]$Cat,
        [System.Collections.ArrayList]$AllCat,
        [GpoToolsAdml]$Adml
    ){
        $this.Name = $Cat.Name
        $this.target = $Cat.target
        $this.DisplayName = $Adml.StringTable."$($Cat.DisplayName)"
        if ($null -ne $Cat.explainText){
            $this.ExplainText = $Adml.StringTable."$($Cat.ExplainText)"
        }

        #Gestion du Parent
        if ($Cat.ParentCategory -ne $null){
            # Si la categorie a un parent dans l'admx on le cherche et on l'ajoute
            $this.ParentCategory = [GPOToolsCategory]::FindParentCategory($Cat,$AllCat,$Adml)
            Write-Verbose ("[GPOToolsCategory] {0} Category have a parent : {1}" -f $Cat.Name,$Cat.ParentCategory.Name)

        }Else{
            # la categorie n'a pas de parent
            Write-Verbose "[GPOToolsCategory] $($Cat.Name) Category doesn't have parent"
        }
    }

    static [System.Collections.Generic.List[GpoToolsCategory]]Create(
        [AdmxCategory]$Category,
        [System.Collections.ArrayList]$AllCat,
        [GpoToolsAdml]$Adml
    ){
        # Si la category est presente dans la classe utility on rappel l'objet
        if (![GPOToolsUtility]::CheckCategoryPresence($Category.Name,$Category.target) ){
            Write-Verbose "[GPOToolsCategory]Loading of $($Category.Name) Category"
            $NewCat = [GpoToolsCategory]::New($Category,$AllCat,$Adml)

            # On ajoute la category au membre statique de la classe GPOToolsUtility
            [GPOToolsUtility]::Categories.Add($NewCat)
            return $NewCat
        }Else{
            Write-Verbose "[GPOToolsCategory] $($Category.Name) Category is already load in [GPOToolsUtility]::Categories"
            return [GPOToolsUtility]::Categories | Where-Object {$_.Name -eq $Category.Name}
        }
    }
    <#
        Methode static utilisee pour trouver la category parent d'une category.
        Elle recherche dans la propriete statique Categories de la classe GPOToolsUtility

        Use :
            [GPOToolsCategory]::New()
    #>
    static [GPOToolsCategory]FindParentCategory(
        [AdmxCategory]$Cat,
        [AdmxCategory[]]$Categories,
        [GpoToolsAdml]$Adml
    ){
        # Pour chaque category de Categories
        $ParentCat = [GPOToolsUtility]::Categories |
            Where-Object {
                    #Si la categorie a le meme nom que celle recherche
                    $_.Name -eq $Cat.ParentCategory.Name -and
                    (# Et que son prefix est similaire a celui de la category parent recherchee
                        $_.target.prefix -eq $Cat.ParentCategory.prefix -or
                        #Ou si la category parent est present dans le meme fichier admx avec
                        #le meme prefix que la category enfant
                        $_.target.prefix -eq $Cat.target.prefix
                    )
                }
        if ($null -eq $ParentCat.count){
            Write-Verbose "[GPOToolsCategory](FindParentCategory) No ParentCategory found for $($Cat.Name) Name in [GPOToolsUtility]::Categories static property"
            if($Categories.Name -contains $Cat.ParentCategory.Name){
                $ParentCat = $Categories.Name | Where-Object {$_.Name -eq $Category.ParentCategory.Name}
                if ($ParentCat -eq 1) {
                    return [GPOToolsCategory]::New($ParentCat,$Categories,$Adml)
                }Else{
                    Throw "[GPOToolsCategory](FindParentCategory) To many ParentCategory found for $($Cat.Name) in ADMX file"
                }
            }Else{
                throw ('[GPOToolsCategory](FindParentCategory) No category parent {0} found for {1} category in [GPOToolsUtility]::Categories static property and ADMX file' -f $Cat.ParentCategory.Name,$Cat.Name)
            }
        }ElseIf($ParentCat.count -ge 2){
            Throw "[GPOToolsCategory](FindParentCategory) To many ParentCategory found for $($Cat.Name)"
        }Else{
            return $ParentCat
        }
    }

    static [void]LoadAdmxAdml(
        [GpoToolsAdmx]$Admx,
        [GpoToolsAdml]$Adml
    ){
        $Admx.Categories | Foreach-Object {
            [GPOToolsCategory]::Create($_,$Admx.Categories,$Adml)
        }
    }
}