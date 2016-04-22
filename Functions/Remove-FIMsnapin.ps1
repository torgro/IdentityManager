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