$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false


Describe "Get-IMPersonMembership" {
    Context "Parameter validation" {
        Mock Get-IMobject {$null}

        It "No parameters should throw" {
            { Get-IMPersonMembership } | Should throw
        }
    }

    Context "Adding credentials" {        
        $cred = [System.Management.Automation.PSCredential]::Empty
        Mock Get-IMobject {return $credential}
        It "Adding credentials should not throw" {
            { Get-IMPersonMembership -Credential $cred -ObjectID myguid } | Should Not throw
        }
        
        It "Should call Get-IMobject" {
            Assert-MockCalled Get-IMObject
        }
    }
}

Remove-Module fimmodule



