$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "Get-IMset" {

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
        
        It "Attribute parameter should exist" {
            $AllParams -contains "Attribute" | Should Be $true
        }
        
        It "AttributeValue parameter should exist" {
            $AllParams -contains "AttributeValue" | Should Be $true
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
        Mock Get-IMobject { $null } -Verifiable

        It "No parameters should throw" {
            { Get-IMset } | Should throw
        }

        It "Should throw if both DisplayName and ObjectID is given" {
            { Get-IMset -DisplayName "dummy set" -ObjectID "notpossibletoday"  } | Should throw
        }
        
        It "Should trow if Attribute and DisplayName is given" {
            { Get-IMset -Attribute Balle -DisplayName "Testset"} | should throw
        }

        It "Should NOT throw if DisplayName is given" {
            { Get-IMset -DisplayName "yall" } | Should not throw
        }

        It "Should NOT throw if ObjectID is given" {
            { Get-IMset -ObjectID "yall" } | Should not throw
        }
    }

    Context "Adding credentials" {
        
        Mock Get-IMobject { $null } -Verifiable 

        $cred = [System.Management.Automation.PSCredential]::Empty

        It "No credentials should not throw" {
            { Get-IMset -DisplayName "yalla" } | Should Not throw
        }

        It "Should only call Get-FIMobject once" {
            Assert-MockCalled Get-IMobject -Exactly 1
        }

        It "With credentials should not throw" {
            { Get-IMset -DisplayName "yalla" -Credential $cred} | Should Not throw
        }        
    }

    Context "Added credentials should be forwarded" {
        Mock Get-IMobject {return $Credential} -Verifiable

        $cred = [System.Management.Automation.PSCredential]::Empty

        $testcred = Get-IMset -DisplayName yalla -Credential $cred

        It "Should return an object" {
            $testcred | Should not be $null
        }

        It "Should be of type PScredential" {
            $testcred -is [PScredential] | should be $true
        }
    }

    Context "Added URI should be forwareded" {
        Mock Get-IMobject {return $uri} -Verifiable
        $uri = "http://imserver"

        $testuri =  Get-IMset -DisplayName yalla -uri $uri

        It "Should return an object" {
            $testuri | Should not be $null
        }

        It "Should be of type string" {
            $testuri.GetType().Name | Should be "String"
        }

        It "Should have value '$uri'" {
            $testuri | should be $uri
        }
    }

    Context "Mock Get-IMobject with data" {
       
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
        }

        $result = Get-IMset -DisplayName "yall"

        It "Should return an PSCustomObject" {
            $result -is [PSCustomObject] | Should Be $true
        }
        It "ObjectType should be set" {                
            $result.ObjectType -eq "Set" | Should be $true
        }
    }

    Context "Mock Get-IMobject return null" {
        
        Mock Get-IMobject { $null }

        $result = Get-IMset -DisplayName "yall"

        It "Should be equal to null" {                
            $result | Should Be $null
        }

        It "Should not throw" {                
            { Get-IMset -DisplayName "yall" } | Should not throw
        }

    }
}
Remove-Module fimmodule



