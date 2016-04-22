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