function Get-IMObjectMember
{
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
