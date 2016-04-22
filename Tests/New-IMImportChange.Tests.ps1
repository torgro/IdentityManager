$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "New-IMImportChange" {

    Context "Parameter validation" {

    $cmdlet = Get-Command -Name New-IMImportChange
    $ParamSetsCount = $cmdlet.ParameterSets.Count
    $MandatoryParams = $cmdlet.ParameterSets | foreach { $_.Parameters | foreach {$_ | where isMandatory -eq $true } } | Select-Object -ExpandProperty Name
    
        It "AttributeName parameter should be mandatory" {
             $MandatoryParams -contains "AttributeName" | Should Be $true
        }

        It "AttributeValue parameter should be mandatory" {
             $MandatoryParams -contains "AttributeValue" | Should Be $true
        }

        It "Parameters sets should be equal to 1" {
            $ParamSetsCount | Should Be 1
        }

        It "Count of Mandatory parameters should be 2" {
            $MandatoryParams.Count | Should Be 2
        }
    }

    Context "Testing object with defaults" {
        $AttribName = "DisplayName"
        $AttribValue = "Say my name"

        $change = New-IMImportChange -AttributeName $AttribName -AttributeValue $AttribValue

        It "Should not be null" {
            { $change } | Should not be $null
        }
        
        It "Operation should be 'add' by default" {
            $change.Operation | Should be "Add"
        }

        It "AttributeName should be '$AttribName'" {
            $change.AttributeName | Should be "$AttribName"
        }

        It "AttributeValue should be '$AttribValue'" {
            $change.AttributeValue | Should be "$AttribValue"
        }

        It "FullyResolved should be '$true' by default" {
            $change.FullyResolved | Should be $true
        }

        It "Locale should be 'Invariant' by default" {
            $change.Locale | Should be "Invariant"
        }
    }

    Context "Testing object without defaults" {
        
        $AttribName = "DisplayName"
        $AttribValue = "Say my name"
        $FullyRes = $true
        $locale = "dummy"
        $operation = "None"

        $change = New-IMImportChange -AttributeName $AttribName -AttributeValue $AttribValue -FullyResolved $FullyRes -Locale $locale -Operation $operation

        It "Should not be null" {
            { $change } | Should not be $null
        }

        It "Operation should be '$operation'" {
            $change.Operation | Should be $operation
        }

        It "AttributeName should be '$AttribName'" {
            $change.AttributeName | Should be "$AttribName"
        }

        It "AttributeValue should be '$AttribValue'" {
            $change.AttributeValue | Should be "$AttribValue"
        }

        It "FullyResolved should be '$FullyRes'" {
            $change.FullyResolved | Should be $FullyRes
        }

        It "Locale should be '$locale'" {
            $change.Locale | Should be "$locale"
        }
    }
}
Remove-Module fimmodule



