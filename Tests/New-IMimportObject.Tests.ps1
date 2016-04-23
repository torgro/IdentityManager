$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "New-IMimportObject" {

    Context "Parameter validation" {
        $cmdlet = Get-Command -Name New-IMimportObject
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

        It "ObjectType parameter should exist" {
            $AllParams -contains "ObjectType" | Should Be $true
        }

        It "ObjectType parameter should be Mandatory" {
             $MandatoryParams -contains "ObjectType" | Should Be $true
        }

        It "ImportState parameter should exist" {
            $AllParams -contains "ImportState" | Should Be $true
        }

        It "ImportState parameter should be Mandatory" {
             $MandatoryParams -contains "ImportState" | Should Be $true
        }

        It "ObjectType parameter should exist in ParameterSet '__AllParameterSets'" {
            { $cmdlet.ResolveParameter("ObjectType").Parametersets["__AllParameterSets"] } | Should not Be $null
        }
        It "ImportState parameter should exist in ParameterSet '__AllParameterSets'" {
            { $cmdlet.ResolveParameter("ImportState").Parametersets["__AllParameterSets"] } | Should not Be $null
        }
    }

    Context "Testing output object" {

        $ObjectType = "BindingDescription"
        $ImpState = "Create"

        $impObj = New-IMimportObject -ObjectType $ObjectType -ImportState $ImpState

        It "ImportObject should not be 'null'" {
            { $impObj } | Should not be $null
        }

        It "Import object state should be '$ImpState'" {
            $impObj.State | Should be $ImpState
        }

        It "Import object ObjectType should be '$ObjectType'" {
            $impObj.ObjectType | Should be $ObjectType
        }

        It "Import object should have 'one' change" {
            $impObj.Changes.Count | Should be 0
        }
        
        It "Import object SourceObjectIdentifier should not be null" {
            $impObj.SourceObjectIdentifier | Should not be $null
        }       
    }
}
Remove-Module fimmodule



