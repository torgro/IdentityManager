$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false


Describe "Get-IMSecurityGroup" {
    Context "Parameter validation" {
        Mock Get-IMobject {$null}

        It "No parameters should not throw" {
            { Get-IMSecurityGroup } | Should not throw
        }
    }

    Context "Adding credentials" {        
        $cred = [System.Management.Automation.PSCredential]::Empty
        Mock Get-IMobject {$cred}
        It "Adding credentials should not throw" {
            { Get-IMSecurityGroup -Credential $cred } | Should Not throw
        }
    }

    Context "Running wildcard search" {
        
        Mock Get-IMobject {
            $ReturnObj = [pscustomobject]@{Name = "Yallabaloo"}
            return $ReturnObj
        }
             
        It "If AttributeValue contains * it should run a wildcard search" {
            $Group = Get-IMSecurityGroup -DisplayName "yalla*"
            $Group.Name -like "yalla*" | should be $true
        }
        
        $Group = $null
        It "If AttributeValue does not contains * it should run a regular search" {
            $Group = Get-IMSecurityGroup -DisplayName "Yallabaloo"
            $Group.Name -eq "Yallabaloo" | should be $true
        }
    }
}

Remove-Module fimmodule



