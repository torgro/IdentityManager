function Get-IMSetUsage
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
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START" 
    
    $splat = @{
        uri = $uri
        ResourceType = "Set"
        ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
    }

    $FIMobject = Get-IMSet @PSBoundParameters

    if(-not $FIMobject)
    {         
        Write-Verbose "$f -  Get-IMobject returned null objects of resourcetype $($splat.ResourceType)"
        break;
    }

    Write-Verbose -Message "$f -  Found set [$($FIMobject.DisplayName)], getting usage"
    $SetGuid = $FIMobject.ObjectID | ConvertTo-GUID

    if(-not $SetGuid)
    {
        [string]$msg = "$f -  Unable to find GUID"
        Write-Verbose -Message $msg
        Write-Error -Message $msg -ErrorAction Stop
    }

    $AllQuery = "/ManagementPolicyRule[ResourceFinalSet='$SetGuid' or ResourceCurrentSet='$SetGuid' or PrincipalSet='$SetGuid'] | /Set/ComputedMember[ObjectID='$SetGuid'] | /Group/ComputedMember[ObjectID='$SetGuid']"
    
    $GetIMObject = @{
        uri = $uri
        ErrorAction = [System.Management.Automation.ActionPreference]::SilentlyContinue
        Xpath = $AllQuery
    }
    if($Credential)
    {
        Write-Verbose -Message "$f -  Credentials provided, adding to splat"
        $null = $GetIMObject.Add("Credential",$Credential)
    }
    if ($AllRelated)
    { 
        Write-Verbose -Message "$f -  AllRelated specified, adding to splat"
        $null = $GetIMObject.Add("AllRelated",$true)
    }

    Write-Verbose -Message "$f -  Running Get-IMObject"

    $FIMobject = Get-IMobject @GetIMObject

    if(-not $FIMobject)
    {         
        Write-Verbose "$f -  Get-IMobject returned null objects"
    }

    $FIMobject

    Write-Verbose -Message "$f - END"
    
}