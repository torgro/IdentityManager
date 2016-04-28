function ConvertTo-GUID
{
[cmdletbinding()]
[outputType([string])]
Param(
    [Parameter(ValueFromPipeline)]
    [string[]]$GUID
)
BEGIN
{ 
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
}
    
PROCESS
{ 
    foreach ($NewGUID in $GUID)
    { 
        if ($NewGUID.ToLower().Contains("urn:uuid:"))
        { 
            Write-Verbose -Message "$f -  Removing prefix, current value is '$NewGUID'"
            $NewGUID = $NewGUID.Replace("urn:uuid:","").ToLower()
            Write-Verbose -Message "$f -  New value after removal is '$NewGUID'"
        }
        $NewGUID
    }    
}

END
{ 
    Write-Verbose -Message "$f - END"
}    
}

function Get-IMobject
{
[CmdletBinding()]
Param(
    [Parameter(ParameterSetName='BuildQuery')]
    [string]$Attribute
    ,
    [Parameter(ParameterSetName='BuildQuery')]
    [ValidateSet("*","Approval","Set","ObjectVisualizationConfiguration","ActivityInformationConfiguration","DetectedRuleEntry","Person","Group","Request","Resource","WorkflowDefinition","AttributeTypeDescription","BindingDescription","ObjectTypeDescription","SynchronizationRule","ManagementPolicyRule")]
    [string]$ResourceType
    ,
    [Parameter(ParameterSetName='BuildQuery')]
    [string]$AttributeValue
    ,
    [Parameter(ParameterSetName='XPathQuery',ValueFromPipeline)]
    [String]$Xpath
    ,
    [string]$uri = "http://localhost:5725/ResourceManagementService"
    ,
    [pscredential]$Credential
    ,
    [switch]$AllRelated
)

Begin 
{
    Set-StrictMode -Version Latest

    $f = $MyInvocation.MyCommand.Name
    Write-Verbose -Message "$f - START"

    Write-Verbose -Message "$f -  URI is '$uri'"
    Write-Verbose -Message "$f -  Running on computer '$env:COMPUTERNAME'"

    [string]$ExportXpath = $null
}

Process 
{
    if($PSBoundParameters.ContainsKey("Xpath"))
    {
        Write-Verbose -Message "$f -  Exporting using XPath"
        $ExportXpath = $Xpath
    }
    
    if($PSBoundParameters.ContainsKey("Attribute") -and $PSBoundParameters.ContainsKey("AttributeValue") -and $PSBoundParameters.ContainsKey("ResourceType"))
    {
        Write-Verbose -Message "$f -  Exporting using ResourceType or Attribute"
        Write-Verbose -Message "$f -  AttributeValue is '$AttributeValue"
        $AttributeValue = ConvertTo-GUID -GUID $AttributeValue
        Write-Verbose -Message "$f -  AttributeValue is now '$AttributeValue'"
        [string]$ExportXpath = "/$ResourceType[$Attribute = '$AttributeValue']"        
    
    }

    if($PSBoundParameters.ContainsKey("ResourceType") -and (-not $ExportXpath))
    {
        Write-Verbose -Message "$f -  Exporting using ResourceType $ResourceType"
        [string]$ExportXpath = "/$ResourceType"
    }

    Write-Verbose -Message "$f -  Creating splatting variable"

    $splat = @{
        Uri = $uri
        CustomConfig = $ExportXpath
    }

    if ($AllRelated)
    { 
        # this will fetch all related resources
    }
    else
    { 
        # this will not fetch related resources
        $null = $splat.Add("OnlyBaseResources", $true)
    }

    if($PSBoundParameters.ContainsKey("Credential"))
    {
        Write-Verbose -Message "$f -  Credentials provided, adding to splat"
        $null = $splat.Add("Credential",$Credential)
    }

    if($ExportXpath -ne $null)
    {
        Write-Verbose -Message "$f -  XPath=$ExportXpath"

        if($AttributeValue.Contains("*") -and $Attribute)
        {
            Write-Verbose -Message "$f -  Running wildcard search"

            $ExportXpath = "/$ResourceType[contains($Attribute,'%$AttributeValue%')]"
            $ExportXpath = $ExportXpath.Replace("*","")
           
            $splat.CustomConfig = $ExportXpath

            Write-Verbose -Message "$f -  XPath=$ExportXpath"
        }

        Write-Verbose -Message "$f -  Running Export-FIMConfig cmdlet"
        $Result = $null
        $Result = Export-FIMConfig @splat | Out-IMAttribute
       
        if($Result -ne $null)
        {
            Write-Verbose -Message "$f -  Saving results in global scope"
            Set-Variable -Name FIMresultObject -Value $Result -Scope Global
        }
        else
        {
            Write-Verbose -Message "$f -  Export-FIMConfig returned no results"    
        }
        $Result
    }   
}

End 
{
    Write-Verbose -Message "$f - END"
}   
}

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


function Get-IMPerson
{
[cmdletbinding(DefaultParameterSetName="None")]
Param(
    [Parameter(ParameterSetName='ByDisplayName')]
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
    [Parameter(ParameterSetName='ByAttribute')]
    [string]$Attribute
    ,
    [Parameter(ParameterSetName='ByAttribute')]
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
    
    Write-Verbose -Message "$f -  Getting IMobject"
    $IMobject = Get-IMobject @splat

    if(-not $IMobject)
    {         
        Write-Verbose "$f -  Get-IMobject returned null objects of resourcetype $($splat.ResourceType)"
    }

    $IMobject
}

END {
    Write-Verbose -Message "$f - END"
} 
    
}

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

Function Get-IMXPathQuery
{
[cmdletbinding()]
Param(
    [Parameter(Mandatory,ValueFromPipeLine)]
    [hashtable]$FieldValues
    ,    
    [ValidateSet("Person","Set","Group")]
    [string]$ObjectType
    ,
    [validateset("And","or")]
    [string]$JoinOperator
    ,
    [ValidateSet("=","contains")]
    [string]$CompareOperator = "="
)

BEGIN
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"
    
    if($PSBoundParameters.ContainsKey("ObjectType") -eq $false)
    {
        throw "ObjectType parameter is required"
    }

    $strBuilder = New-Object System.Text.StringBuilder
    [string]$str = $null
    
}
    
PROCESS
{    
    $null = $strBuilder.Append("/$ObjectType[")

    if($CompareOperator -eq "=")
    {
        foreach($key in $FieldValues.Keys)
        {
            $Value = $FieldValues["$key"]
            $null = $strBuilder.Append("($key $CompareOperator '$value') $JoinOperator ")
        }        
    }

    if($CompareOperator -eq "contains")
    {
        foreach($key in $FieldValues.Keys)
        {
            $Value = $FieldValues[$key]            
            $null = $strBuilder.Append("(contains($key,'%$value%')) $JoinOperator ")
        }        
    }

    $str = $strBuilder.ToString()
    $str = $str.TrimEnd(" $JoinOperator")
    $str = "$str]"

    return $str
}
    
END 
{
    Write-Verbose -Message "$f - END"
}
}

Function New-IMImportChange
{
[cmdletbinding()]
[outputtype([Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange])]
Param(
    [Parameter(Mandatory=$true)]
    [string]$AttributeName
    ,
    [Parameter(Mandatory=$true)]
    [string]$AttributeValue
    ,
    [string]$Locale = "Invariant"
    ,
    [Microsoft.ResourceManagement.Automation.ObjectModel.ImportOperation]
    $Operation = [Microsoft.ResourceManagement.Automation.ObjectModel.ImportOperation]::Add
    ,
    [bool]$FullyResolved
)
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"

    Write-Verbose -Message "$f -  Creating ImportChange object for Attribute '$AttributeName'"
    $change = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
    $change.Operation = $Operation
    $change.AttributeName = $AttributeName
    $change.AttributeValue = $AttributeValue
    $change.Locale = $Locale
    $change.FullyResolved = $true

    Write-Verbose -Message "$f - END"
    return $change
}

function New-IMimportObject
{
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("ObjectTypeDescription","Person","Group","BindingDescription","AttributeTypeDescription","Set","WorkflowDefinition","SynchronizationRule","ManagementPolicyRule","DetectedRuleEntry","ActivityInformationConfiguration")]
    [string]$ObjectType
    ,
    [Parameter(Mandatory=$true)]
    [Microsoft.ResourceManagement.Automation.ObjectModel.ImportState]$ImportState
)
    $f = $MyInvocation.MyCommand.Name
    Write-Verbose -Message "$f - START"

    $importObject = New-Object -TypeName Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
    $importObject.ObjectType = $ObjectType
    $importObject.State = $ImportState
    $importObject.SourceObjectIdentifier = [System.Guid]::NewGuid().ToString()

    Write-Verbose -Message "$f -  Created ImportObject of type $ObjectType and state $ImportState"
    $importObject

    Write-Verbose -Message "$f - END"
}

function Out-IMattribute
{ 
[cmdletbinding()]
Param(
    [Parameter(ValueFromPipeline=$true)]
    $inputObject
)

BEGIN
{
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$F - START"
}

PROCESS
{
    if ($inputObject -is [Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject])
    { 
        foreach($object in $inputObject)
        {        
            Write-Verbose -Message "$f -  Now processing $(($object.ResourceManagementAttributes | where AttributeName -eq "DisplayName").Value)"
            $hash = @{}
            foreach($prop in $object.ResourceManagementAttributes)
            {                             
                if($prop.IsMultiValue)
                {
                    $null = $hash.Add($prop.AttributeName,$prop.Values)
                }
                else
                {
                    if($prop.AttributeName -eq "ObjectID")
                    {
                        $guid = ConvertTo-GUID -GUID $prop.Value
                        $null = $hash.Add($prop.AttributeName, $guid)
                    }
                    else
                    {
                        $null = $hash.Add($prop.AttributeName,$prop.Value)
                    }                    
                }
            }
            $null = $hash.Add("ResourceManagementObject",$inputObject.ResourceManagementObject)
            $output = [pscustomobject]$hash
            $objectType = $output.ObjectType
            $output.PSObject.TypeNames.Insert(0,"IM.$objectType")
            $output
        }
    }
    else
    { 
        if($inputObject -isnot [Microsoft.ResourceManagement.Automation.ObjectModel.ExportObject])
        {
            Write-Verbose -Message "$f -  Object is not an ExportObject object, passthrou"
            $inputObject
        }
        else
        {
            foreach($object in $inputObject.ResourceManagementObject)
            {
                if(-not ($object -is [Microsoft.ResourceManagement.Automation.ObjectModel.ResourceManagementObject]))
                {
                    Write-Verbose -Message "$f -  Object is not a ResourceManagementObject object, passthrou"
                    $object
                }
                else
                {
                    Write-Verbose -Message "$f -  Now processing $(($object.ResourceManagementAttributes | where AttributeName -eq "DisplayName").Value)"
                    $hash = @{}
                    foreach($prop in $object.ResourceManagementAttributes)
                    {              
                        if($prop.IsMultiValue)
                        {
                            $null = $hash.Add($prop.AttributeName,$prop.Values)
                        }
                        else
                        {
                            if($prop.AttributeName -eq "ObjectID")
                            {
                                $guid = ConvertTo-GUID -GUID $prop.Value
                                $null = $hash.Add($prop.AttributeName, $guid)
                            }
                            else
                            {
                                $null = $hash.Add($prop.AttributeName,$prop.Value)
                            }        
                        }
                    }
                    $null = $hash.Add("ResourceManagementObject",$inputObject.ResourceManagementObject)
                    $output = [pscustomobject]$hash
                    $objectType = $output.ObjectType
                    $output.PSObject.TypeNames.Insert(0,"IM.$objectType")
                    $output
                }
            }
        }        
    }    
}

END
{
    Write-Verbose -Message "$f - END"
}
}

function Remove-FIMsnapin
{
[cmdletbinding()]
Param()
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"

    if(Get-PSSnapin -Name FIMautomation -ErrorAction SilentlyContinue)
    {
        Write-Verbose -Message "$F -  Removing FIMautomation snapin"
        Remove-PSSnapin -Name FIMautomation
    }
    else
    {
        Write-Verbose -Message "$f -  FIMautomation Snapin not found"
    }

    Write-Verbose -Message "$F - END"
}

function Set-IMset
{ 
[cmdletbinding(
    DefaultParameterSetName='ByObjectID',
    SupportsShouldProcess=$true
)]
Param(
    [Parameter(Mandatory=$false, ValueFromPipeline, ParameterSetName='ByObject', Position=0)]
    [Parameter(Mandatory=$false, ValueFromPipeline, ParameterSetName='WithFilterAndObject')]
    [Parameter(Mandatory=$false, ValueFromPipeline, ParameterSetName='WithXMLFilterAndObject')]
    [pscustomobject]
    $SetObject
    ,
    [Parameter(Mandatory=$false,ParameterSetName='ByObjectID', Position=0)]
    [Parameter(Mandatory=$false, ParameterSetName='WithFilterAndID')]
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndID')]
    [string]$ObjectID
    ,
    [string]$DisplayName
    ,
    [Parameter(Mandatory=$false, ParameterSetName='WithFilterAndObject')]
    [Parameter(Mandatory=$false, ParameterSetName='WithFilterAndID')]
    [string]$Filter
    ,
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndObject')]
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndID')]
    [String]$XpathFilter
    ,
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndObject')]
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndID')]
    [PSCustomObject[]]$ExplicitMember
    ,
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndObject')]
    [Parameter(Mandatory=$false, ParameterSetName='WithXMLFilterAndID')]
    [PSCustomObject[]]$RemoveExplicitMember
    ,
    [pscredential]$Credential
    ,
    [switch]$Commit
    ,
    [string]$uri = "http://localhost:5725/ResourceManagementService"
)

BEGIN {
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"

    Write-Verbose -Message "$F -  Creating a splatting variable"
    $splat = @{
        Uri = $uri
    }

    if($PSBoundParameters.ContainsKey("Credential"))
    {
        Write-Verbose -Message "$f -  Credentials specified, adding to splatting variable"
        $null = $splat.Add("Credential",$Credential)
    }
}
    
PROCESS {
    Write-Verbose -Message "$f -  Getting Set"

    if(-not $PSBoundParameters.ContainsKey('SetObject'))
    {
        $IMobject = Get-IMset -ObjectID $ObjectID @splat
        $IMobject = $IMobject.ResourceManagementObject
    }
    else
    {
        $IMobject = $SetObject.ResourceManagementObject     
    }

    if($IMobject.ObjectType -ne "Set")
    {
        throw "Target object type is not 'Set'"
    }

    $ChangeAttributes = @{}
    
    if($PSBoundParameters.ContainsKey("DisplayName"))
    {
        $ChangeAttributes.DisplayName = $DisplayName
        If($PSBoundParameters.ContainsKey("ObjectID") -eq $false -and $PSBoundParameters.ContainsKey("SetObject") -eq $false)
        {
            throw "Specify an SetObject or an ObjectID"
        }
    }

    if ($PSBoundParameters.ContainsKey("Filter"))
    { 
        if (-not $Filter.TrimStart().StartsWith("<"))
        { 
            throw "Filter is not an XML, please use new-IMFilter to create an XML filter or use the XpathFilter parameter"
        }
        $ChangeAttributes.Filter = $Filter
    }

    if ($PSBoundParameters.ContainsKey("XpathFilter"))
    { 
        [String]$NewFilter = New-IMxpathFilter -xPath $XpathFilter
        if ($NewFilter)
        { 
            $ChangeAttributes.Filter = $NewFilter
        }
        else
        { 
            throw "New-IMxPathFilter did not return an filter XML"
        }
    }

    Write-Verbose -Message "$F -  Create ImportObject of type Set"
    $importObject = New-IMimportObject -ObjectType Set -ImportState Put
    
    $importObject.TargetObjectIdentifier = $IMobject.ObjectID | ConvertTo-Guid
    $importObject.SourceObjectIdentifier = [guid]::Empty.ToString()
    
    Write-Verbose -Message "$f -  Looping through ChangeAttributes"

    foreach($key in $ChangeAttributes.Keys)
    {
        $AttribValue = $ChangeAttributes.$key                
        Write-Verbose -Message "$f -  $key = $AttribValue"
        $change = New-IMImportChange -AttributeName $key -AttributeValue $AttribValue -Operation Replace
        $importObject.Changes += $change
    }
    
    if($PSBoundParameters.ContainsKey("ExplicitMember"))
    {
        $null = $ChangeAttributes.Add("ExplicitMember",@())
        $MemberArray = New-Object -TypeName System.Collections.ArrayList
        foreach($member in $ExplicitMember)
        {
            $Id = $member.ObjectID | ConvertTo-Guid
            $null = $MemberArray.Add($id)
        }
        $ChangeAttributes.ExplicitMember = $MemberArray
    }

    if($PSBoundParameters.ContainsKey("RemoveExplicitMember"))
    {
        $null = $ChangeAttributes.Add("ExplicitMember",@())
        $MemberArray = New-Object System.Collections.ArrayList
        foreach($member in $RemoveExplicitMember)
        {
            $id = $member.ObjectID | ConvertTo-Guid
            $null = $MemberArray.Add($id)
        }
        $ChangeAttributes.ExplicitMember = $MemberArray
    }

    if($ChangeAttributes.Count -eq 0)
    {
        throw "No changes has been added, every parameter is null"
    }
    
    foreach($memb in $ChangeAttributes.ExplicitMember)
    {
        if($PSBoundParameters.ContainsKey("RemoveExplicitMember"))
        {
            $change = New-IMImportChange -AttributeName ExplicitMember -AttributeValue $memb -Operation Delete
        }
        else
        {
            $change = New-IMImportChange -AttributeName ExplicitMember -AttributeValue $memb -Operation Add
        }
        
        $importObject.Changes += $change
    }

    $splat.ImportObject = $importObject

    if($pscmdlet.ShouldProcess($FIMobject.DisplayName,"Updating set"))
    {
        if($Commit)
        {
            Write-Verbose -Message "$f -  Importing to FIM, commit change"
            $NeedAttention = Import-FIMConfig @splat
        
            if($NeedAttention)
            {
                Write-Warning -Message "$f - Import-FIMconfig returned objects that need your attention"
                return $NeedAttention
            }    
        }
        else
        {
            Write-Verbose -Message "$F -  Commit not set, returning importObject and exiting"
            return $importObject
        }
    }
}

END 
{
    Write-Verbose -Message "$f - END" 
}
    
}


