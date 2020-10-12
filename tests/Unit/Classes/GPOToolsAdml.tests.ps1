$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

BeforeAll {
    $Culture = [cultureinfo]'fr-FR'
    $ADMXFolder = Get-ChildItem $ProjectPath -Recurse -Include ADMX
    $ADMLFolder = Join-Path -Path $ADMXFolder -ChildPath $Culture
}

InModuleScope $ProjectName {
    Describe "GPOToolsAdml class" {
        Context "Test constructor method" {
            $TestCases = @(
                @{
                    File = 'WindowsBackup.adml'
                },
                @{
                    File = 'WindowsUpdate.adml'
                }
            )

            It "Test object type for <File> file" -TestCases $TestCases {
                param(
                    $File
                )
                $ADMLPath  = Join-Path -Path $ADMLFolder -ChildPath $File
                $ADML = [GPOToolsAdml]::New($ADMLPath)

                'GpoToolsAdml' -as [Type] | Should -BeOfType [Type]
                $ADML -is [GPOToolsAdml] | Should be $true
            }
        }

        Context "Test property" {
            $TestCases = @(
                @{
                    File = 'WindowsBackup.adml'
                    StringTable = @{
                        # Warning to encoding script for special caractere
                        AllowOnlySystemBackup = 'Autoriser\suniquement\sla\ssauvegarde\sdu\ssyst\xE8me'
                        DisallowLocallyAttachedStorageAsBackupTarget = 'Ne\spas\sautoriser\sun\sp\xE9riph\xE9rique\sde\sstockage\sconnect\xE9\slocalement\s\xE0\sfaire\soffice\sde\scible\sde\ssauvegarde'
                        Backup = 'Sauvegarde'
                        windowscomponents = 'Composants Windows'
                    }
                },
                @{
                    File = 'WindowsUpdate.adml'
                }
            )

            It "Test FilePath property for <File> file" -TestCases $TestCases {
                param(
                    $File
                )
                $ADMLPath  = Join-Path -Path $ADMLFolder -ChildPath $File
                $ADML = [GPOToolsAdml]::New($ADMLPath)

                $ADML.FilePath -is [string] | Should be $true
                $ADML.FilePath | Should be $ADMLPath
            }

            It "Test BaseName Property for <File> file"-TestCases $TestCases {
                param(
                    $File
                )
                $ADMLPath  = Join-Path -Path $ADMLFolder -ChildPath $File
                $ADML = [GPOToolsAdml]::New($ADMLPath)

                $ADML.BaseName -is [string] | Should be $true
                $ADML.BaseName | Should be $File.TrimEnd('.adml')
            }

            It "Test StringTable Property for <File> file" -TestCases $TestCases.where({$_.containskey('StringTable')}) {
                param(
                    $File,
                    $StringTable
                )
                $ADMLPath  = Join-Path -Path $ADMLFolder -ChildPath $File
                $ADML = [GPOToolsAdml]::New($ADMLPath)

                $StringTable.GetEnumerator() | Foreach-Object {
                    $ADML.StringTable.ContainsKey($_.Key) | Should Be $true
                    $ADML.StringTable."$($_.Key)" | Should Match $_.Value
                }
            }
            # IT prensentation
        }
    }
}