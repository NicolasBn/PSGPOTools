
Get-Module PSGPOTools | Remove-Module -ErrorAction Stop
Import-Module '..\..\PSGPOTools\PSGPOTools.psm1'

$TestPath = Split-Path $MyInvocation.MyCommand.Path

Push-Location -Path $TestPath
Set-Location -Path $TestPath

#Describe "Test AdmxSupportedOn class"
#Describe "Test AdmxNamespace class"
#Describe "Test AdmxCategory class"
#Describe "Test AdmxPolicy class"

InModuleScope -ModuleName PSGPOTools {
    Describe "Test GpoToolsAdmx class" {
        Context "Test constructor method for Admx WindowsBackup" {
            $ADMXPath = (Get-Item -Path "..\..\sources\PolicyDefinitions\WindowsBackup.admx").FullName
            $ADMX = [GPOToolsAdmx]::New($ADMXPath)
            $UsingTab = @(
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
            $CatTab = @(
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
            $PolTab = @(
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
            It "Test ADMX object type"{
                $ADMX -is [GPOToolsAdmx] | Should be $true
            }

            It "Test FilePath property type"{
                $ADMX.FilePath -is [string] | Should be $true
            }
            It "Test FilePath proprerty value"{
                $ADMX.FilePath | Should be $ADMXPath
            }

            It "Test BaseName Property type"{
                $ADMX.BaseName -is [string] | Should be $true
            }
            It "Test BaseName Property Value"{
                $ADMX.BaseName | Should be "WindowsBackup"
            }

            It "Test Target Property Type" {
                $ADMX.Target -is [AdmxNamespace] | Should be $true
            }
            It "Test Target SubProperty Value" {
                $ADMX.Target.prefix | Should be 'windowsbackup'
                $ADMX.Target.Namespace | Should be 'Microsoft.Policies.WindowsBackup'
            }

            It "Test Using Property Type" {
                $ADMX.Using -is [System.Collections.ArrayList] | Should be $true
            }
            It "Test Using Property Value"{
                $ADMX.Using.count | Should be $UsingTab.Count
                for ($i = 0 ; $i -lt $ADMX.Using.count; $i++){
                    $ADMX.Using[$i] -is [AdmxNamespace] | should be $true
                    $ADMX.Using[$i].prefix | Should be $UsingTab[$i].prefix
                    $ADMX.Using[$i].namespace | Should be $UsingTab[$i].namespace
                }
            }

            It "Test SupportedOnDefinition Type" {
                $ADMX.SupportedOnDefinition -is [System.Collections.ArrayList] | Should be $true
            }
            It "Test SupportedOnDefinition Value" {
                $ADMX.SupportedOnDefinition.count | Should be 0
            }

            It "Test Category Type" {
                $ADMX.Categories -is [System.Collections.ArrayList] | Should be $true
            }
            It "Test Category Value" {
                $ADMX.Categories.count | Should be 2
                for ($i = 0 ; $i -lt $ADMX.Categories.count; $i++){
                    $ADMX.Categories[$i].Name | Should be $CatTab[$i].Name
                    $ADMX.Categories[$i].DisplayName | Should be $CatTab[$i].DisplayName
                    $ADMX.Categories[$i].ParentCategory.prefix | Should be $CatTab[$i].ParentCategory.prefix
                    $ADMX.Categories[$i].ParentCategory.name | Should be $CatTab[$i].ParentCategory.name
                    #$ADMX.Categories[$i].ExplainText
                }
            }

            It "Test policy" {
                $ADMX.Policies -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Policies.count | Should be $PolTab.Count
                for ($i = 0 ; $i -lt $ADMX.Policies.count; $i++){
                    $ADMX.Policies[$i].Name | Should be $PolTab[$i].Name
                    $ADMX.Policies[$i].Class | Should be $PolTab[$i].Class
                    $ADMX.Policies[$i].DisplayName | Should be $PolTab[$i].DisplayName
                    $ADMX.Policies[$i].RegKey | Should be $PolTab[$i].RegKey
                    $ADMX.Policies[$i].ValueName | Should be $PolTab[$i].ValueName
                    $ADMX.Policies[$i].ParentCategory.prefix | Should be $PolTab[$i].ParentCategory.prefix
                    $ADMX.Policies[$i].ParentCategory.name | Should be $PolTab[$i].ParentCategory.name
                    $ADMX.Policies[$i].enableValue | Should be $PolTab[$i].enableValue
                    $ADMX.Policies[$i].disableValue | Should be $PolTab[$i].disableValue
                }
            }
        }

        Context "Test constructor method for Admx WindowsUpdate" {
            $ADMXPath = (Get-Item -Path "..\..\sources\PolicyDefinitions\WindowsUpdate.admx").FullName
            $ADMX = [GPOToolsAdmx]::New($ADMXPath)
            $UsingTab = @(
                [pscustomobject]@{
                    prefix = 'windows'
                    namespace = 'Microsoft.Policies.Windows'
                }
            )
            $TabSupportedOn = @(
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
            $CatTab = @(
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

            $PolTab = @(
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

            #IT blocks
            It "Test object type"{
                $ADMX -is [GPOToolsAdmx] | Should be $true
            }

            It "Test FilePath property"{
                $ADMX.FilePath -is [string] | Should be $true
                $ADMX.FilePath | Should be $ADMXPath
            }

            It "Test BaseName Property"{
                $ADMX.BaseName -is [string] | Should be $true
                $ADMX.BaseName | Should be "WindowsUpdate"
            }

            It "Test Target Property" {
                $ADMX.Target -is [AdmxNamespace] | Should be $true
                $ADMX.Target.prefix | Should be 'wuau'
                $ADMX.Target.Namespace | Should be 'Microsoft.Policies.WindowsUpdate'
            }

            It "Test Using Property" {
                $ADMX.Using -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Using.count | Should be $UsingTab.Count
                for ($i = 0 ; $i -lt $ADMX.Using.count; $i++){
                    $ADMX.Using[$i] -is [AdmxNamespace] | should be $true
                    $ADMX.Using[$i].prefix | Should be $UsingTab[$i].prefix
                    $ADMX.Using[$i].namespace | Should be $UsingTab[$i].namespace
                }
            }

            It "Test SupportedOnDefinition"{
                $ADMX.SupportedOnDefinition -is [System.Collections.ArrayList] | Should be $true
                $ADMX.SupportedOnDefinition.count | Should be $TabSupportedOn.count
                for ($i = 0 ; $i -lt $ADMX.SupportedOnDefinition.count; $i++){
                    $ADMX.SupportedOnDefinition[$i].Name | Should be $TabSupportedOn[$i].Name
                    $ADMX.SupportedOnDefinition[$i].DisplayName | Should be $TabSupportedOn[$i].DisplayName
                }
            }

            It "Test Category" {
                $ADMX.Categories -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Categories.count | Should be $CatTab.count
                for ($i = 0 ; $i -lt $ADMX.Categories.count; $i++){
                    $ADMX.Categories[$i].Name | Should be $CatTab[$i].Name
                    $ADMX.Categories[$i].DisplayName | Should be $CatTab[$i].DisplayName
                    $ADMX.Categories[$i].ParentCategory.prefix | Should be $CatTab[$i].ParentCategory.prefix
                    $ADMX.Categories[$i].ParentCategory.Name | Should be $CatTab[$i].ParentCategory.Name
                    #$ADMX.Categories[$i].ExplainText
                }
            }

            It "Test policy" {
                $ADMX.Policies -is [System.Collections.ArrayList] | Should be $true
                $ADMX.Policies.count | Should be 40
                for ($i = 0 ; $i -lt $ADMX.Policies.count; $i++){
                    $ADMX.Policies[$i].Name | Should be $PolTab[$i].Name
                    $ADMX.Policies[$i].Class | Should be $PolTab[$i].Class
                    $ADMX.Policies[$i].DisplayName | Should be $PolTab[$i].DisplayName
                    $ADMX.Policies[$i].RegKey | Should be $PolTab[$i].RegKey
                    $ADMX.Policies[$i].ValueName | Should be $PolTab[$i].ValueName
                    $ADMX.Policies[$i].ParentCategory.prefix | Should be $PolTab[$i].ParentCategory.prefix
                    $ADMX.Policies[$i].ParentCategory.name | Should be $PolTab[$i].ParentCategory.name
                    $ADMX.Policies[$i].enableValue | Should be $PolTab[$i].enableValue
                    $ADMX.Policies[$i].disableValue | Should be $PolTab[$i].disableValue
                }
            }
        }
    }

    Describe "Test GPOToolsADML class"{
        Context "Test constructor method"{
            $Culture = [cultureinfo]'fr-FR'
            $ADMLFile = Get-Item -Path "..\..\sources\PolicyDefinitions\$Culture\WindowsBackup.adml"
            $ADMLPath = $ADMLFile.FullName
            $StringTableTest = @{
                # Warning to encoding script for special caractere
                AllowOnlySystemBackup = 'Autoriser\suniquement\sla\ssauvegarde\sdu\ssyst\xE8me'
                DisallowLocallyAttachedStorageAsBackupTarget = 'Ne\spas\sautoriser\sun\sp\xE9riph\xE9rique\sde\sstockage\sconnect\xE9\slocalement\s\xE0\sfaire\soffice\sde\scible\sde\ssauvegarde'
                Backup = 'Sauvegarde'
                windowscomponents = 'Composants Windows'
            }

            $ADML = [GPOToolsAdml]::new($ADMLPath)
            It "Test GPOToolsADML type"{
                $ADML -is [GPOToolsADML] | Should Be $true
            }

            It "Test GPOToolsADML properties"{
                $ADML.FilePath | Should Be $ADMLPath
                $ADML.BaseName | Should Be $ADMLFile.BaseName
            }

            It 'Test GPOToolsADML StringTable'{
                $StringTableTest.GetEnumerator() | Foreach-Object {
                    $ADML.StringTable.ContainsKey($_.Key) | Should Be $true
                    $ADML.StringTable."$($_.Key)" | Should Match $_.Value
                }
            }
        }
    }

    Describe "Test GPOToolsSupportedOn class" {
        Context "Test method constructor" {
            $Culture = [cultureinfo]'fr-FR'
            $ADMXFile = Get-Item -Path "..\..\sources\PolicyDefinitions\Windows.admx"
            $ADMLFile = Get-Item -Path "..\..\sources\PolicyDefinitions\$Culture\Windows.adml"
            $ADMX = [GpoToolsAdmx]::new($ADMXFile)
            $ADML = [GpoToolsAdml]::new($ADMLFile)
            $Support = [GPOToolsSupportedOn]::new($ADMX.SupportedOnDefinition[0],$ADML)
            $LoadAdm = [GPOToolsSupportedOn]::LoadAdmxAdml($ADMX,$ADML)
            $TestSup = @(
                [PScustomObject]@{
                    Name = 'SUPPORTED_AllowWebPrinting'
                    DisplayNamePattern = "Windows\s2000\sou\sversion\sult\xE9rieure,\sex\xE9cutant\sIIS.\sNon\spris\sen\scharge\spar\sWindows\sServer\s2003"
                },
                [PScustomObject]@{
                    Name = 'SUPPORTED_IE6SP1'
                    DisplayNamePattern = "Au\sminimum\sInternet\sExplorer\s6\sService\sPack\s1"
                }
            )


            It "Test constructor method"{
                $Support -is [GPOToolsSupportedOn] | Should be $true
                $Support.Name | Should Be 'SUPPORTED_AllowWebPrinting'
                $Support.DisplayName | should Match "Windows\s2000\sou\sversion\sult\xE9rieure,\sex\xE9cutant\sIIS.\sNon\spris\sen\scharge\spar\sWindows\sServer\s2003"
            }

            It "Test LoadAdmxAdml static method" {
                $LoadAdm.Gettype().BaseType.Name | Should Be 'Array'
                $LoadAdm | Should BeOfType System.Object
                for ($i = 0 ; $i -lt $TestSup.count; $i++){
                    $LoadAdm[$i].Name | Should be $TestSup[$i].Name
                    $LoadAdm[$i].DisplayName | Should Match $TestSup[$i].DisplayNamePattern
                }
            }
        }
    }

    Describe "Test GPOToolsCategory class" {
        Context "Test method constructor" {
            $Culture = [cultureinfo]'fr-FR'
            $ADMXFile = Get-Item -Path "..\..\sources\PolicyDefinitions\Windows.admx"
            $ADMLFile = Get-Item -Path "..\..\sources\PolicyDefinitions\$Culture\Windows.adml"
            $ADMX = [GpoToolsAdmx]::new($ADMXFile)
            $ADML = [GpoToolsAdml]::new($ADMLFile)
            $Category = [GPOToolsCategory]::new($ADMX.Categories[0],$ADMX.Categories,$ADML)
            #Tester la methode create()

            $CatTab = @(
                [PScustomObject]@{
                    Name = 'System'
                    DisplayNamePattern = "Syst\xE8me"
                    ExplainText = 'Autorise\sla\sconfiguration\sde\sdivers\sparam\xE8tres\sde\scomposants\ssyst\xE8me.'
                },
                [PScustomObject]@{
                    Name = 'InternetManagement'
                    DisplayNamePattern = "Gestion\sde\sla\scommunication\sInternet"
                    ParentCategory= @{
                        Name = 'System'
                        DisplayNamePattern = "Syst\xE8me"
                    }
                }
            )

            It "Test constructor method"{
                $Category -is [GPOToolsCategory] | Should be $true
                $Category.Name | Should Be $CatTab[0].Name
                $Category.DisplayName | should Match $CatTab[0].DisplayNamePattern
                $Category.ExplainText | should Match $CatTab[0].ExplainText
            }

            It "Test LoadAdmxAdml static method" {
                [GPOToolsUtility]::RemoveAll()
                [GPOToolsCategory]::LoadAdmxAdml($ADMX,$ADML)
                $LoadAdm = [GPOToolsUtility]::Categories

                $LoadAdm.Gettype().Name | Should Be 'List`1'
                $LoadAdm.Gettype().BaseType.Name | Should Be 'Object'
                for ($i = 0 ; $i -lt $CatTab.count; $i++){
                    $LoadAdm[$i].Name | Should be $CatTab[$i].Name
                    $LoadAdm[$i].DisplayName | Should Match $CatTab[$i].DisplayNamePattern
                    if($null -ne $CatTab[$i].ExplainText){
                        $LoadAdm[$i].ExplainText | Should Match $CatTab[$i].ExplainText
                    }
                    if($null -ne $CatTab[$i].ParentCategory){
                        $LoadAdm[$i].ParentCategory -is [GPOToolsCategory] | Should Be $true
                        #$LoadAdm[$i].ParentCategory.prefix | Should be $CatTab[$i].ParentCategory.prefix
                        $LoadAdm[$i].ParentCategory.Name | Should Match $CatTab[$i].ParentCategory.Name
                        $LoadAdm[$i].ParentCategory.DisplayName | Should Match $CatTab[$i].ParentCategory.DisplayNamePattern
                    }
                }
            }
        }
    }

    <#Describe "Test GPOToolsPolicy Class" {
                    $PolTab = @(
                [PscustomObject]@{
                    Name = 'AllowOnlySystemBackup'
                    Classe = 'Machine'
                    DisplayName = 'Autoriser\suniquement\sla\ssauvegarde\sdu\ssyst\xE8me'
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
                    Classe = 'Machine'
                    DisplayName = 'Ne\spas\sautoriser\sun\sp\xE9riph\xE9rique\sde\sstockage\sconnect\xE9\slocalement\s\xE0\sfaire\soffice\sde\scible\sde\ssauvegarde'
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
                    Classe = 'Machine'
                    DisplayName = 'Ne\spas\sautoriser\sun\sr\xE9seau\s\xE0\sfaire\soffice\sde\scible\sde\ssauvegarde'
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
                    Classe = 'Machine'
                    DisplayName = 'Ne\spas\sautoriser\sun\sm\xE9dia\soptique\s\xE0\sfaire\soffice\sde\scible\sde\ssauvegarde'
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
                    Classe = 'Machine'
                    DisplayName = 'Ne\spas\sautoriser\sles\ssauvegardes\s\xE0\sex\xE9cution\sunique'
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

    #>

    Describe "Test GPOToolsUtility class" {

        Context "Test static method" {
            $Culture = [cultureinfo]'fr-FR'
            $ADMXFile = Get-Item -Path "..\..\sources\PolicyDefinitions\WindowsBackup.admx"
            $ADMXPath = $ADMXFile.FullName
            $ParentPath = Split-Path -Path $ADMXPath
            $Dep1 = [GPOToolsUtility]::FindDependancyFile($ADMXPath,'Microsoft.Policies.Windows')
            $Dep2 = [GPOToolsUtility]::FindDependancyFile($ADMXPath,'Microsoft.Policies.Server')

            $AdmlPath = [GPOToolsUtility]::GetADMLPathFromADMX($ADMXFile,$Culture)
            It "Test GetADMLPathFromADMX"{
                $AdmlPath | Should be "$ParentPath\$Culture\WindowsBackup.adml"
            }

            It "Test FindDependancyFile for windows namespace"{
                $Dep1 -is [System.IO.FileInfo] | Should Be $True
                $Dep1.FullName | Should Be "$ParentPath\Windows.admx"
            }

                It "Test FindDependancyFile for WindowsServer namespace"{
                $Dep2 -is [System.IO.FileInfo] | Should Be $True
                $Dep2.FullName | Should Be "$ParentPath\WindowsServer.admx"
            }

            It "Test FindDependancyFile fail"{
                {[GPOToolsUtility]::FindDependancyFile($ADMXPath,'Microsoft.Policies.Backup')} | Should Throw "No dependancy file found for Microsoft.Policies.Backup"
            }

            It "Test RemoveAll"{
                {[GPOToolsUtility]::RemoveAll()} | Should -Not -Throw
                [GPOToolsUtility]::SupportOnTable | Should BeNullOrEmpty
                [GPOToolsUtility]::Categories | Should BeNullOrEmpty
                [GPOToolsUtility]::Policies | Should BeNullOrEmpty
                [GPOToolsUtility]::TargetLoad | Should BeNullOrEmpty
                [GPOToolsCategory]::AllParentCategory | Should BeNullOrEmpty
            }

            It "Test InitiateAdmxAdml static method"{
                $ADMXFolder = Get-Item -Path "..\..\sources\PolicyDefinitions\"
                {[GpotoolsUtility]::InitiateAdmxAdml($ADMXFolder,$Culture)} | Should -Not -Throw
            }
        }
    }
}