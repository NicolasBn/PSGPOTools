#Classe de recuperation des informations contenues dans les fichiers admx
class GPOToolsAdml {
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
