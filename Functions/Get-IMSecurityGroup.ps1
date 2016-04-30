function Get-IMSecurityGroup
{
<#
.Synopsis
   Get a Security Group object from Identity Manager. 
.DESCRIPTION
   You can filter on DisplayName or ObjectID
.EXAMPLE
   Get-IMSecurityGroup
   
   Will output all security groups from Identity Manager
.EXAMPLE
  Get-IMSecurityGroup -Displayname "Domain*"
   
   Will ouput all security groups that have Domain in their displayname
.EXAMPLE
  Get-IMPerson -ObjectID 0e64a52c-3696-4edc-b836-caf54888fbb7
  
  Will output the security group with id '0e64a52c-3696-4edc-b836-caf54888fbb7'
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
        Write-Verbose "$f -  Get-IMobject returned null objects of resourcetype $($splat.ResourceType)"
    }
    
    $FIMobject
}
    
END 
{
    Write-Verbose -Message "$f - END"
}       
}