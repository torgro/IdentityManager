function Get-IMset
{
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