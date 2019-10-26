#Defines folders to import
$functionFolders = @('Public', 'Private')

ForEach ($folder in $functionFolders) {

    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folder

    If (Test-Path -Path $folderPath) {

        Write-Verbose -Message "Importing from $folder"
        $functions = Get-ChildItem -Path $folderPath -Filter '*.ps1'

        ForEach ($function in $functions) {
            Write-Verbose -Message "  Importing $($function.BaseName)"
            #Dot source function file
            . $function.providerpath
        }
    }
}

#Export public functions
$publicFunctions = (Get-ChildItem -Path "$PSScriptRoot\functions\Public" -Filter '*.ps1').BaseName
Export-ModuleMember -Function $publicFunctions