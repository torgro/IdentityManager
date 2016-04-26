function Get-IMPersonMembership
{
[cmdletbinding()]
Param(
    [Parameter(ValueFromPipeline,ParameterSetName='ByObject')]
    $FIMobject
    ,
    [Parameter(ParameterSetName='ByDisplayName')]
    [String]$DisplayName
    ,
    [Parameter(ParameterSetName='ByAccountName')]
    [String]$AccountName
    ,
    [Parameter(ParameterSetName='ByObjectID')]
    [string]$ObjectID
    ,
    [pscredential]$Credential
    ,
    [string]$uri = "http://localhost:5725/ResourceManagementService"
)
BEGIN
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
    $Param = @{
        Uri = $uri
    }
    
    if ($Credential)
    {
        $null = $Param.Add("Credential",$Credential)
    }   
}

PROCESS
{
    if($DisplayName)
    {
        Write-Verbose -Message "$f -  Finding person with displayname [$displayname]"
        $FIMobject = Get-IMobject -Attribute DisplayName -ResourceType Person -AttributeValue "$DisplayName"
    }
    
    if($AccountName)
    {
        Write-Verbose -Message "$f -  Finding person with AccountName [$AccountName]"
        $FIMobject = Get-IMobject -Attribute AccountName -ResourceType Person -AttributeValue "$AccountName"
    }

    if($FIMobject)
    {
        $ObjectID = $FIMobject.ObjectID | convertto-GUID
        Write-Verbose -Message "$f -  Setting ObjectID to [$objectid]"
    }

    if($ObjectID)
    {
        $allQuery = (Get-IMxpathQuery -FieldValues @{ComputedMember = "$ObjectID"} -ObjectType Set -CompareOperator =)
        $allQuery += " | " + (Get-IMxpathQuery -FieldValues @{ComputedMember = "$ObjectID"} -ObjectType Group -CompareOperator =)
        Write-Verbose -Message "$f -  Running this query [$allQuery]"
        Get-IMobject -Xpath $allQuery @Param
    }
    else
    {
        Write-Verbose -Message "$f -  Unable to find person without objectID"
    }        
}

END 
{
    Write-Verbose -Message "$f - END"
}

}