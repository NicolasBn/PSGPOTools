class GPOToolsUtility {
    static [System.Collections.Generic.List[GpoToolsSupportedOn]]$SupportOnTable = @()
    static [System.Collections.Generic.List[GpoToolsCategory]]$Categories = @()
    static [System.Collections.Generic.List[GpoToolsPolicy]]$Policies = @()
    static [System.Collections.ArrayList]$TargetLoad = @()

    static [void]InitiateAdmxAdml(
        [System.IO.DirectoryInfo]$Folder,
        [cultureinfo]$UICulture
    ){
        #Importer l'ensemble des fichiers admx
        #Importer les dependances en premier lieu !
        #Pour chaque fichier ADMX on importe le fichier AMDL correspondant
        #On incremente les categories
        #Comment valider que les dependances sont bien deja presents et pas necessaire de les recharger ?
        #noter un element unique (nom du fichier ?) hashtable ?

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
            #On verifie que le fichier AMDX n'a pas deja ete charge.
            If (![GPOToolsUtility]::TargetLoad.Contains([GPOToolsUtility]::GetNamespaceAdmx($File))){
                Write-Verbose "Initialization of $File"
                #Creation de l'objet ADMX
                $ADMX = [GpoToolsAdmx]::New($File.FullName)

                #On verifie si il a besoin de dependance et on les charges
                [GPOToolsUtility]::CheckAndInitiateDependancy($ADMX,$UICulture)

                #On determine le fichier ADML correspondant
                $ADMLPath = [GPOToolsUtility]::GetADMLPathFromADMX($File,$UICulture)

                #On charge le fichier ADML correspondant
                $ADML = [GpoToolsAdml]::New($ADMLPath)

                #On cree les objets SupportedOn
                $Support = $ADMX.SupportedOnDefinition | Foreach-Object { [GPOToolsSupportedOn]::New($_,$ADML) }

                #On initialise les objets Category
                [GPOToolsCategory]::LoadAdmxAdml($Admx,$Adml)

                #On cree les objet Policy
                $Pols = $ADMX.Policies | Foreach-Object {[GPOToolsPolicy]::New($_,$ADML)}

                #On incremente les objets dans les proprietes statiques
                if ($Support.count -gt 0){
                    $Support | Foreach-Object {[GPOToolsutility]::SupportOnTable.Add($_)}
                }
                if ($Pols.count -gt 0){
                    $Pols | Foreach-Object {[GPOToolsutility]::Policies.Add($_)}
                }

                [GPOToolsutility]::TargetLoad.Add($ADMX.Target.namespace)

            }Else{
                Write-Verbose "$File is already Initiate"
            }
        }Else{
            Write-Error "File $File not found"
        }
    }

    static [string]GetNamespaceAdmx(
        [System.IO.FileInfo]$AdmxFile
    ){
        [xml]$Xml = Get-Content -Path $AdmxFile.FullName -Encoding UTF8
        return $Xml.policyDefinitions.policyNamespaces.target.namespace
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
            #On verifie si la dependance est deja charge ou si il s'agit de product
            if (![GPOToolsUtility]::TargetLoad.Contains($_.namespace) -and $($ADMX.Target.namespace -ne 'Microsoft.Policies.Products')){
                Write-Verbose ('The ADMX {0} need {1} dependancy' -f $ADMX.FilePath,$_.namespace)
                #on determine de fichier ADMX dont le premier depend
                #Rajouter un trycatch en cas de generation d'erreur et mise en place d'un warning
                Try{
                    $DepFile = [GPOToolsUtility]::FindDependancyFile($ADMX.FilePath,$_.namespace)
                }
                Catch {
                    Write-Warning $_.Exception.message
                    $DepFile = $null
                }
                #On charge la dependance si il y en a une
                if ($null -ne $DepFile){
                    [GPOToolsUtility]::InitiateAdmxAdml($DepFile,$UICulture)
                }
            }
        }
    }
    <#
        Method utilise pour rechercher les fichiers admx dont depend un fichier admx
        Exe. : WindowsBackup.admx a besoin de windows.admx
        Use :
            [GPOToolsUTility]::CheckAndInitiateDependancy()
    #>
    static [System.IO.FileInfo]FindDependancyFile(
        [string]$Path,
        [string]$namespace
    ){
        $FolderPath = Split-Path -Path $Path
        $Files = Get-ChildItem -Path $FolderPath -Filter *.admx -Exclude $Path.Name
        $File = $Files | Foreach-Object {
            if([GPOToolsUtility]::GetNamespaceAdmx($_) -eq $namespace){
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
    <# Methode pour verifier la presence d'une category dans la propriete static de
     la classe GPOToolsUtility. Elle se base sur la propriete target de l'objet
     Category. Target comprend le prefix et le namespace pour avoir un filtre plus
     precis.

     Use :
    #>
    static [bool]CheckCategoryPresence(
        [string]$Name,
        [hashtable]$target
    ){
        $Result = [GPOToolsUtility]::Categories |
            Where-Object {
                ($_.Name -eq $Name) -and
                ($_.target.prefix -eq $target.prefix) -and
                ($_.target.namespace -eq $target.namespace)
            }
        if ($Result.count -eq 0){
            return $false
        }Else{
            return $true
        }
    }

    <# Surcharge de Methode pour verifier la presence d'une category dans la
     propriete static de la classe GPOToolsUtility. Cette surcharge se base seulement
     sur le nom du prefix et pas sur le namespace. Cela reduit le precision de la
     verification.
     Use :
        [GPOToolsCategory]::Create()
    #>
    static [bool]CheckCategoryPresence(
        [string]$Name,
        [string]$TargetPrefix
    ){
        $return = $false
        $Result = [GPOToolsUtility]::Categories |
            Where-Object {
                ($_.Name -eq $Name) -and
                ($_.target.prefix -eq $TargetPrefix)
            }
        switch ($Result.Count){
            1 {$return = $true}
            0 {$return =  $false}
            {$_ -ge 2} {
                throw ('[GPOToolsUtility](CheckCategoryPresence) To many Category found for {0}.' -f $Name)
            }
            default {
                throw ('[GPOToolsUtility](CheckCategoryPresence) Unknow error for {0} category.' -f $Name)
            }
        }
        return $return
    }

    # Methode pour vider les membre static de GPOToolsUtility. Cela permet d'en
    # initialiser de nouveaux.
    static [void]RemoveAll(){
        foreach($Property in @(
                [GPOToolsUtility]::SupportOnTable,
                [GPOToolsUtility]::Categories,
                [GPOToolsUtility]::Policies,
                [GPOToolsUtility]::TargetLoad
            )
        ){
            $Property.Clear()
        }
    }

}# End GPOToolsUtility




