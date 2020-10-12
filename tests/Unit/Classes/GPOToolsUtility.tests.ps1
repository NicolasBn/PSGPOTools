
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