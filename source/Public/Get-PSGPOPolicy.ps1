function Get-PSGPOPolicy {
    [cmdletbinding()]
    Param(
        [Parameter (Mandatory = $false)]
        [ValidateSet('Machine','User')]
        [string]$Scope

    )

   begin
   {
    $Policies =  [GpoToolsUtility]::Policies
   }
   process{

    if ( $PsBoundParameters.ContainsKey('Scope') ) {
        switch ($Scope) {
            'Machine' {  $Policies = $Policies| Where-Object {$_.Scope -eq 'Machine'} }
            'User'{ $Policies = $Policies| Where-Object {$_.Scope -eq 'User'} }
            Default {}
        }
    }
    If ($null -eq $Policies){
        Write-Warning "Initiate ADMX and ADML files with Initialize-PSGPOAdmx cmdlet."
    }
   }
   end
   {
       return $Policies
    }

}