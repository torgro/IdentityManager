# IdentityManager

This is a module for Identity Manager from Microsoft. The product it self comes with a Powershell Snap-In that covers the bare minimum of basics. You can do everything with it, however it is not easy to use.

The module is work in progress as I am constantly adding stuff to it, including Pester tests. It will eventually become available in PowershellGallery for easy access and installation. 

Please leave feedback and report bug/issues. I am currently looking for beta-testers. Look me up or give it a spinn if you like!


## What is included

I am focusing in on the Get-cmdlets at the moment. Then I will start with Set-cmdlets, New-cmdlets and finally Remove-cmdlets.


## Operation validation

This module will at some point be a requirement for my Operations Validation tests for Identity manager (part of my test initiative at https://github.com/torgro/PesterOperationTest)


## Currently implemented Cmdlets

Get-Cmdlets:

* Get-IMObject:
A generic cmdlet used by all of the Get-Cmdlets. It is responsible for running the core cmdlets in the IM snap-in
* Get-IMObjectMember
Used to list members of a group/set. It can list ComputedMembers or ExplicitMembers
* Get-IMPerson
Get person information
* Get-IMPersonMembership
Show person membership in Groups/sets
* Get-IMSecurityGroup
Show information about Security groups in IM
* Get-IMSet
Show information about Sets in IM
* Get-IMSetUsage
Show all related usage of a Set in IM
* Get-IMXPathQuery
Create simple XPath queries with hashtable
* Out-IMAttribute
Cast a ResourceManagementObject to a PSCustomObject Used by the Get-IMObject cmdlet


Set-Cmdlets:

* Set-IMset (not finished)
Update a set with DisplayName, ExplicitMembers or filter


New-Cmdlets:

* New-IMImportChange
* New-IMImportObject


Out-Cmdlets:
* ConvertTo-Guid
Converts a IM guid to a regular guid


Cheers

**Tore Groneng**
@toregroneng
tore.groneng@gmail.com