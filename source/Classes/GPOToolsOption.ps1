
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
        if ($PresCheckbox.DefaultCheck){$this.DefaultCheck = $PresCheckbox.DefaultCheck}
    }

    [string[]]FormatOptionsControl(){
        $Format = "[CHECKBOX] {0} [ ]"
        $Format = $Format + "{2}     DefaultCheck [{1}]"
        $Format = $Format -f $this.Text,$this.DefaultCheck,[System.Environment]::NewLine
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
            )
        } -End {
            $Format = $Format + "{1}]"
            $Format = $Format -f $_.DisplayName,[System.Environment]::NewLine,$_.Value
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