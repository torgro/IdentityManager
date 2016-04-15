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