
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
        If ($Pres.HasAttribute('defaultChecked')){
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