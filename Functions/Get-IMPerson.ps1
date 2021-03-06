﻿function Get-IMPerson
{
<#
.Synopsis
   Get a Person object from Identity Manager. 
.DESCRIPTION
   You can filter on DisplayName, ObjectID, AccountName, EmployeeID, SocialSecutiryNumber and OrganizationalUnit
.EXAMPLE
   Get-IMPerson
   
   Will output all persons from Identity Manager
.EXAMPLE
   Get-IMPerson -Displayname "testperson*"
   
   Will ouput all persons that have testperson in their displayname
.EXAMPLE
  Get-IMPerson -AccountName torgto
  
  Will output the person with the accountname 'torgto'
.OUTPUTS
   It outpus a PSCustomObject with the attribute bindings that is defined for the Person Object
.COMPONENT
   Identity Manager
.FUNCTIONALITY
   Identity Manager
#>
[OutputType([System.Management.Automation.PSCustomObject])]
[cmdletbinding(DefaultParameterSetName="none")]
Param(
    [Parameter(ParameterSetName='ByDisplayName')]
    [string]$DisplayName
    ,
    [Parameter(ParameterSetName='ByObjectID')]
    [string]$ObjectID
    ,
    [Parameter(ParameterSetName='ByAccountName')]
    [string]$AccountName
    ,
    [Parameter(ParameterSetName='ByEmployeeID')]
    [string]$EmployeeID
    ,
    [Parameter(ParameterSetName='BySocialSecurity')]
    [string]$SocialSecurityNumber
    ,
    [Parameter(ParameterSetName='ByOrgUnit')]
    [string]$OrgUnitCode
    ,
    [Parameter(ParameterSetName='ByAttribute')]
    [string]$Attribute
    ,
    [Parameter(ParameterSetName='ByAttribute')]
    [string]$AttributeValue
    ,
    [pscredential]$Credential
    ,
    [switch]$AllReleated
    ,
    [string]$uri = "http://localhost:5725/ResourceManagementService"
)
    
BEGIN
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
    
    $splat = @{
        uri = $uri
        ResourceType = "Person"
        ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
    }
}    
    
PROCESS {
    
    if($PSBoundParameters.ContainsKey("DisplayName"))
    {
        $null = $splat.Add("Attribute", "DisplayName")
        $null = $splat.Add("AttributeValue","$DisplayName")
    }
    
    if($PSBoundParameters.ContainsKey("AccountName"))
    {
        $null = $splat.Add("Attribute", "AccountName")
        $null = $splat.Add("AttributeValue","$AccountName")
    }
    
    if($PSBoundParameters.ContainsKey("EmployeeID"))
    {
        $null = $splat.Add("Attribute", "EmployeeID")
        $null = $splat.Add("AttributeValue","$EmployeeID")
    }

    if($PSBoundParameters.ContainsKey("ObjectID"))
    {         
        $null = $splat.Add("Attribute", "ObjectID")
        $null = $splat.Add("AttributeValue","$ObjectID")
    }    

    if($PSBoundParameters.ContainsKey("Credential"))
    {
        Write-Verbose -Message "$f -  Credentials provided, adding to splat"
        $null = $splat.Add("Credential",$Credential)
    }
    
    if($PSBoundParameters.ContainsKey("Verbose"))
    {
        $null = $splat.Add("Verbose",$true)
    }
    
    if($PSBoundParameters.ContainsKey("Attribute"))
    {
        $null = $splat.Add("Attribute", $Attribute)
        $null = $splat.Add("AttributeValue",$AttributeValue)
    }
    
    Write-Verbose -Message "$f -  Getting IMobject"
    $IMobject = Get-IMobject @splat

    if(-not $IMobject)
    {         
        Write-Verbose "$f -  Get-IMobject returned null objects of resourcetype $($splat.ResourceType)"
    }

    $IMobject
}

END {
    Write-Verbose -Message "$f - END"
} 
    
}