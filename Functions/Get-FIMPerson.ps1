﻿function Get-FIMPerson
{
[cmdletbinding()]
Param(
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
    [string]$Attribute
    ,
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
    
    Write-Verbose -Message "$f -  Getting FIMobject"
    $FIMobject = Get-FIMobject @splat

    if(-not $FIMobject)
    {         
        Write-Verbose "$f -  Get-FIMobject returned null objects of resourcetype $($splat.ResourceType)"
    }

    $FIMobject
}

END {
    Write-Verbose -Message "$f - END"
} 
    
}