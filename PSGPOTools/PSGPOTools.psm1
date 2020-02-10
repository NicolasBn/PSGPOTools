#Generated at 02/10/2020 15:47:03 by Nicolas BAUDIN
enum StatePolicy {
    Enabled
    Disabled
    NotConfigured
}

enum ScopePolicy {
    User
    Machine
}

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
        #Importer les dÃ©pendances en premier lieu !
        #Pour chaque fichier ADMX on importe le fichier AMDL correspondant
        #On incrÃ©mente les catÃ©gories
        #Comment valider que les dÃ©pendances sont bien dÃ©jÃ  prÃ©sents et pas nÃ©cessaire de les recharger ?
        #noter un Ã©lÃ©ment unique (nom du fichier ?) hashtable ?

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
            #On verifie que le fichier AMDX n'a pas deja ete charge.
            If (![GPOToolsUtility]::TargetLoad.Contains([GPOToolsUtility]::GetNamespaceAdmx($File))){
                Write-Verbose "Initialization of $File"
                #Creation de l'objet ADMX
                $ADMX = [GpoToolsAdmx]::New($File.FullName)

                #On verifie si il a besoin de dÃ©pendance et on les charges
                [GPOToolsUtility]::CheckAndInitiateDependancy($ADMX,$UICulture)

                #On determine le fichier ADML correspondant
                $ADMLPath = [GPOToolsUtility]::GetADMLPathFromADMX($File,$UICulture)

                #On charge le fichier ADML correspondant
                $ADML = [GpoToolsAdml]::New($ADMLPath)

                #On cree les objets SupportedOn
                $Support = $ADMX.SupportedOnDefinition | Foreach-Object { [GPOToolsSupportedOn]::New($_,$ADML) }

                #On initialise les objets Category
                [GPOToolsCategory]::LoadAdmxAdml($Admx,$Adml)

                #On cree les objet Policy
                $Pols = $ADMX.Policies | Foreach-Object {[GPOToolsPolicy]::New($_,$ADML)}

                #On incremente les objets dans les proprietes statiques
                if ($Support.count -gt 0){
                    $Support | Foreach-Object {[GPOToolsutility]::SupportOnTable.Add($_)}
                }
                if ($Pols.count -gt 0){
                    $Pols | Foreach-Object {[GPOToolsutility]::Policies.Add($_)}
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
            #On verifie si la dependance est deja  charge ou si il s'agit de product
            if (![GPOToolsUtility]::TargetLoad.Contains($_.namespace) -and $($ADMX.Target.namespace -ne 'Microsoft.Policies.Products')){
                Write-Verbose ('The ADMX {0} need {1} dependancy' -f $ADMX.FilePath,$_.namespace)
                #on determine de fichier ADMX dont le premier depend
                #Rajouter un trycatch en cas de generation d'erreur et mise en place d'un warning
                Try{
                    $DepFile = [GPOToolsUtility]::FindDependancyFile($ADMX.FilePath,$_.namespace)
                }
                Catch {
                    Write-Warning $_.Exception.message
                    $DepFile = $null
                }
                #On charge la dependance si il y en a une
                if ($null -ne $DepFile){
                    [GPOToolsUtility]::InitiateAdmxAdml($DepFile,$UICulture)
                }
            }
        }
    }
    <#
        Method utilise pour rechercher les fichiers admx dont depend un fichier admx
        Exe. : WindowsBackup.admx a besoin de windows.admx
        Use :
            [GPOToolsUTility]::CheckAndInitiateDependancy()
    #>
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
    <# Methode pour verifier la presence d'une category dans la propriete static de
     la classe GPOToolsUtility. Elle se base sur la propriete target de l'objet
     Category. Target comprend le prefix et le namespace pour avoir un filtre plus
     precis.

     Use :
    #>
    static [bool]CheckCategoryPresence(
        [string]$Name,
        [hashtable]$target
    ){
        $Result = [GPOToolsUtility]::Categories |
            Where-Object {
                ($_.Name -eq $Name) -and
                ($_.target.prefix -eq $target.prefix) -and
                ($_.target.namespace -eq $target.namespace)
            }
        if ($Result.count -eq 0){
            return $false
        }Else{
            return $true
        }
    }

    <# Surcharge de Methode pour verifier la presence d'une category dans la
     propriete static de la classe GPOToolsUtility. Cette surcharge se base seulement
     sur le nom du prefix et pas sur le namespace. Cela rÃ©duit le prÃ©cision de la
     verification.
     Use :
        [GPOToolsCategory]::Create()
    #>
    static [bool]CheckCategoryPresence(
        [string]$Name,
        [string]$TargetPrefix
    ){
        $return = $false
        $Result = [GPOToolsUtility]::Categories |
            Where-Object {
                ($_.Name -eq $Name) -and
                ($_.target.prefix -eq $TargetPrefix)
            }
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

    # Methode pour vider les membre static de GPOToolsUtility. Cela permet d'en
    # initialiser de nouveaux.
    static [void]RemoveAll(){
        foreach($Property in @(
                [GPOToolsUtility]::SupportOnTable,
                [GPOToolsUtility]::Categories,
                [GPOToolsUtility]::Policies,
                [GPOToolsUtility]::TargetLoad
                #[GPOToolsCategory]::AllParentCategory
            )
        ){
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
                    #Si la categorie a le meme nom que celle recherchÃ©
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
        $Result = $Admx.Categories | Foreach-Object {
            [GPOToolsCategory]::Create($_,$Admx.Categories,$Adml)
        }
    }
}

#Classe Policy
class GPOToolsPolicy {
    [string]$Path #Manque la notion d'Administrative Template
    [string]$Name
    [string]$DisplayName
    #[string]$State # Mettre une enumeration? Mettre simplement une methode, l'interrogation de l'ensemble du registre va prendre du temps
    [string]$Description
    [string]$ID
    [GpoToolsRegistry]$Registry
    [ScopePolicy]$Scope
    [string]$FileName
    Hidden [GpoToolscategory]$Category
    Hidden [GPOToolsSupportedOn]$SupportedOn

    GPOToolsPolicy([AdmxPolicy]$Policy,[GpoToolsAdml]$ADMLPol){
        $this.ID = $Policy.Name
        $this.Name = $ADMLPol.StringTable."$($Policy.Name)"
        $this.DisplayName = $ADMLPol.StringTable."$($Policy.DisplayName)"
        $this.Description = $ADMLPol.StringTable."$($Policy.explainText)"
        if ($Policy.Class -eq 'Machine'){
            $this.scope = [ScopePolicy]::Machine
        }Else{
            $this.scope = [ScopePolicy]::User
        }
        $this.FileName = (Split-Path $ADMLPol.FilePath -Leaf) -Replace 'l$','x'
        $this.Category = [GPOToolsPolicy]::FindParentCategory($Policy)
        $this.Path = $this.GeneratePath()

        $this.Registry = [GPOToolsRegistry]::New($Policy)
    }

    [string]GeneratePath(){
        if($this.Category -ne $Null){
            $GNPath = '{0}\{1}' -f $this.Scope,[GPOToolsPolicy]::GeneratePath($this.Category)
        }Else{
            $GNpath = '{0}\' -f $this.Scope
        }
        return $GnPath
    }
    static [string]GeneratePath([GpoToolscategory]$Cat){
        if($Cat.ParentCategory -ne $Null){
            $GNPath = '{0}{1}\' -f [GPOToolsPolicy]::GeneratePath($Cat.ParentCategory),$Cat.DisplayName
        }Else{
            $GNpath = '{0}\' -f $Cat.DisplayName
        }
        return $GNpath
    }

    <#
        Method static pour rechercher une category parent d'une policy
    #>
    static [GPOToolsCategory]FindParentCategory(
        [AdmxPolicy]$Pol
    ){
        # Pour chaque category de Categories
        $ParentCat = [GPOToolsUtility]::Categories |
            Where-Object {
                    #Si la categorie a le meme nom que celle recherchÃ©
                    $_.Name -eq $Pol.ParentCategory.Name -and
                    (# Et que son prefix est similaire a celui de la category parent recherchee
                        $_.target.prefix -eq $Pol.ParentCategory.prefix -or
                        #Ou si la category parent est present dans le meme fichier admx avec
                        #le meme prefix que la policy enfant
                        $_.target.prefix -eq $Pol.target.prefix
                    )
                }
        if ($null -eq $ParentCat.count){
            Throw "[GPOToolsCategory](FindParentCategory) No ParentCategory found for $($Pol.Name) policy in [GPOToolsUtility]::Categories static property"
        }ElseIf($ParentCat.count -ge 2){
            Throw "[GPOToolsCategory](FindParentCategory) To many ParentCategory found for $($Pol.Name) policy"
        }Else{
            return $ParentCat
        }
    }

    [StatePolicy]GetPolicyState(){
        if (-not (Test-path $This.Registry.Path)){
            $State = [StatePolicy]::NotConfigured
        }Else{
            $RegProperty = Get-ItemProperty $This.Registry.Path  -name $This.Registry.Key -ErrorAction SilentlyContinue
            if($RegProperty -eq $null){
                $State = [StatePolicy]::NotConfigured
            }Elseif($RegProperty.{$This.Registry.Key} -eq $this.Registry.Value.Enable){
                $State = [StatePolicy]::Enabled
            }Elseif($RegProperty.{$This.Registry.Key} -eq $this.Registry.Value.Disable){
                $State = [StatePolicy]::Disabled
            }Else{
                throw ('[GPOToolsPolicy](GetPolicyState) State not determinate for {0} policy' -f $this.DisplayName)
            }
        }

        return $State
    }
}

class GPOToolsRegistry {
    $Path
    $Key
    $Value
    $DefaultValue

    GPOToolsRegistry([AdmxPolicy]$Pol) {
        if ($Pol.Class -eq 'Machine'){
            $this.Path = 'HKLM:\{0}' -f $Pol.RegKey
        }Else{
            $this.Path = 'HKCU:\{0}' -f $Pol.RegKey
        }
        $this.Key = $Pol.ValueName
        $this.Value = @{
            Enable = $Pol.enableValue
            Disable = $pol.disableValue
        }
    }
}

#Classe de recuperation des informations contenues dans les fichiers amdx
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
                $this.Policies.Add($([AdmxPolicy]::New($_,$trgt)))
            }
        }
    }
}
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
    $elements

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
        #$this.elements = $policy.elements


    }
}

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


#Classe de recuperation des informations contenues dans les fichiers admx
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
function Initialize-PSGPOAdmx {
    [cmdletbinding()]
    Param(
        [ValidateScript( { Test-Path -Path $_ })]
        [String]$Path = "$Env:windir\PolicyDefinitions\",

        [cultureinfo]$UICulture = [cultureinfo]::CurrentUICulture
    )

    ### VAR ###
    ### MAIN ###
    # Empty Statics properties
    [GPOToolsUtility]::RemoveAll()
    [GpotoolsUtility]::InitiateAdmxAdml($ADMXFolder,$Culture)
}
