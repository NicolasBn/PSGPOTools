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

    static [System.Collections.Generic.List[GpoToolsAdml]]ImportFromFolder([string]$FolderPath) {
        [System.Collections.Generic.List[GpoToolsAdml]]$Tab = @()


        if (!(Test-Path -Path $FolderPath)) {
            Throw 'This folder does not exist'
        }
        $Files = Get-ChildItem -Path $FolderPath -Filter *.adml

        foreach ($File in $Files) {
            $Tab.Add([GpoToolsAdml]::New($File.FullName))
        }

        return $Tab
    }

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

    static [System.Collections.Generic.List[GpoToolsAdmx]]ImportFromFolder([string]$FolderPath) {
        [System.Collections.Generic.List[GpoToolsAdmx]]$Tab = @()


        if (!(Test-Path -Path $FolderPath)) {
            Throw 'This folder does not exist'
        }
        $Files = Get-ChildItem -Path $FolderPath -Filter *.admx

        foreach ($File in $Files) {
            $Tab.Add([GpoToolsAdmx]::New($File.FullName))
        }

        return $Tab
    }

}
#Classe utilisée dans GPOToolsAdmx  pour lire les policy
class AdmxPolicy {
    $Name
    $Class
    $DisplayNameVar
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
        $this.DisplayNameVar = $policy.DisplayName -replace '\$\(string\.(.*)\)', '$1'
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
    $Name
    $DisplayNames

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

class AdmxElement {

    $Type

    #Boolean
    #text
    #enum
    #decimal
    #list
}