#cd C:\Users\Tore\Dropbox\SourceTreeRepros\powerfim -ErrorAction SilentlyContinue
$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "Get-IMobject" {
    Context "Parameter validation" {

        Mock Export-FIMConfig {$null}

        It "No parameters should throw" {
            { Get-IMobject } | Should throw
        }

        It "No parameters should throw with message" {
            { Get-IMobject } | Should throw "Parameter set cannot be resolved using the specified named parameters"
        }

        It "Only Xpath parameter should not throw" {
            { Get-IMobject -Xpath "/AttributeTypeDescription[Name = 'DisplayName']" } | Should not throw
        }

        It "Build xpath parameterset should not throw" {
            { Get-IMobject -ResourceType AttributeTypeDescription -Attribute "Name" -AttributeValue "DisplayName" } | Should not throw
        }

        It "Build xpath parameterset should retun an object" {
            { Get-IMobject -ResourceType AttributeTypeDescription -Attribute "Name" -AttributeValue "DisplayName" } | Should not be null
        }
        
        It "Only ResourceType should not trow" {
            { Get-IMobject -ResourceType Person } | Should Not throw
        }

        It "Should throw if xpath paramter is used with Attribute parameter" {
            { Get-IMobject -Xpath "/yalla" -Attribute "dummy" } | Should throw
        }

        It "Should throw if xpath paramter is used with Attribute parameter with message" {
            { Get-IMobject -Xpath "/yalla" -Attribute "dummy" } | Should throw "Parameter set cannot be resolved using the specified named parameters."
        }

        It "Should throw if xpath paramter is used with AttributeValue parameter" {
            { Get-IMobject -Xpath "/yalla" -AttributeValue "dummy" } | Should throw
        }

        It "Should throw if xpath paramter is used with AttributeValue parameter with message" {
            { Get-IMobject -Xpath "/yalla" -AttributeValue "dummy" } | Should throw "Parameter set cannot be resolved using the specified named parameters."
        }

        It "Should throw if xpath paramter is used with ResourceType parameter" {
            { Get-IMobject -Xpath "/yalla" -ResourceType Approval } | Should throw
        }
    }

    Context "Mock Export-FIMConfig" {
        Mock Export-FIMConfig { $null } 
              
            It "Object was not found should not throw" {                           
                { Get-IMobject -Xpath "yalla" } | Should not throw
            }

            It "Object was not found should equal null" {
                Get-IMobject -Xpath "yall" | Should Be $null
            }

            It "Should not throw if ResourceType ActivityInformationConfiguration is specified" {
                { Get-IMobject -ResourceType ActivityInformationConfiguration } | Should not throw
            }

            It "Should not throw if ResourceType * is specified" {
                { Get-IMobject -ResourceType * } | Should not throw
            }

            It "Should not throw if ResourceType Approval is specified" {
                { Get-IMobject -ResourceType Approval } | Should not throw
            }

            It "Should not throw if ResourceType AttributeTypeDescription is specified" {
                { Get-IMobject -ResourceType AttributeTypeDescription } | Should not throw
            }

            It "Should not throw if ResourceType BindingDescription is specified" {
                { Get-IMobject -ResourceType BindingDescription } | Should not throw
            }

            It "Should not throw if ResourceType DetectedRuleEntry is specified" {
                { Get-IMobject -ResourceType DetectedRuleEntry } | Should not throw
            }

            It "Should not throw if ResourceType Group is specified" {
                { Get-IMobject -ResourceType Group } | Should not throw
            }

            It "Should not throw if ResourceType ManagementPolicyRule is specified" {
                { Get-IMobject -ResourceType ManagementPolicyRule } | Should not throw
            }

            It "Should not throw if ResourceType ObjectTypeDescription is specified" {
                { Get-IMobject -ResourceType ObjectTypeDescription } | Should not throw
            }

            It "Should not throw if ResourceType Person is specified" {
                { Get-IMobject -ResourceType Person } | Should not throw
            }

            It "Should not throw if ResourceType Request is specified" {
                { Get-IMobject -ResourceType Request } | Should not throw
            }

            It "Should not throw if ResourceType Resource is specified" {
                { Get-IMobject -ResourceType Resource } | Should not throw
            }

            It "Should not throw if ResourceType Set is specified" {
                { Get-IMobject -ResourceType Set } | Should not throw
            }

            It "Should not throw if ResourceType SynchronizationRule is specified" {
                { Get-IMobject -ResourceType SynchronizationRule } | Should not throw
            }

            It "Should not throw if ResourceType WorkflowDefinition is specified" {
                { Get-IMobject -ResourceType WorkflowDefinition } | Should not throw
            }
    }

    Context "Adding credentials" {
        Mock Export-FIMConfig {$null}
        $cred = [System.Management.Automation.PSCredential]::Empty

        It "Adding credentials should not throw" {
            { Get-IMobject -Xpath "/yall" -Credential $cred } | Should Not throw
        }
    }

    Context "Variable in global scope does not exist" {
        
        Mock Export-FIMConfig { $true } -Verifiable
        Mock Set-Variable {} -Verifiable
        
        $testObj = Get-IMobject -Attribute name -ResourceType Person -AttributeValue "Yalla"

        It "Should call Set-Variable once" {
            Assert-MockCalled Set-Variable -Exactly 1
        }

        It "Should create an Global Variable if an object was found" {            
            { Get-Variable -Name FIMresultObject -Scope Global } | should not be $null
        }       
    }

    Context "Running wildcard search" {
        Mock Export-FIMConfig {
                Param([string[]]$CustomConfig) 
                If($CustomConfig[0].contains("%")){
                    $true
                }
                else {
                    $false
                }
        }
             
        It "If AttributeValue contains * it should run a wildcard search" {
            Get-IMobject -Attribute Name -ResourceType Person -AttributeValue "yalla*" | Should be $true
        }

        It "If AttributeValue does not contains * it should run a regular search" {
            Get-IMobject -Attribute Name -ResourceType Person -AttributeValue "yalla" | Should be $false
        }
    }
}

Remove-Module -Name FIMmodule



