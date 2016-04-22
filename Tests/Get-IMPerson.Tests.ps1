$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false


Describe "Get-IMPerson" {
    Context "Parameter validation" {
        Mock Get-IMobject {$null}

        It "No parameters should not throw" {
            { Get-IMPerson } | Should not throw
        }
    }

    Context "Adding credentials" {        
        $cred = [System.Management.Automation.PSCredential]::Empty
        Mock Get-IMobject {$null}
        It "Adding credentials should not throw" {
            { Get-IMPerson -Credential $cred } | Should Not throw
        }
    }

    Context "Running wildcard search" {
        
        Mock Get-IMobject {
            $ReturnObj = [pscustomobject]@{Name = "Yallabaloo"}
            return $ReturnObj
        }
             
        It "If AttributeValue contains * it should run a wildcard search" {
            $Person = Get-IMPerson -Attribute Name -AttributeValue "yalla*"
            $Person.Name -like "yalla*" | should be $true
        }

        It "If AttributeValue does not contains * it should run a regular search" {
            $Person = Get-IMPerson -Attribute Name -AttributeValue "Yallabaloo"
            $Person.Name -eq "Yallabaloo" | should be $true
        }
    }
}

Remove-Module fimmodule



