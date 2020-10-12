$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch{$false}) }
    ).BaseName

Import-Module $ProjectName

BeforeAll {
    $ADMXFolder = Get-ChildItem $ProjectPath -Recurse -Include ADMX
}

InModuleScope $ProjectName {
    Describe "GpoToolsAdmx class" {

        Context "Test constructor method" {
            $TestCases = @(
                @{
                    File = 'WindowsBackup.admx'
                },
                @{
                    File = 'WindowsUpdate.admx'
                }
            )

            It "Test object type for <File> file" -TestCases $TestCases {
                param(
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                'GpoToolsAdmx' -as [Type] | Should -BeOfType [Type]
                $ADMX -is [GPOToolsAdmx] | Should be $true
            }
        }

        Context "Test property" {
            $TestCases = @(
                @{
                    File = 'WindowsBackup.admx'
                    PoliciesCount = 5
                    Tab = @{
                        TabTarget = @(
                            [pscustomobject]@{
                                prefix = 'windowsbackup'
                                namespace = 'Microsoft.Policies.WindowsBackup'
                            }
                        )
                        TabUsing = @(
                            [pscustomobject]@{
                                prefix = 'backup'
                                namespace = 'Microsoft.Policies.Backup'
                            },
                            [pscustomobject]@{
                                prefix = 'windows'
                                namespace = 'Microsoft.Policies.Windows'
                            },
                            [pscustomobject]@{
                                prefix = 'server'
                                namespace = 'Microsoft.Policies.Server'
                            }
                        )
                        TabSupportedOn = @()
                        TabCat = @(
                            [PscustomObject]@{
                                Name = 'Backup'
                                DisplayName = 'Backup'
                                ParentCategory = @{
                                    prefix = 'windows'
                                    name = 'WindowsComponents'
                                }
                            },
                            [PscustomObject]@{
                                Name = 'BackupServer'
                                DisplayName = 'BackupServer'
                                ParentCategory = @{
                                    prefix = 'backup'
                                    name = 'Backup'
                                }
                            }
                        )
                        TabPol = @(
                            [PscustomObject]@{
                                Name = 'AllowOnlySystemBackup'
                                Class = 'Machine'
                                DisplayName = 'AllowOnlySystemBackup'
                                Regkey = 'Software\Policies\Microsoft\Windows\Backup\Server'
                                valueName = 'OnlySystemBackup'
                                ParentCategory = @{
                                    prefix = 'windowsbackup'
                                    name = 'BackupServer'
                                }
                                EnableValue = 1
                                DisableValue = 0
                            },[PscustomObject]@{
                                Name = 'DisallowLocallyAttachedStorageAsBackupTarget'
                                Class = 'Machine'
                                DisplayName = 'DisallowLocallyAttachedStorageAsBackupTarget'
                                Regkey = 'Software\Policies\Microsoft\Windows\Backup\Server'
                                valueName = 'NoBackupToDisk'
                                ParentCategory = @{
                                    prefix = 'windowsbackup'
                                    name = 'BackupServer'
                                }
                                EnableValue = '1'
                                DisableValue = '0'
                            },[PscustomObject]@{
                                Name = 'DisallowNetworkAsBackupTarget'
                                Class = 'Machine'
                                DisplayName = 'DisallowNetworkAsBackupTarget'
                                Regkey = 'Software\Policies\Microsoft\Windows\Backup\Server'
                                valueName = 'NoBackupToNetwork'
                                ParentCategory = @{
                                    prefix = 'windowsbackup'
                                    name = 'BackupServer'
                                }
                                EnableValue = 1
                                DisableValue = 0
                            },[PscustomObject]@{
                                Name = 'DisallowOpticalMediaAsBackupTarget'
                                Class = 'Machine'
                                DisplayName = 'DisallowOpticalMediaAsBackupTarget'
                                Regkey = 'Software\Policies\Microsoft\Windows\Backup\Server'
                                valueName = 'NoBackupToOptical'
                                ParentCategory = @{
                                    prefix = 'windowsbackup'
                                    name = 'BackupServer'
                                }
                                EnableValue = 1
                                DisableValue = 0
                            },[PscustomObject]@{
                                Name = 'DisallowRunOnceBackups'
                                Class = 'Machine'
                                DisplayName = 'DisallowRunOnceBackups'
                                Regkey = 'Software\Policies\Microsoft\Windows\Backup\Server'
                                valueName = 'NoRunNowBackup'
                                ParentCategory = @{
                                    prefix = 'windowsbackup'
                                    name = 'BackupServer'
                                }
                                EnableValue = 1
                                DisableValue = 0
                            }
                        )
                    }
                },
                @{
                    File = 'WindowsUpdate.admx'
                    PoliciesCount = 40
                    Tab = @{
                        TabTarget = @(
                            [pscustomobject]@{
                                prefix = 'wuau'
                                namespace = 'Microsoft.Policies.WindowsUpdate'
                            }
                        )
                        TabUsing = @(
                            [pscustomobject]@{
                                prefix = 'windows'
                                namespace = 'Microsoft.Policies.Windows'
                            }
                        )
                        TabSupportedOn = @(
                            [pscustomobject]@{
                                Name = 'WU_SUPPORTED_Windows7ToXPSP2'
                                DisplayName = 'WU_SUPPORTED_Windows7ToXPSP2'
                            },
                            [pscustomobject]@{
                                Name = 'WU_SUPPORTED_Windows7_To_Win2kSP3_Or_XPSP1'
                                DisplayName = 'WU_SUPPORTED_Windows7_To_Win2kSP3_Or_XPSP1'
                            },
                            [pscustomobject]@{
                                Name = 'WU_SUPPORTED_Win2kSP3_Or_XPSP1_NoWinRT'
                                DisplayName = 'WU_SUPPORTED_Win2kSP3_Or_XPSP1_NoWinRT'
                            },
                            [pscustomobject]@{
                                Name = 'WU_SUPPORTED_WindowsXPSP1_NoWinRT'
                                DisplayName = 'WU_SUPPORTED_WindowsXPSP1_NoWinRT'
                            },
                            [pscustomobject]@{
                                Name = 'WU_SUPPORTED_Win2kSP3_Or_XPSP1_Through_Win81_or_Server2012R2'
                                DisplayName = 'WU_SUPPORTED_Win2kSP3_Or_XPSP1_Through_Win81_or_Server2012R2'
                            },
                            [pscustomobject]@{
                                Name = 'WU_SUPPORTED_WindowsVista_Through_Win81_or_Server2012R2'
                                DisplayName = 'WU_SUPPORTED_WindowsVista_Through_Win81_or_Server2012R2'
                            }
                        )
                        TabCat = @(
                            [Pscustomobject]@{
                                Name = 'WindowsUpdateCat'
                                DisplayName = 'WindowsUpdateCat'
                                ParentCategory = @{
                                    prefix = 'windows'
                                    name = 'WindowsComponents'
                                }
                            },
                            [Pscustomobject]@{
                                Name = 'DeferUpdateCat'
                                DisplayName = 'DeferUpdateCat'
                                ParentCategory = @{
                                    prefix = 'wuau'
                                    name = 'WindowsUpdateCat'
                                }
                            }
                        )
                        TabPol = @(
                            [PscustomObject]@{
                                Name = 'NoAutoUpdate'
                                Class = 'User'
                                DisplayName = 'NoAutoUpdate'
                                Regkey = 'Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                                valueName = 'NoAutoUpdate'
                                ParentCategory = @{
                                    prefix = 'windows'
                                    name = 'System'
                                }
                                EnableValue = 1
                                DisableValue = 0
                            },[PscustomObject]@{
                                Name = 'AUDontShowUasPolicy'
                                Class = 'Both'
                                DisplayName = 'AUDontShowUasPolicy'
                                Regkey = 'Software\Policies\Microsoft\Windows\WindowsUpdate\AU'
                                valueName = 'NoAUShutdownOption'
                                ParentCategory = @{
                                    prefix = 'wuau'
                                    name = 'WindowsUpdateCat'
                                }
                                EnableValue = 1
                                DisableValue = 0
                            }
                        )
                    }
                }
            )

            It "Test FilePath property for <File> file" -TestCases $TestCases {
                param(
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.FilePath -is [string] | Should be $true
                $ADMX.FilePath | Should be $ADMXPath
            }

            It "Test BaseName Property for <File> file"-TestCases $TestCases {
                param(
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.BaseName -is [string] | Should be $true
                $ADMX.BaseName | Should be $File.TrimEnd('.admx')
            }

            It "Test Target Property for <File> file" -TestCases $TestCases {
                param(
                    $Tab,
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.Target -is [AdmxNamespace] | Should be $true
                $ADMX.Target.prefix | Should be $Tab.TabTarget.prefix
                $ADMX.Target.Namespace | Should be $Tab.TabTarget.namespace
            }

            It "Test Using Property for <File> file" -TestCases $TestCases {
                param(
                    $Tab,
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.Using -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Using.count | Should be $Tab.TabUsing.Count
                for ($i = 0 ; $i -lt $ADMX.Using.count; $i++){
                    $ADMX.Using[$i] -is [AdmxNamespace] | should be $true
                    $ADMX.Using[$i].prefix | Should be $Tab.TabUsing[$i].prefix
                    $ADMX.Using[$i].namespace | Should be $Tab.TabUsing[$i].namespace
                }
            }

            It "Test SupportedOnDefinition for <File> file" -TestCases $TestCases {
                param(
                    $Tab,
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.SupportedOnDefinition -is [System.Collections.ArrayList] | Should be $true
                $ADMX.SupportedOnDefinition.count | Should be $Tab.TabSupportedOn.count
                for ($i = 0 ; $i -lt $ADMX.SupportedOnDefinition.count; $i++){
                    $ADMX.SupportedOnDefinition[$i].Name | Should be $Tab.TabSupportedOn[$i].Name
                    $ADMX.SupportedOnDefinition[$i].DisplayName | Should be $Tab.TabSupportedOn[$i].DisplayName
                }
            }

            It "Test Category for <File> file" -TestCases $TestCases {
                param(
                    $Tab,
                    $File
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.Categories -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Categories.count | Should be $Tab.TabCat.count
                for ($i = 0 ; $i -lt $ADMX.Categories.count; $i++){
                    $ADMX.Categories[$i].Name | Should be $Tab.TabCat[$i].Name
                    $ADMX.Categories[$i].DisplayName | Should be $Tab.TabCat[$i].DisplayName
                    $ADMX.Categories[$i].ParentCategory.prefix | Should be $Tab.TabCat[$i].ParentCategory.prefix
                    $ADMX.Categories[$i].ParentCategory.Name | Should be $Tab.TabCat[$i].ParentCategory.Name
                    #$ADMX.Categories[$i].ExplainText
                }
            }

            It "Test policy for <File> file" -TestCases $TestCases {
                param(
                    $Tab,
                    $File,
                    $PoliciesCount
                )
                $ADMXPath  = Join-Path -Path $ADMXFolder -ChildPath $File
                $ADMX = [GPOToolsAdmx]::New($ADMXPath)

                $ADMX.Policies -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Policies.count | Should be $PoliciesCount
                for ($i = 0 ; $i -lt 2; $i++){
                    $ADMX.Policies[$i].Name | Should be $Tab.TabPol[$i].Name
                    $ADMX.Policies[$i].Class | Should be $Tab.TabPol[$i].Class
                    $ADMX.Policies[$i].DisplayName | Should be $Tab.TabPol[$i].DisplayName
                    $ADMX.Policies[$i].RegKey | Should be $Tab.TabPol[$i].RegKey
                    $ADMX.Policies[$i].ValueName | Should be $Tab.TabPol[$i].ValueName
                    $ADMX.Policies[$i].ParentCategory.prefix | Should be $Tab.TabPol[$i].ParentCategory.prefix
                    $ADMX.Policies[$i].ParentCategory.name | Should be $Tab.TabPol[$i].ParentCategory.name
                    $ADMX.Policies[$i].enableValue | Should be $Tab.TabPol[$i].enableValue
                    $ADMX.Policies[$i].disableValue | Should be $Tab.TabPol[$i].disableValue
                }
            }
        }
    }



            <#
            It 'Has a default constructor' {
                $instance = [class1]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'class1'
            }
        }

        Context 'Methods' {
            BeforeEach {
                $instance = [class1]::new()
            }

            It 'Overrides the ToString method' {
                # Typo "calss" is inherited from definition. Preserved here as validation is demonstrative.
                $instance.ToString() | Should -Be 'This calss is class1'
            }
        }

        Context 'Properties' {
            BeforeEach {
                $instance = [class1]::new()
            }

            It 'Has a Name property' {
                $instance.Name | Should -Be 'Class1'
            }
        }

    }
    #>
}
