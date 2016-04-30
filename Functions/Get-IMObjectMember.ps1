function Get-IMObjectMember
{
<#
.Synopsis
   Get the member of a Set or a Group.
.DESCRIPTION
   If you do not use the ComputedMembers parameter or the ExplicitMembers parameter, all members will be returned.
.EXAMPLE
   Get-IMObjectMember -DisplayName "All Employees" -ObjectType Set
   
   Will output all persons that is a member of the Set 'All Employees'
.EXAMPLE
   Get-IMObjectMember -DisplayName "All Employees" -ObjectType Set -ComputedMembers
   
   Will output all persons that matches the filter/criteria of the Set. Manually managed members is not returned
.EXAMPLE
  Get-IMObjectMember -DisplayName "All Employees" -ObjectType Set -ExplicitMembers
   
   Will output all persons that is manually managed on the Set. Filter/criteria members is not returned
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
    [Parameter(ValueFromPipeline,ParameterSetName='ByObject')]
    $FIMobject
    ,
    [Parameter(ParameterSetName='ByDisplayName')]
    [String]$DisplayName
    ,
    [Parameter(ParameterSetName='ByObjectID')]
    [string]$ObjectID
    ,
    [Parameter(ParameterSetName='ByObjectID')]
    [Parameter(ParameterSetName='ByDisplayName')]
    [ValidateSet("Set","Group")]
    [String]$ObjectType
    ,
    [switch]$ComputedMembers
    ,
    [switch]$ExplicitMembers
    ,
    [pscredential]$Credential
    ,
    [string]$uri = "http://localhost:5725/ResourceManagementService"
)
BEGIN
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
}

PROCESS
{
    $GetFimObject = @{}
    $GetFIMSet = @{}
    
    $GetFimXpath = @{
        CompareOperator = "="
    }
    
    $BaseParam = @{
        Uri = $uri
    }
    
    if($PSBoundParameters.ContainsKey("Credential"))
    {
        $null = $BaseParam.Add("Credential", $Credential)        
    }
    If($PSBoundParameters.ContainsKey("DisplayName"))
    {
        Write-Verbose -Message "$f -  Setting displayname"
        $null = $GetFimXpath.Add("FieldValues",@{DisplayName="$DisplayName"})   
        $null = $GetFIMSet.Add("DisplayName",$DisplayName)
    }
    if($PSBoundParameters.ContainsKey("FIMobject"))
    {
        $ObjectID = $FIMobject.ObjectID
        $ObjectType = $FIMobject.ObjectType
    }
    
    if($ObjectID)
    {
        Write-Verbose -Message "$f -  Setting ObjectID"
        $ObjectID = $ObjectID | ConvertTo-GUID
        $null = $GetFimXpath.Add("FieldValues",@{ObjectID="$ObjectID"})
        $null = $GetFIMSet.Add("ObjectID",($ObjectID | ConvertTo-GUID))
    }
    
    [string]$MemberType = "/ComputedMember"
    
    if($PSBoundParameters.ContainsKey("ComputedMembers") -eq $false -and $PSBoundParameters.ContainsKey("ExplicitMembers") -eq $false)
    {
        Write-Verbose -Message "$f -  Outputing computermembers (all)"
        [string]$query = (Get-IMXPathQuery @GetFimXpath -ObjectType $ObjectType) + $MemberType
        
        Write-Verbose -Message "$F -  Running this query [$query]"

        $null = $GetFimObject.Add("Xpath",$query)
        Get-IMobject @GetFimObject @BaseParam
    }

    if($PSBoundParameters.ContainsKey("ExplicitMembers"))
    {
        $MemberType = "/ExplicitMember"
        Write-Verbose -Message "$f -  Outputing manually managed members"
        [string]$query = (Get-IMXPathQuery @GetFimXpath -ObjectType $ObjectType) + $MemberType
        
        Write-Verbose -Message "$F -  Running this query [$query]"
        $null = $GetFimObject.Add("Xpath",$query)
        Get-IMobject @GetFimObject @BaseParam
    }
    
    if($PSBoundParameters.ContainsKey("ComputedMembers"))
    {
        Write-Verbose -Message "$f -  Finding members by filter"
        if(-not $FIMobject)
        {
            Write-Verbose -Message "$f -  Finding set [$DisplayName $objectID]"
            $FIMobject = Get-IMSet @GetFIMSet @BaseParam            
        }
        if($FIMobject)
        {
            Write-Verbose -Message "$f -  Have FIMobject, getting filter"
            [string]$filter = $FIMobject.Filter
            $filterXML = [xml]$filter
            Write-Verbose -Message "$f -  XPATH filter is [$($filterXML.Filter.InnerText)]"
            $null = $GetFimObject.Add("Xpath",$filterXML.Filter.InnerText)
            Get-IMObject @GetFimObject @BaseParam
        }
        else
        {
            Write-Verbose -Message "$f -  FIMobject is null"
        }
    }    
}

END
{
    Write-Verbose -Message "$f - END"
}
}
