cd C:\Users\Tore\Dropbox\SourceTreeRepros\powerfim -ErrorAction SilentlyContinue
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$PSBoundParameters.clear()

import-module .\PowerFIM.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false


#FIXME
Describe "Get-FIMPerson" {
    Context "Parameter validation" {

        Mock Get-FIMobject {$null}

        It "No parameters should not throw" {
            { Get-FIMPerson } | Should not throw
        }

        It "Only Xpath parameter should not throw" {
            { Get-FIMobject -Xpath "/AttributeTypeDescription[Name = 'DisplayName']" } | Should not throw
        }

        It "Build xpath parameterset should not throw" {
            { Get-FIMobject -ResourceType AttributeTypeDescription -Attribute "Name" -AttributeValue "DisplayName" } | Should not throw
        }

        It "Build xpath parameterset should retun an object" {
            { Get-FIMobject -ResourceType AttributeTypeDescription -Attribute "Name" -AttributeValue "DisplayName" } | Should not be null
        }

        It "Should throw if xpath paramter is used with Attribute parameter" {
            { Get-FIMobject -Xpath "/yalla" -Attribute "dummy" } | Should throw
        }

        It "Should throw if xpath paramter is used with Attribute parameter with message" {
            { Get-FIMobject -Xpath "/yalla" -Attribute "dummy" } | Should throw "Parameter set cannot be resolved using the specified named parameters."
        }

        It "Should throw if xpath paramter is used with AttributeValue parameter" {
            { Get-FIMobject -Xpath "/yalla" -AttributeValue "dummy" } | Should throw
        }

        It "Should throw if xpath paramter is used with AttributeValue parameter with message" {
            { Get-FIMobject -Xpath "/yalla" -AttributeValue "dummy" } | Should throw "Parameter set cannot be resolved using the specified named parameters."
        }

        It "Should throw if xpath paramter is used with ResourceType parameter" {
            { Get-FIMobject -Xpath "/yalla" -ResourceType Approval } | Should throw
        }
    }

    Context "Adding credentials" {
        
        $cred = [System.Management.Automation.PSCredential]::Empty

        It "Adding credentials should not throw" {
            { Get-FIMPerson -Credential $cred } | Should Not throw
        }
    }

    Context "Running wildcard search" {
        
        Mock Get-FIMobject {
            $ReturnObj = [pscustomobject]@{Name = "Yallabaloo"}
            return $ReturnObj
        }
             
        It "If AttributeValue contains * it should run a wildcard search" {
            $Person = Get-FIMPerson -Attribute Name -AttributeValue "yalla*"
            $Person.Name -like "yalla*" | should be $true
        }

        It "If AttributeValue does not contains * it should run a regular search" {
            $Person = Get-FIMPerson -Attribute Name -AttributeValue "Yallabaloo"
            $Person.Name -eq "Yallabaloo" | should be $true
        }
    }
}

Remove-Module fimmodule



