$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false


Describe "Get-IMObjectMember" {
    Context "Parameter validation" {
        Mock Get-IMobject {$null}

        It "No parameters should throw" {
            { Get-IMObjectMember } | Should throw
        }
    }

    Context "Adding credentials" {        
        $cred = [System.Management.Automation.PSCredential]::Empty
        Mock Get-IMobject {
            return [pscustomobject]@{
                ObjectType = "Set"
                Cred = $Credential
            }
        }
        
        Mock Get-IMXPathQuery { $null }
        
        Mock ConvertTo-GUID {Return $inputobject}
        
        It "Adding credentials should not throw" {
            { Get-IMObjectMember -ObjectId myguid -Credential $cred -ObjectType Set } | Should Not throw
        }
        
        $GetObjectMember = Get-IMObjectMember -ObjectId myguid -Credential $cred -ObjectType Set 
        
        It "Should forward the Credential object" {
            $GetObjectMember.Cred | Should Not Be $null
        }
        
        It "Should return an objectType 'set'" {
            $GetObjectMember.ObjectType | Should Be 'set'
        }
        
        It "Calls Get-IMXPathQuery" {
            Assert-MockCalled Get-IMXPathQuery
        }
        
        It "Calls ConvertTo-GUID" {
            Assert-MockCalled ConvertTo-GUID
        }
    }

    Context "ExplicitMember" {
        
        Mock Get-IMobject {
            return [pscustomobject]@{
                Xpath = $Xpath                
            }
        }
        
        $Members = Get-IMObjectMember -ObjectID myguid -ObjectType Set -ExplicitMembers -ErrorAction SilentlyContinue
        
        It "[ObjectType = Set] Should retun an object that is not null" {
            $Members | should not be $null
        }
                
        It "[ObjectType = Set] Xpath should contain ExplicitMember" {                       
            $Members.Xpath -like "*ExplicitMember*" | Should Be $true
        }
        
        It "[ObjectType = Set] Xpath should start with /Set" {
            #write-verbose -message $members.xpath -verbose
            $members.Xpath -like "/Set*" | Should Be $true
        }
        
        $members = $null
        $Members = Get-IMObjectMember -ObjectID myguid -ObjectType Group -ExplicitMembers -ErrorAction SilentlyContinue
        
        It "[ObjectType = Group] Should retun an object that is not null" {
            $Members | should not be $null
        }
        
        It "[ObjectType = Group] Xpath should contain ExplicitMember" {                       
            $Members.Xpath -like "*ExplicitMember*" | Should Be $true
        }
        
        It "[ObjectType = Group] Xpath should start with /Group" {
            #write-verbose -message $members.xpath -verbose
            $members.Xpath -like "/Group*" | Should Be $true
        }
    }
    
    Context "ComputedMember" {
        Mock Get-IMSet {}
        Mock Get-IMobject {
            return [pscustomobject]@{
                Xpath = $Xpath                
            }
        }
        
        $members = $null
        $Members = Get-IMObjectMember -ObjectID myguid -ObjectType Set -ComputedMembers -ErrorAction SilentlyContinue
        
        It "[ObjectType = Set] Should retun an object that is not null" {
            $Members | should not be $null
        }
                
        It "[ObjectType = Set] Xpath should contain ComputedMember" {                       
            $Members.Xpath -like "*ComputedMember*" | Should Be $true
        }
        
        It "[ObjectType = Set] Xpath should start with /Set" {
            #write-verbose -message $members.xpath -verbose
            $members.Xpath -like "/Set*" | Should Be $true
        }
        
        $members = $null
        $Members = Get-IMObjectMember -ObjectID myguid -ObjectType Group -ComputedMembers -ErrorAction SilentlyContinue
        
        It "[ObjectType = Group] Should retun an object that is not null" {
            $Members | should not be $null
        }
        
        It "[ObjectType = Group] Xpath should contain ComputedMember" {                       
            $Members.Xpath -like "*ComputedMember*" | Should Be $true
        }
        
        It "[ObjectType = Group] Xpath should start with /Group" {
            #write-verbose -message $members.xpath -verbose
            $members.Xpath -like "/Group*" | Should Be $true
        }
    }
}

Remove-Module fimmodule



