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