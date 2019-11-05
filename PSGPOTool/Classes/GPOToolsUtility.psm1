class GPOToolsUtility {
    static [System.Collections.Generic.List[GpoToolsSupportedOn]]$SupportOnTable
    static [System.Collections.Generic.List[GpoToolsCategory]]$Categories
    static [System.Collections.Generic.List[GpoToolsPolicy]]$Policies
    static [System.Collections.ArrayList]$TargetLoad

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
            If (![GPOToolsUtility]::TargetLoad.Contains($File.BaseName)){
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
                $Support = [GPOToolsSupportedOn]::New($ADMX,$ADML)

                #On crée les objets Category

                #On crée les objet Policy


                #On incrémente les objets dans les propriétés statiques
                $Support | Foreach-Object {[GPOToolsutility]::SupportOnTable.Add($_)}
                [GPOToolsutility]::TargetLoad.Add($ADMX.Target.namespace)

            }Else{
                Write-Verbose "$File is already Initiate"
            }
        }Else{
            Write-Error "File $File not found"
        }
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
                $DepFile = [GPOToolsUtility]::FindDependancyFile($ADMX.FilePath,$_.namespace)
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
            [xml]$Content = Get-Content -Path $_.FullName -Encoding UTF8
            if($Content.policyDefinitions.policyNamespaces.target.namespace -eq $namespace){
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

    static [void]RemoveAll(){
        @([GPOToolsUtility]::SupportOnTable,[GPOToolsUtility]::Categories,[GPOToolsUtility]::Policies,[GPOToolsUtility]::TargetLoad) | ForEach-Object {
            if ($_.count -eq 0){
                Write-Verbose "$_ is already empty"
            }Else{
                $_::RemoveAll()
            }
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

    [void]LoadAdmxAdml(
        [GpoToolsAdmx]$Admx,
        [GpoToolsAdml]$Adml
    ){
        $Admx.SupportedOnDefinition | Foreach-Object {
            [GPOToolsSupportedOn]::New($_,$Adml)
        }
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

        $This.FilePath = $File.FullName
        $This.BaseName = $File.BaseName
        $This.Target = [AdmxNamespace]::New($PolicyDefinitions.policyNamespaces.target)

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
                $this.Categories.Add($([AdmxCategory]::New($_)))
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
    [string]$explainText
    [string]$ParentCategoryName

    AdmxCategory ($Category){
        $this.Name = $Category.Name
        $this.DisplayName = $Category.DisplayName -replace '\$\(string\.(.*)\)', '$1'
        $this.explainText = $Category.explainText -replace '\$\(string\.(.*)\)', '$1'
        $this.ParentCategoryName = $Category.parentcategory.ref
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

        $xml.policyDefinitionResources.resources.StringTable.string | Foreach-Object {
            $this.StringTable.Add($_.id,$_.'#Text')
        }
    }
}