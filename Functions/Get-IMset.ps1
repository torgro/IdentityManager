function Get-IMset
{
<#
.Synopsis
   Get a Set object from Identity Manager. 
.DESCRIPTION
   You can filter on DisplayName, ObjectID, Attribute and AttributeValue
.EXAMPLE
   Get-IMset
   
   Will output all Sets from Identity Manager
.EXAMPLE
   Get-IMset -Displayname "all Employees"
   
   Will ouput the Set with the DisplayName 'all Employees'
.EXAMPLE
   Get-IMset -Attribute Creator -AttributeValue 'torgto'
   
   Will output sets with the Creator attribute set to 'torgto'
.OUTPUTS
   It outpus a PSCustomObject with the attribute bindings that is defined for the Person Object
.COMPONENT
   Identity Manager
.FUNCTIONALITY
   Identity Manager
#>
[OutputType([System.Management.Automation.PSCustomObject])]
[cmdletbinding()]
Param(
    [Parameter(ParameterSetName='ByDisplayName')]
    [string]$DisplayName
    ,
    [Parameter(ParameterSetName='ByObjectID')]
    [string]$ObjectID
    ,
    [Parameter(ParameterSetName='ByAttribute')]
    [string]$Attribute
    ,
    [Parameter(ParameterSetName='ByAttribute')]
    [string]$AttributeValue
    ,
    [pscredential]$Credential
    ,
    [string]$uri = "http://localhost:5725/ResourceManagementService"
    ,
    [switch]$AllRelated
)

BEGIN 
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START" 
    
    $splat = @{
        uri = $uri
        ResourceType = "Set"
        ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
    }
}

PROCESS 
{
    if($PSBoundParameters.ContainsKey("DisplayName"))
    {
        $null = $splat.Add("Attribute", "DisplayName")
        $null = $splat.Add("AttributeValue","$DisplayName")
    }
    
    if($PSBoundParameters.ContainsKey("ObjectID"))
    {
        $null = $splat.Add("Attribute", "ObjectID")
        $guid = $ObjectID | ConvertTo-GUID
        $null = $splat.Add("AttributeValue",$guid)
    } 

    if($PSBoundParameters.ContainsKey("Credential"))
    {
        Write-Verbose -Message "$f -  Credentials provided, adding to splat"
        $null = $splat.Add("Credential",$Credential)
    }

    if ($AllRelated)
    { 
        Write-Verbose -Message "$f -  AllRelated specified, adding to splat"
        $null = $splat.Add("AllRelated",$true)
    }
    
    if($PSBoundParameters.ContainsKey("Attribute") -and $PSBoundParameters.ContainsKey("AttributeValue"))
    {
        $null = $splat.Add("Attribute", "$Attribute")
        $null = $splat.Add("AttributeValue","$AttributeValue")
    }

    $IMobject = Get-IMobject @splat

    if(-not $IMobject)
    {         
        Write-Verbose -Message "$f -  Get-IMobject returned null objects of resourcetype $($splat.ResourceType)"
    }
    $IMobject
} 

END 
{
    Write-Verbose -Message "$f - END"
}
}