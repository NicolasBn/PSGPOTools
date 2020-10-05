# Class pour les ressources SupportedOn (Exemple Windows.admx)
class AdmxSupportedOn {
    [string]$Name
    [string]$DisplayName

    AdmxSupportedOn ($SupportedOn) {
        $This.Name = $SupportedOn.Name
        $THis.DisplayName = $SupportedOn.DisplayName -replace '\$\(string\.(.*)\)', '$1'
    }
}