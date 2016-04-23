$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "Set-IMsetUsage" {              
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
        Mock Get-IMSet { return [PSCustomObject]@{ObjectId = [guid]::NewGuid()} } -Verifiable
       
       Mock Get-IMobject { return $null } -Verifiable
       
        It "No parameters should throw" {
            { Get-IMsetUsage } | Should throw
        }

        It "Should throw if both DisplayName and ObjectID is given" {
            { Get-IMsetUsage -DisplayName "dummy set" -ObjectID "notpossibletoday"  } | Should throw
        }

        It "Should NOT throw if only DisplayName is given" {
            { Get-IMsetUsage -DisplayName "yall" } | Should Not throw
        }

        It "Should NOT throw if only ObjectID is given" {
            { Get-IMsetUsage -ObjectID "yall" } | Should Not throw
        }
        
        It "Should calld Get-IMset twice" {
            Assert-MockCalled Get-IMset -Exactly 2
        }
        
        It "Should call Get-IMobject twice" {
            Assert-MockCalled Get-IMobject -Exactly 2
        }
    }

    Context "Adding credentials" {
        Mock Get-IMSet { [PSCustomObject]@{ObjectId = [guid]::NewGuid()} } -Verifiable
        
        Mock Get-IMobject { return $null } -Verifiable
        
        $cred = [System.Management.Automation.PSCredential]::Empty

        It "No credentials should not throw" {
            { Get-IMsetUsage -DisplayName "yalla" } | Should Not throw
        }

        It "Should only call Get-IMSet once" {
            Assert-MockCalled Get-IMSet -Exactly 1
        }

        It "With credentials should not throw" {
            { Get-IMsetUsage -ObjectId myguid -Credential $cred } | Should Not throw
        }        
    }

    Context "Added URI should be forwareded" {
        $uri = "http://imserver"
        Mock Get-IMSet { [PSCustomObject]@{ObjectId = [guid]::NewGuid()} } -Verifiable
        
        Mock Get-IMobject { return $uri } -Verifiable
        
        $testuri =  Get-IMsetUsage -DisplayName yalla -uri $uri

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
}
Remove-Module fimmodule



