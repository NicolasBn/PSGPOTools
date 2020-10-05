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