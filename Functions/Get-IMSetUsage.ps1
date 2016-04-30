function Get-IMSetUsage
{
<#
.Synopsis
   Find all resourcetypes that has referenced a Set.
.DESCRIPTION
   You can filter on the Set DisplayName, ObjectID, Attribute and AttributeValue. It will find Sets that is used as a critiera in other sets, groups
   that is using the set as criteria and management policy rules that use the set for transistion in/out
.EXAMPLE
   Get-IMSetUsage Displayname "all Employees"
   
   Will output all sets, groups and management policy rules that refernence the set with displayname 'all employees'
.EXAMPLE
   Get-IMSetUsage -Attribute ObjectID -AttributeValue '0e64a52c-3696-4edc-b836-caf54888fbb7'
   
   Will output all sets, groups and management policy rules that refernence the set with ObjectID '0e64a52c-3696-4edc-b836-caf54888fbb7'
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