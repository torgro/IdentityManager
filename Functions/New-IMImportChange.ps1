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