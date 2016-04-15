cd C:\Users\Tore\Dropbox\SourceTreeRepros\powerfim -ErrorAction SilentlyContinue
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$PSBoundParameters.clear()

Import-module .\PowerFIM.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

Describe "Get-FIMobject" {
    Context "Parameter validation" {

        Mock Export-FIMConfig {$null}

        It "No parameters should throw" {
            { Get-FIMobject } | Should throw
        }

        It "No parameters should throw with message" {
            { Get-FIMobject } | Should throw "Parameter set cannot be resolved using the specified named parameters"
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
        
        It "Only ResourceType should not trow" {
            { Get-FIMobject -ResourceType Person } | Should Not throw
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

    Context "Mock Export-FIMConfig" {
        Mock Export-FIMConfig { $null } 
              
            It "Object was not found should not throw" {                           
                { Get-FIMobject -Xpath "yalla" } | Should not throw
            }

            It "Object was not found should equal null" {
                Get-FIMobject -Xpath "yall" | Should Be $null
            }

            It "Should not throw if ResourceType ActivityInformationConfiguration is specified" {
                { Get-FIMobject -ResourceType ActivityInformationConfiguration } | Should not throw
            }

            It "Should not throw if ResourceType * is specified" {
                { Get-FIMobject -ResourceType * } | Should not throw
            }

            It "Should not throw if ResourceType Approval is specified" {
                { Get-FIMobject -ResourceType Approval } | Should not throw
            }

            It "Should not throw if ResourceType AttributeTypeDescription is specified" {
                { Get-FIMobject -ResourceType AttributeTypeDescription } | Should not throw
            }

            It "Should not throw if ResourceType BindingDescription is specified" {
                { Get-FIMobject -ResourceType BindingDescription } | Should not throw
            }

            It "Should not throw if ResourceType DetectedRuleEntry is specified" {
                { Get-FIMobject -ResourceType DetectedRuleEntry } | Should not throw
            }

            It "Should not throw if ResourceType Group is specified" {
                { Get-FIMobject -ResourceType Group } | Should not throw
            }

            It "Should not throw if ResourceType ManagementPolicyRule is specified" {
                { Get-FIMobject -ResourceType ManagementPolicyRule } | Should not throw
            }

            It "Should not throw if ResourceType ObjectTypeDescription is specified" {
                { Get-FIMobject -ResourceType ObjectTypeDescription } | Should not throw
            }

            It "Should not throw if ResourceType Person is specified" {
                { Get-FIMobject -ResourceType Person } | Should not throw
            }

            It "Should not throw if ResourceType Request is specified" {
                { Get-FIMobject -ResourceType Request } | Should not throw
            }

            It "Should not throw if ResourceType Resource is specified" {
                { Get-FIMobject -ResourceType Resource } | Should not throw
            }

            It "Should not throw if ResourceType Set is specified" {
                { Get-FIMobject -ResourceType Set } | Should not throw
            }

            It "Should not throw if ResourceType spvOrganizationalUnit is specified" {
                { Get-FIMobject -ResourceType spvOrganizationalUnit } | Should not throw
            }

            It "Should not throw if ResourceType SynchronizationRule is specified" {
                { Get-FIMobject -ResourceType SynchronizationRule } | Should not throw
            }

            It "Should not throw if ResourceType WorkflowDefinition is specified" {
                { Get-FIMobject -ResourceType WorkflowDefinition } | Should not throw
            }
    }

    Context "Adding credentials" {
        Mock Export-FIMConfig {$null}
        $cred = [System.Management.Automation.PSCredential]::Empty

        It "Adding credentials should not throw" {
            { Get-FIMobject -Xpath "/yall" -Credential $cred } | Should Not throw
        }
    }

    Context "Variable in global scope does not exist" {
        
        Mock Export-FIMConfig { $true } -Verifiable
        Mock Set-Variable {} -Verifiable
        
        $testObj = Get-FIMobject -Attribute name -ResourceType Person -AttributeValue "Yalla" -verbose

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
            Get-FIMobject -Attribute Name -ResourceType Person -AttributeValue "yalla*" | Should be $true
        }

        It "If AttributeValue does not contains * it should run a regular search" {
            Get-FIMobject -Attribute Name -ResourceType Person -AttributeValue "yalla" | Should be $false
        }
    }
}

Remove-Module -Name FIMmodule



