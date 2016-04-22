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