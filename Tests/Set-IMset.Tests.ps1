$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "Set-IMset" {
        Mock Get-IMobject {
            $obj = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject
            $obj.ResourceManagementObject = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject
            $obj.ResourceManagementObject.ObjectType = "Set"
            $attr = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementAttribute
            $attr.AttributeName = "ObjectType"
            $attr.Value = "Set"
            $null = $obj.ResourceManagementObject.ResourceManagementAttributes = (,$attr)
            $obj = $obj | Out-IMattribute
            return $obj
        } -Verifiable
        
        Context "Parameter validation" {
        $cmdlet = Get-Command -Name Get-IMset
        $ParamSetsCount = $cmdlet.ParameterSets.Count

        $MandatoryParams = $cmdlet.ParameterSets | foreach { 
                           $_.Parameters | foreach {
                           $_ | where isMandatory -eq $true } } | 
                           Select-Object -ExpandProperty Name -Unique

        $AllParams = $cmdlet.ParameterSets | foreach { 
                     $_.Parameters } |                        
                     Select-Object -ExpandProperty Name -Unique | 
                     foreach { if([System.Management.Automation.Cmdlet]::CommonParameters -notcontains $_){ $_ }
        }

        It "DisplayName parameter should exist" {
            $AllParams -contains "DisplayName" | Should Be $true
        }

        It "Credential parameter should exist" {
            $AllParams -contains "Credential" | Should Be $true
        }

        It "uri parameter should exist" {
            $AllParams -contains "uri" | Should Be $true
        }

        It "ObjectID parameter should exist" {
            $AllParams -contains "ObjectID" | Should Be $true
        }

        It "DisplayName parameter should exist in ParameterSet 'ByDisplayName'" {
            { $cmdlet.ResolveParameter("DisplayName").Parametersets["ByDisplayName"] } | Should not Be $null
        }
        It "Credential parameter should exist in ParameterSet 'ByDisplayName'" {
            { $cmdlet.ResolveParameter("Credential").Parametersets["ByDisplayName"] } | Should not Be $null
        }
        It "uri parameter should exist in ParameterSet 'ByDisplayName'" {
            { $cmdlet.ResolveParameter("uri").Parametersets["ByDisplayName"] } | Should not Be $null
        }

        It "Credential parameter should exist in ParameterSet 'ByObjectID'" {
            { $cmdlet.ResolveParameter("Credential").Parametersets["ByObjectID"] } | Should not Be $null
        }
        It "uri parameter should exist in ParameterSet 'ByObjectID'" {
            { $cmdlet.ResolveParameter("uri").Parametersets["ByObjectID"] } | Should not Be $null
        }
        It "ObjectID parameter should exist in ParameterSet 'ByObjectID'" {
            { $cmdlet.ResolveParameter("ObjectID").Parametersets["ByObjectID"] } | Should not Be $null
        }
   }

    Context "Parameter logic validation" {
        Mock Import-FIMConfig { $null } -Verifiable
        Mock Get-IMset {
            $obj = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject
            $obj.ResourceManagementObject = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject
            $obj.ResourceManagementObject.ObjectType = "Set"
            $attr = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementAttribute
            $attr.AttributeName = "ObjectType"
            $attr.Value = "Set"
            $null = $obj.ResourceManagementObject.ResourceManagementAttributes = (,$attr)
            $obj = $obj | Out-IMattribute
            return $obj
        } -Verifiable

        It "No parameters should throw" {
            { Set-IMset } | Should throw
        }

        It "Should NOT throw if both DisplayName and ObjectID is given" {
            { Set-IMset -DisplayName "dummy set" -ObjectID "notpossibletoday"  } | Should Not throw
        }

        It "Should throw if only DisplayName is given" {
            { Set-IMset -DisplayName "yall" } | Should throw
        }

        It "Should throw if only ObjectID is given" {
            { Set-IMset -ObjectID "yall" } | Should throw
        }
    }

    Context "Adding credentials" {
        Mock Import-FIMConfig { $null } -Verifiable
            
        Mock Get-IMset {
            $obj = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject
            $obj.ResourceManagementObject = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject
            $obj.ResourceManagementObject.ObjectType = "Set"
            $attr = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementAttribute
            $attr.AttributeName = "ObjectType"
            $attr.Value = "Set"
            $null = $obj.ResourceManagementObject.ResourceManagementAttributes = (,$attr)
            $obj = $obj | Out-IMattribute
            return $obj
        } -Verifiable
        
        $cred = [System.Management.Automation.PSCredential]::Empty

        It "No credentials should not throw" {
            { Set-IMset -DisplayName "yalla" -ObjectId myguid } | Should Not throw
        }

        It "Should only call Get-IMset once" {
            Assert-MockCalled Get-IMset -Exactly 1
        }

        It "With credentials should not throw" {
            { Set-IMset -DisplayName "yalla" -ObjectId myguid -Credential $cred } | Should Not throw
        }        
    }

    Context "Added URI should be forwareded" {
        $uri = "http://imserver"
        Mock Import-FIMConfig { return $uri } -Verifiable
        
        Mock Get-IMset {
            $obj = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject
            $obj.ResourceManagementObject = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject
            $obj.ResourceManagementObject.ObjectType = "Set"
            $attr = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementAttribute
            $attr.AttributeName = "ObjectType"
            $attr.Value = "Set"
            $null = $obj.ResourceManagementObject.ResourceManagementAttributes = (,$attr)
            $obj = $obj | Out-IMattribute
            return $obj
        } -Verifiable
        
        #Mock Write-Warning {$null}
        
        $testuri =  Set-IMset -DisplayName yalla -ObjectId myguid -uri $uri -Commit -WarningAction SilentlyContinue -WarningVariable warn

        It "Should return an object" {
            $testuri | Should not be $null
        }

        It "Should be of type string" {
            $testuri.GetType().Name | Should be "String"
        }

        It "Should have value '$uri'" {
            $testuri | should be $uri
        }
        
        It "Should raise a warning" {
            $warn | Should Not Be $null
        }
        
        It "Should raise a warning with message" {
            $warn | Should Be "Set-IMset - Import-FIMconfig returned objects that need your attention"
        }
    }
}
Remove-Module fimmodule



