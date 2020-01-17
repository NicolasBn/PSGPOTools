class GPOToolsUtility {
    static [System.Collections.Generic.List[GpoToolsSupportedOn]]$SupportOnTable = @()
    static [System.Collections.Generic.List[GpoToolsCategory]]$Categories = @()
    static [System.Collections.Generic.List[GpoToolsPolicy]]$Policies = @()
    static [System.Collections.ArrayList]$TargetLoad = @()

    static [void]InitiateAdmxAdml(
        [System.IO.DirectoryInfo]$Folder,
        [cultureinfo]$UICulture
    ){
        #Importer l'ensemble des fichiers admx
        #Importer les dépendances en premier lieu !
        #Pour chaque fichier ADMX on importe le fichier AMDL correspondant
        #On incrémente les catégories
        #Comment valider que les dépendances sont bien déjà présents et pas nécessaire de les recharger ?
        #noter un élément unique (nom du fichier ?) hashtable ?

        #On passe en revu chaque fichier admx
        if (Test-Path -Path $Folder.FullName){
            Write-Verbose "Initialization of ADMX file in $Folder"
            $AdmxFiles = Get-ChildItem -Path $Folder.FullName -File -Filter *.admx
            foreach ($File in $AdmxFiles) {
                [GPOToolsUtility]::InitiateAdmxAdml($File,$UICulture)
            }
        }Else{
            Write-Error "Foler $Folder not found"
        }

    }

    static [void]InitiateAdmxAdml(
        [System.IO.FileInfo]$File,
        [cultureinfo]$UICulture
    ){
        if((Test-Path -Path $File.FullName) -and ($File.Name -Like '*.admx')){
            If (![GPOToolsUtility]::TargetLoad.Contains([GPOToolsUtility]::GetNamespaceAdmx($File))){
                Write-Verbose "Initialization of $File"
                #Création de l'objet ADMX
                $ADMX = [GpoToolsAdmx]::New($File.FullName)

                #On vérifie si il a besoin de dépendance et on les charges
                [GPOToolsUtility]::CheckAndInitiateDependancy($ADMX,$UICulture)

                #On détermine le fichier ADML correspondant
                $ADMLPath = [GPOToolsUtility]::GetADMLPathFromADMX($File,$UICulture)

                #On charge le fichier ADML correspondant
                $ADML = [GpoToolsAdml]::New($ADMLPath)

                #On crée les objets SupportedOn
                $Support = $ADMX.SupportedOnDefinition | Foreach-Object { [GPOToolsSupportedOn]::New($_,$ADML) }

                #On crée les objets Category
                $Cat = [GPOToolsCategory]::LoadAdmxAdml($Admx,$Adml)

                #On crée les objet Policy

                #On incrémente les objets dans les propriétés statiques
                if ($Support.count -gt 0){
                    $Support | Foreach-Object {[GPOToolsutility]::SupportOnTable.Add($_)}
                }
                if ($Cat.count -gt 0){
                    $Cat | ForEach-Object {[GPOToolsutility]::Categories.Add($_)}
                }
                [GPOToolsutility]::TargetLoad.Add($ADMX.Target.namespace)

            }Else{
                Write-Verbose "$File is already Initiate"
            }
        }Else{
            Write-Error "File $File not found"
        }
    }

    static [string]GetNamespaceAdmx(
        [System.IO.FileInfo]$AdmxFile
    ){
        [xml]$Xml = Get-Content -Path $AdmxFile.FullName -Encoding UTF8
        return $Xml.policyDefinitions.policyNamespaces.target.namespace
    }
    static [string]GetADMLPathFromADMX(
        [System.IO.FileInfo]$AdmxFile,
        [cultureinfo]$UICulture
    ){
        $ParentPath = Split-Path -Path $AdmxFile.FullName
        $ADMLPath  = '{0}\{1}\{2}' -f $ParentPath,$UICulture,$($AdmxFile.Name -replace '\.admx','.adml')
        if (Test-Path -Path $ADMLPath){
            return $ADMLPath
        }Else{
            Throw "The ADML File $ADMLPath doesn't exist."
        }
    }

    static [void]CheckAndInitiateDependancy(
        [GpoToolsAdmx]$ADMX,
        [cultureinfo]$UICulture
    ){
        $ADMX.Using | Foreach-Object {
            #On verifie si la dépendance est déjà chargé ou si il s'agit de product
            if (![GPOToolsUtility]::TargetLoad.Contains($_.namespace) -and $($ADMX.Target.namespace -ne 'Microsoft.Policies.Products')){
                Write-Verbose ('The ADMX {0} need {1} dependancy' -f $ADMX.FilePath,$_.namespace)
                #on determine de fichier ADMX dont le premier depend
                #Rajouter un trycatch en cas de génération d'erreur et mise en place d'un warning
                Try{
                    $DepFile = [GPOToolsUtility]::FindDependancyFile($ADMX.FilePath,$_.namespace)
                }
                Catch {
                    Write-Warning $_.Exception.message
                    $DepFile = $null
                }
                #On charge la dépendance si il y en a une
                if ($null -ne $DepFile){
                    [GPOToolsUtility]::InitiateAdmxAdml($DepFile,$UICulture)
                }
            }
        }
    }

    static [System.IO.FileInfo]FindDependancyFile(
        [string]$Path,
        [string]$namespace
    ){
        $FolderPath = Split-Path -Path $Path
        $Files = Get-ChildItem -Path $FolderPath -Filter *.admx -Exclude $Path.Name
        $File = $Files | Foreach-Object {
            if([GPOToolsUtility]::GetNamespaceAdmx($_) -eq $namespace){
                $_
            }
        }
        switch ($File.count){
            1 {
                break
            }
            {$_ -ge 2} {
                Throw ('Too many dependancy file found for {0} target in {1} ADMX file' -f $namespace,$Path)
            }
            0 {
                Throw ('No dependancy file found for {0} target in {1} ADMX file' -f $namespace,$Path)
            }
            default {
                Throw ('Unknwon error for find {0} target in {1} ADMX file' -f $namespace,$Path)
            }
        }

        return $File
    }

    static [bool]CheckCategoryPresence(
        [string]$Name,
        [hashtable]$target
    ){
        $Result = [GPOToolsUtility]::Categories | Where-Object {($_.Name -eq $Name) -and ($_.target.prefix -eq $target.prefix) -and ($_.target.namespace -eq $target.namespace)}
        if ($Result.count -eq 0){
            return $false
        }Else{
            return $true
        }
    }

    static [bool]CheckCategoryPresence(
        [string]$Name,
        [string]$TargetPrefix
    ){
        $return = $false
        $Result = [GPOToolsUtility]::Categories | Where-Object {($_.Name -eq $Name) -and ($_.target.prefix -eq $TargetPrefix)}
        switch ($Result.Count){
            1 {$return = $true}
            0 {$return =  $false}
            {$_ -ge 2} {
                throw ('[GPOToolsUtility](CheckCategoryPresence) To many Category found for {0}.' -f $Name)
            }
            default {
                throw ('[GPOToolsUtility](CheckCategoryPresence) Unknow error for {0} category.' -f $Name)
            }
        }
        return $return
    }

    static [void]RemoveAll(){
        foreach($Property in @([GPOToolsUtility]::SupportOnTable,[GPOToolsUtility]::Categories,[GPOToolsUtility]::Policies,[GPOToolsUtility]::TargetLoad,[GPOToolsCategory]::AllParentCategory) ){
            $Property.Clear()
        }
    }

}# End GPOToolsUtility

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
#Classe Category

#Subtilisé le constructeur par une méthode Create() de manière à ne pas réinstancier deux fois la même catégorie
class GPOToolsCategory {
    [string]$Name
    [string]$DisplayName
    [string]$ExplainText
    Hidden [Admxnamespace]$target
    [GPOToolsCategory]$ParentCategory

    static hidden [System.Collections.Generic.List[GpoToolsCategory]]$AllParentCategory = @()

    GPOToolsCategory(
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
        # Si la category est presente dans la classe utility on recree l'objet
        if (![GPOToolsUtility]::CheckCategoryPresence($Category.Name,$Category.target) ){
            # Si la category est absente de la classe Category on la cree
            if (![GPOToolsCategory]::CheckCategoryPresence($Category.Name,$Category.target)){
                Write-Verbose "[GPOToolsCategory]Loading of $($Category.Name) Category"
                $NewCat = [GpoToolsCategory]::New($Category,$AllCat,$Adml)

                # On ajoute la category au membre statique
                [GPOToolsCategory]::AllParentCategory.Add($NewCat)
                return $NewCat
            }Else{
                Write-Verbose "[GPOToolsCategory] $($Category.Name) Category is already load"
                return [GPOToolsCategory]::AllParentCategory | Where-Object {$_.Name -eq $Category.Name}
            }
        }Else{
            Write-Verbose "[GPOToolsCategory] $($Category.Name) Category is already load in [GPOToolsUtility]::Categories"
            return [GPOToolsUtility]::Categories | Where-Object {$_.Name -eq $Category.Name}
        }
    }

    static [GPOToolsCategory]FindParentCategory(
        [AdmxCategory]$Cat,
        [AdmxCategory[]]$Categories,
        [GpoToolsAdml]$Adml
    ){

        $ParentCat = [GPOToolsCategory]::AllParentCategory | Where-Object {$_.Name -eq $Cat.ParentCategory.Name -and ($_.target.prefix -eq $Cat.ParentCategory.prefix -or $_.target.prefix -eq $Cat.target.prefix)}
        if ($null -eq $ParentCat.count){
            Write-Verbose "[GPOToolsCategory](FindParentCategory) No ParentCategory found for $($Cat.Name) in [GPOToolsCategory]::AllParentCategory static property"
            if($Categories.Name -contains $Cat.ParentCategory.Name){
                $ParentCat = $Categories.Name | Where-Object {$_.Name -eq $Category.ParentCategory.Name}
                if ($ParentCat -eq 1) {
                    return [GPOToolsCategory]::New($ParentCat,$Categories,$Adml)
                }Else{
                    Throw "[GPOToolsCategory](FindParentCategory) To many ParentCategory found for $($Cat.Name) in ADMX file"
                }
            }Else{
                throw ('[GPOToolsCategory](FindParentCategory) No category parent {0} found for {1} category in [GPOToolsCategory]::AllParentCategory static property and ADMX file' -f $Cat.ParentCategory.Name,$Cat.Name)
            }
        }ElseIf($ParentCat.count -ge 2){
            Throw "[GPOToolsCategory](FindParentCategory) To many ParentCategory found for $($Cat.Name)"
        }Else{
            return $ParentCat
        }
    }

    static [bool]CheckCategoryPresence(
        [string]$Name,
        [AdmxNamespace]$target
    ){
        $Result = [GPOToolsCategory]::AllParentCategory | Where-Object {($_.Name -eq $Name) -and ($_.target.prefix -eq $target.prefix) -and ($_.target.namespace -eq $target.namespace)}
        if ($Result.count -eq 0){
            return $false
        }Else{
            return $true
        }
    }
    static [Array]LoadAdmxAdml(
        [GpoToolsAdmx]$Admx,
        [GpoToolsAdml]$Adml
    ){
        $Result = $Admx.Categories | Foreach-Object {
            [GPOToolsCategory]::Create($_,$Admx.Categories,$Adml)
        }
        return $Result
        #[GPOToolsCategory]::AllParentCategory.Clear()
    }
}

#Classe Policy
class GPOToolsPolicy {

}

#Classe de récupération des informations contenues dans les fichiers amdx
class GpoToolsAdmx {
    [string]$FilePath
    [string]$BaseName
    [AdmxNamespace]$Target
    [System.Collections.ArrayList]$Using = @()
    [System.Collections.ArrayList]$SupportedOnDefinition = @()
    [System.Collections.ArrayList]$Categories = @()
    [System.Collections.ArrayList]$Policies = @()

    GpoToolsAdmx([string]$AdmxPath) {
        $File = Get-Item -Path $AdmxPath
        [xml]$Xml = Get-Content -Path $File.FullName -Encoding UTF8

        $PolicyDefinitions = $xml.policyDefinitions
        $trgt = [AdmxNamespace]::New($PolicyDefinitions.policyNamespaces.target)


        $This.FilePath = $File.FullName
        $This.BaseName = $File.BaseName
        $This.Target = $trgt

        if ($null -ne $PolicyDefinitions.policyNamespaces.using){
            $PolicyDefinitions.policyNamespaces.using | Foreach-Object {
                $This.Using.Add([AdmxNamespace]::New($_))
            }
        }

        if ($null -ne $PolicyDefinitions.supportedOn.definitions){
            $PolicyDefinitions.supportedOn.definitions.definition | Foreach-Object {
                $This.SupportedOnDefinition.Add([AdmxSupportedOn]::New($_))
            }
        }

        if ($null -ne $PolicyDefinitions.categories){
            $PolicyDefinitions.categories.Category | Foreach-Object {
                $this.Categories.Add($([AdmxCategory]::New($_,$trgt)))
            }
        }

        if ($null -ne $PolicyDefinitions.Policies){
            $PolicyDefinitions.Policies.policy | Foreach-Object {
                $this.Policies.Add($([AdmxPolicy]::New($_)))
            }
        }
    }
}
#Classe utilisée dans GPOToolsAdmx  pour lire les policy
class AdmxPolicy {
    $Name
    $Class
    $DisplayName
    $explainText
    $RegKey
    $ValueName
    $ParentCategoryName
    $SupportedOn
    $enableValue
    $disableValue
    $elements

    AdmxPolicy ($Policy){
        $this.Name = $policy.Name
        $this.Class = $policy.Class
        $this.DisplayName = $policy.DisplayName -replace '\$\(string\.(.*)\)', '$1'
        $this.explainText = $policy.explainText -replace '\$\(string\.(.*)\)', '$1'
        $this.RegKey = $policy.RegKey
        $this.ValueName = $policy.ValueName
        $this.ParentCategoryName = $policy.ParentCategory.ref
        $this.SupportedOn = $policy.SupportedOn
        $this.enableValue = $policy.enabledValue.decimal.Value
        $this.disableValue = $policy.enabledValue.decimal.Value
        #$this.elements = $policy.elements


    }
}

#Classe utilisé dans GPOToolsAdmx pour les catégories des fichiers admx
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
# Class pour les ressources SupportedOn (Exemple Windows.admx)
class AdmxSupportedOn {
    [string]$Name
    [string]$DisplayName

    AdmxSupportedOn ($SupportedOn) {
        $This.Name = $SupportedOn.Name
        $THis.DisplayName = $SupportedOn.DisplayName -replace '\$\(string\.(.*)\)', '$1'
    }
}

class AdmxNamespace {
    [string]$prefix
    [string]$namespace

    AdmxNamespace($namesp) {
        $this.prefix = $namesp.prefix
        $this.namespace = $namesp.namespace
    }
}

enum ScopePolicy {
    User
    Machine
}
#Classe de récupération des informations contenues dans les fichiers admx
class GpoToolsAdml {
    [string]$FilePath
    [string]$BaseName
    [Hashtable]$StringTable

    #presentationTable

    GpoToolsAdml ([string]$AdmlPath) {
        $File = Get-Item -Path $AdmlPath
        [xml]$Xml = Get-Content -Path $File.FullName -Encoding UTF8

        $This.FilePath = $File.FullName
        $This.BaseName = $File.BaseName
        $this.StringTable = @{}

        $xml.policyDefinitionResources.resources.stringTable.string | Foreach-Object {
            Write-Verbose ('Ajout du champ {0} dans la table StringTable pour le fichier {1}' -f $_.id,$File.BaseName)
            $this.StringTable.Add($_.id,$_.'#Text')
        }
    }
}