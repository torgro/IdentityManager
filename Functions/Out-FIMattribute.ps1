function Out-FIMattribute
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
                            [void]$hash.Add($prop.AttributeName,$prop.Values)
                        }
                        else
                        {
                            [void]$hash.Add($prop.AttributeName,$prop.Value)
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