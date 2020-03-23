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
        #Importer les dependances en premier lieu !
        #Pour chaque fichier ADMX on importe le fichier AMDL correspondant
        #On incremente les categories
        #Comment valider que les dependances sont bien deja presents et pas necessaire de les recharger ?
        #noter un element unique (nom du fichier ?) hashtable ?

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

                #On verifie si il a besoin de dependance et on les charges
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
            #On verifie si la dependance est deja charge ou si il s'agit de product
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
     sur le nom du prefix et pas sur le namespace. Cela reduit le precision de la
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

#Classe Policy
class GPOToolsPolicy {
    [string]$Path #Manque la notion d'Administrative Template
    [string]$Name
    [string]$DisplayName
    #[string]$State # Mettre une enumeration? Mettre simplement une methode, l'interrogation de l'ensemble du registre va prendre du temps
    [string]$Description
    [string]$ID
    [System.Collections.ArrayList]$Options = @()
    [System.Collections.Generic.List[GpoToolsRegistry]]$Registry
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

        if ($null -ne $Policy.elements){
            $Pres = $ADMLPol.PresentationTable."$($Policy.presentation)"
            $Pos = 0
            # A completer
            Switch ($Pres) {
                {$_ -is [AdmlPresentationText]} {
                    $This.Options.Add([GPOToolsOptionText]::New($_,$Pos))
                    $Pos++
                    continue
                }
                {$_ -is [AdmlPresentationCheckbox]} {
                    $This.Options.Add([GPOToolsOptionCheckBox]::New(
                        [GPOToolsOption]::GetElementByID($Policy.elements.Boolean,$_.ID),
                        $_,
                        $Pos
                    ))
                    $Pos++
                    continue
                }
                {$_ -is [AdmlPresentationDropdownList]} {
                    # Les items qui se trouvent dans la liste vont chercher leur ecriture dans sctring table
                    $This.Options.Add([GPOToolsOptionDropDownList]::New(
                        [GPOToolsOption]::GetElementByID($Policy.elements.enum,$_.ID),
                        $_,
                        $Pos,
                        $ADMLPol.StringTable
                    ))
                    $Pos++
                    continue
                }
                {$_ -is [AdmlPresentationTextbox]} {
                    $This.Options.Add([GPOToolsOptionTextBox]::New(
                        [GPOToolsOption]::GetElementByID($Policy.elements.Text,$_.ID),
                        $_,
                        $Pos
                    ))
                    $Pos++
                    continue
                }
                {$_ -is [AdmlPresentationDecimalTextbox]} {
                    $This.Options.Add([GPOToolsOptionDecimal]::New(
                        [GPOToolsOption]::GetElementByID($Policy.elements.decimal,$_.ID),
                        $_,
                        $Pos
                    ))
                    $Pos++
                    continue
                }
                {$_ -is [AdmlPresentationMultiTextbox]} {
                    $This.Options.Add([GPOToolsOptionMultiTextBox]::New(
                        [GPOToolsOption]::GetElementByID($Policy.elements.multiText,$_.ID),
                        $_,
                        $Pos
                    ))
                    $Pos++
                    continue
                }
                {$_ -is [AdmlPresentationListbox]} {
                    $This.Options.Add([GPOToolsOptionList]::New(
                        [GPOToolsOption]::GetElementByID($Policy.elements.list,$_.ID),
                        $_,
                        $Pos
                    ))
                    $Pos++
                    continue
                }
            }
        }
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
                    #Si la categorie a le meme nom que celle recherche
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
    [System.Object[]]FormatCustom() {
        return $this | Format-Custom
    }
}

class GPOToolsRegistry {
    [string[]]$Path
    $Key
    $Value #Active/Desactive
    $DefaultValue

    GPOToolsRegistry([AdmxPolicy]$Pol) {
        Switch ($Pol.Class){
            'Machine' {
                $this.Path = 'HKLM:\{0}' -f $Pol.RegKey
                break
            }
            'User' {
                $this.Path = 'HKCU:\{0}' -f $Pol.RegKey
                break
            }
            'Both' {
                $this.Path = 'HKLM:\{0}', 'HKCU:\{0}' | Foreach-Object {$_ -f $Pol.RegKey}
                break
            }
        }
        $this.Key = $Pol.ValueName
        $this.Value = @{
            Enable = $Pol.enableValue
            Disable = $pol.disableValue
        }
    }
}

class GPOToolsOption {
    Hidden [String]$ID
    Hidden [int]$Position
    [string]$Text
    [String]$Key
    [string]$ValueName

    static [System.Xml.XmlElement]GetElementByID(
        $XML,
        [string]$ID
    ){
        return $($XML | Where-Object {$_.ID -eq $ID})
    }
}

class GPOToolsOptionItemList {
    [String]$DisplayName
    [long]$Value

    GPOToolsOptionItemList([System.Xml.XmlElement]$Item,[hashtable]$StrTbl){
        $this.DisplayName = $StrTbl."$($Item.displayName -replace '\$\(string\.(.*)\)', '$1')"
        $this.Value = $Item.value.decimal.value
    }
}

class GPOToolsOptionText {
    [String]$Text
    Hidden [Int]$Position

    GPOToolsOptionText ([AdmlPresentationText]$PresTest,[int]$Pos) {
        $this.Text = $PresTest.Text
        $this.Position = $Pos
    }

    [string[]]FormatOptionsControl(){
        return $this.Text
    }
}

class GPOToolsOptionCheckBox:GPOToolsOption {
    $FalseValue
    $TrueValue
    [boolean]$DefaultCheck

    GPOToolsOptionCheckBox (
        [System.Xml.XmlElement]$Element,
        [AdmlPresentationCheckbox]$PresCheckbox,
        [int]$Pos
    ){

        $this.ID = $PresCheckbox.ID
        $this.Position = $Pos
        $this.Text = $PresCheckbox.Text
        $this.ValueName = $Element.ValueName

        #Optional
        $this.Key = $Element.Key
        if ($Element.HasAttribute('FalseValue')){$this.FalseValue = $Element.FalseValue}
        if ($Element.HasAttribute('TrueValue')){$this.TrueValue = $Element.TrueValue}
        if ($Element.HasAttribute('DefaultCheck')){$this.DefaultCheck = $Element.DefaultCheck}
    }

    [string[]]FormatOptionsControl(){
        $Format = "[CHECKBOX] {0} [ ]" -f $this.Text
        return $Format
    }
}

class GPOToolsOptionDropDownList:GPOToolsOption {
    [boolean]$Required
    $ClientExtension # ???
    [boolean]$Sort
    $DefaultItem
    [System.Collections.Generic.List[GPOToolsOptionItemList]]$Items

    GPOToolsOptionDropDownList(
        [System.Xml.XmlElement]$Element,
        [AdmlPresentationDropdownList]$PresDropDownList,
        [int]$Pos,
        [hashtable]$StringTable
    ){

        $this.ID = $PresDropDownList.ID
        $this.Position = $Pos
        $this.Text = $PresDropDownList.Text
        $this.ValueName = $Element.ValueName

        $this.Items = $Element.Item | Foreach-Object{
            [GPOToolsOptionItemList]::New($_,$StringTable)
        }

        #Optional
        $this.Key = $Element.Key
        if ($Element.HasAttribute('Required')){$this.Required = $Element.Required}
        $this.ClientExtension = $Element.ClientExtension
        if($PresDropDownList.DefaultItem){
            $this.DefaultItem = $this.Items | Where-Object {$_.Value -eq $PresDropDownList.DefaultItem}
        }
        $this.Sort = $PresDropDownList.Sort
    }

    [string[]]FormatOptionsControl(){
        $Format = "[DROPDOWNLIST] {0} [" -f $this.Text
        $this.Items | ForEach-Object -Process {
            $Format = $Format + $(
                if($_.Value -eq $this.DefaultItem.Value){
                    '{1}     [{2}] {0} [DefaultValue]'
                }Else{
                    '{1}     [{2}] {0}'
                }
            ) -f $_.DisplayName,[System.Environment]::NewLine,$_.Value
        } -End {
            $Format = $Format + [System.Environment]::NewLine + "]"
        }
        return $Format
    }
}

class GPOToolsOptionTextBox:GPOToolsOption {
    [boolean]$Required
    $Expandable # Need to determine the type of data
    [int]$MaxLength
    [string]$DefaultValue

    GPOToolsOptionTextBox(
        [System.Xml.XmlElement]$Element,
        [AdmlPresentationTextbox]$PresTextBox,
        [int]$Pos
    ){

        $this.ID = $PresTextBox.ID
        $this.Position = $Pos
        $this.Text = $PresTextBox.Text
        $this.ValueName = $Element.ValueName

        #Optional
        $this.Key = $Element.Key
        if ($Element.HasAttribute('Required')){$this.Required = $Element.Required}
        if ($Element.HasAttribute('maxLength')) {$this.maxLength = $Element.maxLength}
        $this.expandable = $Element.expandable
        if ($PresTextBox.DefaultValue){$this.DefaultValue = $PresTextBox.DefaultValue}
    }

    [string[]]FormatOptionsControl(){
        $Format = "[TEXTBOX] {0} [ ]" -f $this.Text
        if ($this.DefaultValue) {$Format = $Format + "{4}     DefaultValue [{1}]"}
        if ($this.Required) {$Format = $Format + "{4}     Required [{2}]"}
        if ($this.maxLength) {$Format = $Format + "{4}     maxLength [{3}]"}
        $Format = $Format -f $this.Text,$this.DefaultValue,$this.Required,$this.maxLength,[System.Environment]::NewLine
        return $Format
    }
}

class GPOToolsOptionDecimal:GPOToolsOption {
    [boolean]$Required
    $MinValue
    $MaxValue
    [boolean]$StoreAsText # Need to verify the type of data and to see in the registry
    $ClientExtension # ???
    $DefaultValue

    GPOToolsOptionDecimal (
        [System.Xml.XmlElement]$Element,
        [AdmlPresentationDecimalTextbox]$PresDecimal,
        [int]$Pos
    ){

        $this.ID = $PresDecimal.ID
        $this.Position = $Pos
        $this.Text = $PresDecimal.Text
        $this.ValueName = $Element.ValueName

        #Optional
        $this.Key = $Element.Key
        $this.Required = $Element.Required
        if ($Element.HasAttribute('minValue')){
            $this.MinValue = $Element.minValue
        }
        if ($Element.HasAttribute('maxValue')){
            $this.MaxValue = $Element.maxValue
        }
        $this.StoreAsText = $Element.StoreAsText
        $this.ClientExtension = $Element.ClientExtension
        $this.DefaultValue = $PresDecimal.DefaultValue
    }

    [string[]]FormatOptionsControl(){
        $Format = "[DECIMAL] {0} [ ]"
        if ($this.DefaultValue) {$Format = $Format + "{4}     DefaultValue [{1}]"}
        if ($this.MinValue) {$Format = $Format + "{4}     MinimumValue [{2}]"}
        if ($this.MaxValue) {$Format = $Format + "{4}     MaximumValue [{3}]"}
        $Format = $Format -f $($this.Text -Replace '\n\s*$'),$this.DefaultValue,$this.MinValue,$this.MaxValue,[System.Environment]::NewLine
        return $Format
    }
}

class GPOToolsOptionMultiTextBox:GPOToolsOption {
    [boolean]$Required
    [int]$MaxLength
    [int]$MaxStrings
    #[String]$DefaultValue

    GPOToolsOptionMultiTextBox (
        [System.Xml.XmlElement]$Element,
        [AdmlPresentationMultiTextbox]$PresMultiText,
        [int]$Pos
     ){

        $this.ID = $PresMultiText.ID
        $this.Position = $Pos
        $this.Text = $PresMultiText.Text
        $this.ValueName = $Element.ValueName

        #Optional
        $this.Key = $Element.Key
        $this.Required = $Element.Required
        $this.MaxLength = $Element.MaxLength
        $this.MaxStrings = $Element.MaxStrings
     }

     [string[]]FormatOptionsControl(){
        $Format = "[MULTITEXT] {0}: [ ]" -f $this.Text
        return $Format
    }
}

class GPOToolsOptionList:GPOToolsOption {
    [boolean]$Additive
    [boolean]$ExplicitValue
    [string]$ValuePrefix # Need to see in the registry
    [boolean]$Required

    GPOToolsOptionList (
        [System.Xml.XmlElement]$Element,
        [AdmlPresentationListbox]$PresListbox,
        [int]$Pos
    ){

        $this.ID = $PresListbox.ID
        $this.Position = $Pos
        $this.Text = $PresListbox.Text
        $this.ValueName = $Element.ValueName

        #Optional
        $this.Additive = $Element.Additive
        $this.ExplicitValue = $Element.ExplicitValue
        $this.ValuePrefix = $Element.ValuePrefix
        $this.Required = '' # ADML
    }

    [string[]]FormatOptionsControl(){
        $Format = "[LIST] {0} [ ]" -f $this.Text
        return $Format
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
    [Hashtable]$PresentationTable

    #presentationTable

    GpoToolsAdml ([string]$AdmlPath) {
        $File = Get-Item -Path $AdmlPath
        [xml]$Xml = Get-Content -Path $File.FullName -Encoding UTF8

        $This.FilePath = $File.FullName
        $This.BaseName = $File.BaseName
        $this.StringTable = @{}
        $this.PresentationTable = @{}

        $xml.policyDefinitionResources.resources.stringTable.string | Foreach-Object {
            Write-Verbose ('Ajout du champ {0} dans la table StringTable pour le fichier {1}' -f $_.id,$File.BaseName)
            $this.StringTable.Add($_.id,$_.'#Text')
        }

        if ($null -ne $xml.policyDefinitionResources.resources.presentationTable){
            foreach ($Presentation in $xml.policyDefinitionResources.resources.presentationTable.presentation) {
                [System.Collections.ArrayList]$GenericCollection = @()
                Write-Verbose ('Ajout de la presentation {0} dans la table presentationTable pour le fichier {1}' -f $Presentation.id,$File.BaseName)
                Switch ($Presentation.get_ChildNodes()){
                    {$_.Name -eq 'text'} { [void]$GenericCollection.Add([AdmlPresentationText]::New($_)) ; continue }
                    {$_.Name -eq 'checkbox'} { [void]$GenericCollection.Add([AdmlPresentationCheckbox]::New($_)) ; continue }
                    {$_.Name -eq 'dropdownList'} { [void]$GenericCollection.Add([AdmlPresentationDropdownList]::New($_)) ; continue }
                    {$_.Name -eq 'textbox'} { [void]$GenericCollection.Add([AdmlPresentationTextbox]::New($_)) ; continue }
                    {$_.Name -eq 'decimalTextBox'} { [void]$GenericCollection.Add([AdmlPresentationDecimalTextbox]::New($_)) ; continue }
                    {$_.Name -eq 'multitextbox'} { [void]$GenericCollection.Add([AdmlPresentationMultiTextbox]::New($_)) ; continue }
                    {$_.Name -eq 'listbox'} { [void]$GenericCollection.Add([AdmlPresentationListbox]::New($_)) ; continue }
                }
                $this.PresentationTable.Add($Presentation.id, $GenericCollection)
            }
        }
    }
}

class AdmlPresentation {
    [string]$Text
    [string]$ID
}

class AdmlPresentationText:AdmlPresentation {

    AdmlPresentationText ([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.InnerText
        $this.ID = $Null
    }
}

class AdmlPresentationCheckbox:AdmlPresentation {
    [boolean]$DefaultCheck

    AdmlPresentationCheckbox([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.InnerText
        $this.ID = $Pres.refID
        If ($Pres.HasAttribute('defaultValue')){
            $this.DefaultCheck = $Pres.DefaultChecked
        }
    }
}

class AdmlPresentationDropdownList:AdmlPresentation {
    [string]$DefaultItem
    [boolean]$Sort = $False

    AdmlPresentationDropdownList([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.InnerText
        $this.ID = $Pres.refID
        If ($Pres.HasAttribute('defaultItem')){
            $this.DefaultItem = $Pres.DefaultItem
        }
        If ($Pres.HasAttribute('Sort')){
            $this.Sort = $Pres.Sort
        }ElseIf($Pres.HasAttribute('NoSort')){
            $this.Sort = !$Pres.NoSort
        }ElseIf($Pres.HasAttribute('OSort')){
            $this.Sort = !$Pres.OSort
        }
    }
}

class AdmlPresentationTextbox:AdmlPresentation {
    [String]$DefaultValue

    AdmlPresentationTextbox([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.Label
        $this.ID = $Pres.refID
        If ($Pres.HasAttribute('defaultValue')){
            $this.DefaultValue = $Pres.defaultValue
        }
    }
}

class AdmlPresentationDecimalTextbox:AdmlPresentation {
    [string]$DefaultValue

    AdmlPresentationDecimalTextbox([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.InnerText
        $this.ID = $Pres.refID
        If ($Pres.HasAttribute('defaultValue')){
            $this.DefaultValue = $Pres.defaultValue
        }
    }
}

class AdmlPresentationMultiTextbox:AdmlPresentation {
    AdmlPresentationMultiTextbox ([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.InnerText
        $this.ID = $Pres.refID
    }
}

class AdmlPresentationListbox:AdmlPresentation {
    [boolean]$Required

    AdmlPresentationListbox([System.Xml.XmlElement]$Pres) {
        $this.Text = $Pres.InnerText
        $this.ID = $Pres.refID
        If ($Pres.required){
            $this.Required = $Pres.Required
        }
    }
}