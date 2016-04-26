function Get-IMSecurityGroup
{
[cmdletbinding()]
Param(
    [string]$DisplayName
    ,
    [Parameter(ParameterSetName='ByObjectID')]
    [string]$ObjectID
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
        ResourceType = "Group"
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
        $null = $splat.Add("AttributeValue","$ObjectID")
    }    

    if($PSBoundParameters.ContainsKey("Credential"))
    {
        Write-Verbose -Message "$f -  Credentials provided, adding to splat"
        $null = $splat.Add("Credential",$Credential)
    }

    if ($PSBoundParameters.ContainsKey("AllRelated"))
    { 
        Write-Verbose -Message "$f -  AllRelated specified, adding to splat"
        $null = $splat.Add("AllRelated",$true)
    }

    $FIMobject = Get-IMobject @splat

    if(-not $FIMobject)
    {         
        Write-Verbose "$f -  Get-FIMobject returned null objects of resourcetype $($splat.ResourceType)"
    }
    
    $FIMobject
}
    
END 
{
    Write-Verbose -Message "$f - END"
}       
}