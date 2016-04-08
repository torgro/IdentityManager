#build module script
[cmdletbinding()]
Param(
    [string]$ModuleFileName = "IdentityManager.psm1"
    ,
    [switch]$Major
    ,
    [switch]$Minor
    ,
    [switch]$LoadModule
)
cd C:\Users\Tore\Dropbox\SourceTreeRepros\IdentityManager -ErrorAction SilentlyContinue
$F = $MyInvocation.InvocationName
Write-Verbose -Message "$F - Starting build, getting files"

if(Get-Module -Name IdentityManager)
{
    Write-Verbose "$F -  Removing FIMautomation snapIn and Powerfim module"
    Remove-FIMsnapin -Verbose
    Remove-Module IdentityManager -Verbose:$false
}
    
$fileList = Get-ChildItem -Filter .\functions\*.ps1 | where name -NotLike "*Tests*"

$ModuleName = (Get-ChildItem -Path $ModuleFileName -ErrorAction SilentlyContinue).BaseName
Write-Verbose -Message "$f -  Modulename is $ModuleName"

$ExportedFunctions = New-Object System.Collections.ArrayList
$fileList | foreach {
    Write-Verbose -Message "$F -  Function = $($_.BaseName) added"
    [void]$ExportedFunctions.Add($_.BaseName)
}

$ModuleLevelFunctions = $null

foreach($function in $ModuleLevelFunctions)
{
    Write-Verbose -Message "$f -  Checking function $function"
    if($ExportedFunctions -contains $function)
    {
        write-verbose -Message "$f -  Removing function $function from exportlist"
        $ExportedFunctions.Remove($function)
    }
    else
    {
        Write-Verbose -Message "$f -  Exported functions does not contain $function"
    }
}

Write-Verbose -Message "$f -  Constructing content of module file"
[string]$ModuleFile = ""
foreach($file in $fileList)
{
    $filecontent = Get-Content -Path $file.FullName -raw
    $filecontent = "$filecontent`n`n"
    $ModuleFile += $filecontent
}
[System.Version]$ver = $null

if((Test-Path -Path $moduleFileName -ErrorAction SilentlyContinue) -eq $true)
{
    Write-Verbose -Message "$f -  Getting version info"
    Import-Module -Name ".\$ModuleName.psd1" -Verbose:$false
    $ver = (Get-Module $Modulename).Version
    Remove-FIMsnapin
    Remove-Module $ModuleName -Verbose:$false
    #Remove-PSSnapin -Name FIMautomation -ErrorAction SilentlyContinue
    Write-Verbose -Message "$f -  Removing previous version of $ModuleFileName"
    Remove-Item -Path $ModuleFileName
}

function Get-NextVersion
{
[cmdletbinding()]
[outputtype([System.Version])]
Param(
    [System.Version]$CurrentVersion
    ,
    [switch]$Major
    ,
    [switch]$Minor
)
    [System.Version]$newVersion = $null
    $f = $MyInvocation.InvocationName
    Write-Verbose -Message "$f - START"

    if($Major)
    {
        Write-Verbose -Message "$F -  Bumping Major version"
        $build = $CurrentVersion.Build
        $ma = $CurrentVersion.Major + 1
        $mi = $CurrentVersion.Minor
        $newVersion = New-Object System.Version("$Ma.$Mi.$build.0")
    }

    if($Minor)
    {
        Write-Verbose -Message "$f - Bumping Minor version"
        $build = $CurrentVersion.Build
        $ma = $CurrentVersion.Major
        $mi = $CurrentVersion.Minor + 1
        $newVersion = New-Object System.Version("$Ma.$Mi.$build.0")
    }

    if($Minor -and $Major)
    {
        Write-Verbose -Message "$f - Bumping Major and Minor version"
        $build = $CurrentVersion.Build
        $ma = $CurrentVersion.Major + 1
        $mi = $CurrentVersion.Minor + 1
        $newVersion = New-Object System.Version("$Ma.$Mi.$build.0")
    }

    if(-not $Minor -and -not $Major)
    {
        Write-Verbose -Message "$f - Bumping build version"
        $build = $CurrentVersion.Build + 1
        $ma = $CurrentVersion.Major
        $mi = $CurrentVersion.Minor
        $newVersion = New-Object System.Version("$Ma.$Mi.$build.0")
    }
    return $newVersion
}

if(-not $ver)
{
    Write-Verbose -Message "$f -  No previous version found, creating new version"
    $ver = New-Object System.Version("1.0.0.0")
}

if($Major)
{    
    $ver = Get-NextVersion -CurrentVersion $ver -Major
}

if($Minor)
{
    $ver = Get-NextVersion -CurrentVersion $ver -Minor
}

if($Minor -and $Major)
{
     $ver = Get-NextVersion -CurrentVersion $ver -Minor -Major
}

if(-not $Minor -and -not $Major)
{
    Write-Verbose -Message "$f -  Defaults to bump build version"
    $ver = Get-NextVersion -CurrentVersion $ver
}

Write-Verbose -Message "$f -  New version is $($ver.ToString())"

Write-Verbose -Message "$f -  Writing contents to modulefile"
Set-Content -Path $ModuleFileName -Value $ModuleFile -Encoding UTF8

$ManifestName = "$((Get-ChildItem -Path $ModuleFileName -ErrorAction SilentlyContinue).BaseName).psd1"
Write-Verbose -Message "$f -  ManifestfileName is $ManifestName"

if((Test-Path -Path $ManifestName -ErrorAction SilentlyContinue) -eq $true)
{
    Write-Verbose -Message "$f -  Removing previous version of $ManifestName"
    Remove-Item -Path $ManifestName
}

Write-Verbose -Message "$f -  Creating manifestfile"
$New_moduleManifest = @{
    Path        = $ManifestName
    Author      = "Tore Grøneng @toregroneng tore@firstpoint.no"
    CompanyName = "NA"
    ModuleVersion = $ver.ToString()
    FunctionsToExport = $ExportedFunctions
    RootModule = $ModuleFileName

}
New-ModuleManifest @New_moduleManifest -NestedModules @("FIMmodule\FIMmodule.psd1")
Write-Verbose -Message "$f -  Reading back content to contert to UTF8 (content management tracking)"
Set-Content -Path $ManifestName -Value (Get-Content -Path $ManifestName -Raw) -Encoding UTF8

$Answer = "n"

if(-not $LoadModule)
{
    $Answer = Read-Host -Prompt "Load module $ModuleName? (Yes/No)"
}

if($Answer -eq "y" -or $Answer -eq "yes" -or $LoadModule)
{
    Write-Verbose -Message "$f -  Loading module"
    if(Test-Path -Path $ManifestName)
    {
        Import-Module $PSScriptRoot\$ManifestName
    }
    else
    {
        Write-Warning -Message "Modulefile $ManifestName not found, module not imported"
    }
}
else
{
    Write-Verbose -Message "$f -  Module not loaded"
}

Write-Verbose -Message "$f - END"