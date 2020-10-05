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
                    # Les items qui se trouvent dans la liste vont chercher leur ecriture dans string table
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
