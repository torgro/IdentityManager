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
        $Result = Export-FIMConfig @splat | Out-FIMAttribute
       
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

function Get-IMPerson
{
[cmdletbinding()]
Param(
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
    [string]$Attribute
    ,
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
                    $null = $hash.Add($prop.AttributeName,$prop.Value)
                }
            }
            $null = $hash.Add("ResourceManagementObject",$inputObject.ResourceManagementObject)
            [pscustomobject]$hash
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
                            $null = $hash.Add($prop.AttributeName,$prop.Value)
                        }
                    }
                    $null = $hash.Add("ResourceManagementObject",$inputObject.ResourceManagementObject)
                    [pscustomobject]$hash
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
    DefaultParameterSetName='ByObject',
    SupportsShouldProcess=$true
)]
Param(
    [Parameter(Mandatory=$true, ValueFromPipeline, ParameterSetName='ByObject', Position=0)]
    [Parameter(Mandatory=$false, ValueFromPipeline, ParameterSetName='WithFilterAndObject')]
    [Parameter(Mandatory=$false, ValueFromPipeline, ParameterSetName='WithXMLFilterAndObject')]
    [pscustomobject]
    $SetObject
    ,
    [Parameter(Mandatory=$true,ParameterSetName='ByObjectID', Position=0)]
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
    }

    if ($PSBoundParameters.ContainsKey("Filter"))
    { 
        if (-not $Filter.TrimStart().StartsWith("<"))
        { 
            throw "Filter is not an XML, please use new-fimfilter to create an XML filter or use the XpathFilter parameter"
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


