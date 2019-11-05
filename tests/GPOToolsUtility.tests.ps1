using module '..\PSGPOTool\Classes\GPOToolsUtility.psm1'

$TestPath = Split-Path $MyInvocation.MyCommand.Path

Push-Location -Path $TestPath
Set-Location -Path $TestPath

#Describe "Test AdmxSupportedOn class"
#Describe "Test AdmxNamespace class"
#Describe "Test AdmxCategory class"
#Describe "Test AdmxPolicy class"

Describe "Test GpoToolsAdmx class" {
    Context "Test constructor method for Admx WindowsBackup" {
        $ADMXPath = (Get-Item -Path "..\sources\PolicyDefinitions\WindowsBackup.admx").FullName
        $ADMX = [GPOToolsAdmx]::New($ADMXPath)
        $UsingTab = @(
            [pscustomobject]@{
                prefix = 'backup'
                namespace = 'Microsoft.Policies.Backup'
            },
            [pscustomobject]@{
                prefix = 'windows'
                namespace = 'Microsoft.Policies.Windows'
            }
        )
        $CatTab = @(
            [PscustomObject]@{
                Name = 'Backup'
                DisplayName = 'Backup'
                ParentCategoryName = 'windows:WindowsComponents'
            },
            [PscustomObject]@{
                Name = 'BackupServer'
                DisplayName = 'BackupServer'
                ParentCategoryName = 'backup:Backup'
            }
        )
        It "Test object type"{
            $ADMX -is [GPOToolsAdmx] | Should be $true
        }

        It "Test FilePath property"{
            $ADMX.FilePath -is [string] | Should be $true
            $ADMX.FilePath | Should be $ADMX.Path
        }

        It "Test BaseName Property"{
            $ADMX.BaseName -is [string] | Should be $true
            $ADMX.BaseName | Should be "WindowsBackup"
        }

        It "Test Target Property" {
            $ADMX.Target -is [AdmxNamespace] | Should be $true
            $ADMX.Target.prefix | Should be 'windowsbackup'
            $ADMX.Target.Namespace | Should be 'Microsoft.Policies.WindowsBackup'
        }

        It "Test Using Property" {
            $ADMX.Using -is [System.Collections.ArrayList] | Should be $true
            $ADMX.Using.count | Should be 2
            for ($i = 0 ; $i -lt $ADMX.Using.count; $i++){
                $ADMX.Using[$i] -is [AdmxNamespace] | should be $true
                $ADMX.Using[$i].prefix | Should be $UsingTab[$i].prefix
                $ADMX.Using[$i].namespace | Should be $UsingTab[$i].namespace
            }
        }

        It "Test SupportedOnDefinition" {
            $ADMX.SupportedOnDefinition -is [System.Collections.ArrayList] | Should be $true
            $ADMX.SupportedOnDefinition.count -eq 0 | Should be $true
        }

        It "Test Category" {
            $ADMX.Categories -is [System.Collections.ArrayList] | Should be $true
            $ADMX.Categories.count | Should be 2
            for ($i = 0 ; $i -lt $ADMX.Categories.count; $i++){
                $ADMX.Categories[$i].Name | Should be $CatTab[$i].Name
                $ADMX.Categories[$i].DisplayName | Should be $CatTab[$i].DisplayName
                $ADMX.Categories[$i].ParentCategoryName | Should be $CatTab[$i].ParentCategoryName
                #$ADMX.Categories[$i].ExplainText
            }
        }

        #It "Test policy"
    }

    Context "Test constructor method for Admx WindowsUpdate" {
        $ADMXPath = (Get-Item -Path "..\sources\PolicyDefinitions\WindowsUpdate.admx").FullName
        $ADMX = [GPOToolsAdmx]::New($ADMXPath)
        $UsingTab = @(
            [pscustomobject]@{
                prefix = 'windows'
                namespace = 'Microsoft.Policies.Windows'
            }
        )
        $TabSupportedOny = @(
            [pscustomobject]@{
                Name = 'WU_SUPPORTED_Windows7_Or_Win81Update'
                DisplayName = 'WU_SUPPORTED_Windows7_Or_Win81Update'
            }
        )
        $CatTab = @(
            [Pscustomobject]@{
                Name = 'WindowsUpdateCat'
                DisplayName = 'WindowsUpdateCat'
                ParentCategoryName = 'windows:WindowsComponents'
            }
        )
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
            $ADMX.Using.count | Should be 1
            for ($i = 0 ; $i -lt $ADMX.Using.count; $i++){
                $ADMX.Using[$i] -is [AdmxNamespace] | should be $true
                $ADMX.Using[$i].prefix | Should be $UsingTab[$i].prefix
                $ADMX.Using[$i].namespace | Should be $UsingTab[$i].namespace
            }
        }

        It "Test SupportedOnDefinition"{
            $ADMX.SupportedOnDefinition -is [System.Collections.ArrayList] | Should be $true
            $ADMX.SupportedOnDefinition.count -eq 1 | Should be $true
            for ($i = 0 ; $i -lt $ADMX.SupportedOnDefinition.count; $i++){
                $ADMX.SupportedOnDefinition[$i].Name | Should be $TabSupportedOny[$i].Name
                $ADMX.SupportedOnDefinition[$i].DisplayName | Should be $TabSupportedOny[$i].DisplayName
            }
        }

        It "Test Category" {
            $ADMX.Categories -is [System.Collections.ArrayList] | Should be $true
            $ADMX.Categories.count | Should be 1
            for ($i = 0 ; $i -lt $ADMX.Categories.count; $i++){
                $ADMX.Categories[$i].Name | Should be $CatTab[$i].Name
                $ADMX.Categories[$i].DisplayName | Should be $CatTab[$i].DisplayName
                $ADMX.Categories[$i].ParentCategoryName | Should be $CatTab[$i].ParentCategoryName
                #$ADMX.Categories[$i].ExplainText
            }
        }

        #It "Test policy"
    }
}

#Describe "Test GPOToolsADML class"

Describe "Test GPOToolsUtility class" {
    Context "Test static method" {
        $ADMXFile = Get-Item -Path "..\sources\PolicyDefinitions\WindowsBackup.admx"
        $ADMXPath = $ADMXFile.FullName
        $ADMX = [GPOToolsAdmx]::New($ADMXPath)
        $Dep1 = [GPOToolsUtility]::FindDependancyFile($ADMXPath,'Microsoft.Policies.Windows')
        $Dep2 = [GPOToolsUtility]::FindDependancyFile($ADMXPath,'Microsoft.Policies.Backup')

        $AdmlPath = [GPOToolsUtility]::GetADMLPathFromADMX($ADMXFile,[cultureinfo]::CurrentCulture)
        It "Test GetADMLPathFromADMX"{
            $AdmlPath | Should be "$Env:windir\PolicyDefinitions\$([cultureinfo]::CurrentCulture)\WindowsBackup.adml"
        }

        It "Test FindDependancyFile"{
            $Dep1 -is [System.IO.FileInfo] | Should Be $True
            $Dep1.FullName | Should Be "$Env:windir\PolicyDefinitions\Windows.admx"

            $Dep2 -is [System.IO.FileInfo] | Should Be $True
            $Dep2.FullName | Should Be "$Env:windir\PolicyDefinitions\UserDataBackup.admx"
        }

        It "Test RemoveAll"{
            [GPOToolsUtility]::RemoveAll()
            $null -eq [GPOToolsUtility]::SupportOnTable | Should Be $true
            $null -eq [GPOToolsUtility]::Categories | Should Be $true
            $null -eq [GPOToolsUtility]::Policies | Should Be $true
            $null -eq [GPOToolsUtility]::TargetLoad | Should Be $true
        }
    }
}