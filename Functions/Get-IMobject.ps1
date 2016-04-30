function Get-IMobject
{
<#
.Synopsis
   A generic cmdlet desinged to do the communication with the Identity Manager Snap-In. It supports the most common used esourceTypes
.DESCRIPTION
   It supports the most common used ResourceTypes in Identity Manager. Please note that the Attribute parameter is casesensitive in 
   Identity Manager. Displayname is not the same as DisplayName!
.EXAMPLE
   Get-IMobject -Attribute DisplayName -AttributeValue "testperson*" -ResourceType Person
   
   Will ouput all persons that have testperson in their displayname
.EXAMPLE
   Get-IMobject -Attribute AccountName -AttributeValue "torgto*" -ResourceType Person
   
   Will output the person with the accountname 'torgto'
.EXAMPLE
  Get-IMobject -Attribute DisplayName -AttributeValue "All Employees" -ResourceType Set
  
  Will output the Set with the DisplayName 'All Employees'
.OUTPUTS
   It outpus a PSCustomObject with the attribute bindings that is defined for the ResourceType
.COMPONENT
   Identity Manager
.FUNCTIONALITY
   Identity Manager
#>
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