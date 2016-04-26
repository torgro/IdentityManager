$here = Split-Path -Parent $MyInvocation.MyCommand.Path | split-path -parent
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\functions\$sut"

$PSBoundParameters.clear()

Import-module .\IdentityManager.psd1 -verbose:$false
Import-Module .\FIMmodule\FIMmodule.psd1 -Scope Global -verbose:$false

$FieldValues = @{Value=2}

Describe "Get-IMXPathQuery" {
    Context "Parameter validation" {
        $cmdlet = Get-Command -Name Get-IMXPathQuery
        $ParamSetsCount = $cmdlet.ParameterSets.Count

        $MandatoryParams = $cmdlet.ParameterSets | ForEach-Object { 
                           $_.Parameters | foreach-Object {
                           $_ | where isMandatory -eq $true } } | 
                           Select-Object -ExpandProperty Name -Unique

        $AllParams = $cmdlet.ParameterSets | foreach-Object { 
                     $_.Parameters } |                        
                     Select-Object -ExpandProperty Name -Unique | 
                     foreach-Object { if([System.Management.Automation.Cmdlet]::CommonParameters -notcontains $_){ $_ }
        }

        It "Only FieldValues parameter should throw" {
           { Get-IMXPathQuery -FieldValues $FieldValues } | Should Throw
        }

        It "ValidateSet count for ObjectType should be 3" {
            $ValidateSet = $cmdlet.ResolveParameter("ObjectType").Attributes | Where-Object {$_.GetType().Name -eq "ValidateSetAttribute"}
            $ValidateSet.ValidValues.count | Should be 3
        }

        It 'Should throw if ObjectType is not "Person","Set","Group"' {
            { Get-IMXPathQuery -ObjectType yalla  } | Should throw
        }

        It 'Should NOT throw if ObjectType is "Person","Set","Group"' {
            { Get-IMXPathQuery -FieldValues $FieldValues -ObjectType Person  } | Should Not throw
            { Get-IMXPathQuery -FieldValues $FieldValues -ObjectType Set  } | Should Not throw
            { Get-IMXPathQuery -FieldValues $FieldValues -ObjectType Group  } | Should Not throw
        }

        It 'Should throw if JoinOperator is not "And","or"' {
            { Get-IMXPathQuery -JoinOperator yalla  } | Should throw
        }

        It 'Should NOT throw if JoinOperator is "And","or"' {
            { Get-IMXPathQuery -FieldValues $FieldValues -JoinOperator And -ObjectType Person } | Should Not throw
            { Get-IMXPathQuery -FieldValues $FieldValues -JoinOperator or -ObjectType Person } | Should Not throw
        }
        
        It 'Should throw if CompareOperator is not "=","contains"' {
            { Get-IMXPathQuery -CompareOperator yalla  } | Should throw
        }

        It 'Should NOT throw if CompareOperator is "=","contains"' {
            { Get-IMXPathQuery -FieldValues $FieldValues -CompareOperator "=" -ObjectType Person } | Should Not throw
            { Get-IMXPathQuery -FieldValues $FieldValues -CompareOperator "contains" -ObjectType Person } | Should Not throw
        }
    }

    Context "Function output one field" {
        It "Should produce Group query with value 2"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Group" -CompareOperator "=" | Should Be "/Group[(Value = '2')]"
        }

        It "Should produce Group query which contains 2"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Group" -CompareOperator contains| Should Be "/Group[(contains(Value,'%2%'))]"
        }

        It "Should produce Set query with value 2"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Set" -CompareOperator "=" | Should Be "/Set[(Value = '2')]"
        }

        It "Should produce Set query which contains 2"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Set" -CompareOperator contains| Should Be "/Set[(contains(Value,'%2%'))]"
        }

        It "Should produce Person query with value 2"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator "=" | Should Be "/Person[(Value = '2')]"
        }

        It "Should produce Person query which contains 2"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator contains| Should Be "/Person[(contains(Value,'%2%'))]"
        }

    }

    $FieldValues = @{Value=2;Name="hoho"}

    Context "Function output two fields" {
        It "Should produce Group query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Group" -CompareOperator "=" -JoinOperator And | Should Be "/Group[(Name = 'hoho') And (Value = '2')]"
        }

        It "Should produce Group query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Group" -CompareOperator "=" -JoinOperator or | Should Be "/Group[(Name = 'hoho') or (Value = '2')]"
        }

        It "Should produce Group query which contains 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Group" -CompareOperator contains -JoinOperator And | Should Be "/Group[(contains(Name,'%hoho%')) And (contains(Value,'%2%'))]"
        }

        It "Should produce Group query which contains 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Group" -CompareOperator contains -JoinOperator or | Should Be "/Group[(contains(Name,'%hoho%')) or (contains(Value,'%2%'))]"
        }

        It "Should produce Set query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Set" -CompareOperator "=" -JoinOperator And | Should Be "/Set[(Name = 'hoho') And (Value = '2')]"
        }

        It "Should produce Set query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Set" -CompareOperator "=" -JoinOperator or | Should Be "/Set[(Name = 'hoho') or (Value = '2')]"
        }

        It "Should produce Set query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Set" -CompareOperator contains -JoinOperator And | Should Be "/Set[(contains(Name,'%hoho%')) And (contains(Value,'%2%'))]"
        }

        It "Should produce Set query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Set" -CompareOperator contains -JoinOperator or | Should Be "/Set[(contains(Name,'%hoho%')) or (contains(Value,'%2%'))]"
        }

        It "Should produce Person query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator "=" -JoinOperator And | Should Be "/Person[(Name = 'hoho') And (Value = '2')]"
        }

        It "Should produce Person query with value 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator "=" -JoinOperator or | Should Be "/Person[(Name = 'hoho') or (Value = '2')]"
        }

        It "Should produce Person query which contains 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator contains -JoinOperator And | Should Be "/Person[(contains(Name,'%hoho%')) And (contains(Value,'%2%'))]"
        }

        It "Should produce Person query which contains 2 and name hoho"{
             Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator contains -JoinOperator or | Should Be "/Person[(contains(Name,'%hoho%')) or (contains(Value,'%2%'))]"
        }
    }

    $FieldValues = @{Value=2}

    Context "Chars with one field" {
        
        $Query = Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator "="

        It "Query should not be null" {
            $Query | Should Not Be $null
        }
        
        It "LastChar should be equal to ']'" {
            $Query[-1] | Should Be "]"
        }

        It "First char should be equal to '/'" {
            $Query[0] | Should Be "/"
        }

        It "Query should contain '['" {
            $Query.contains("[") | Should Be $true
        }

        It "Query should contain 2 of the ' char" {
            ($Query.toCharArray() | ForEach-Object {If($_ -eq "'"){$_} }| Measure-Object).Count | Should Be 2
        }

        It "The second last char in the query should be ')'" {
            $Query[$Query.length - 2] | Should Be ")"
        }

        It "Query should contain '('" {
            $Query.contains("(") | Should Be $true
        }
    }

    $FieldValues = @{Value=2;Name="hoho"}

    Context "Chars with two fields" {
        
        $Query = Get-IMXPathQuery -FieldValues $FieldValues -ObjectType "Person" -CompareOperator "="

        It "Query should not be null" {
            $Query | Should Not Be $null
        }
        
        It "LastChar should be equal to ']'" {
            $Query[-1] | Should Be "]"
        }

        It "First char should be equal to '/'" {
            $Query[0] | Should Be "/"
        }

        It "Query should contain '['" {
            $Query.contains("[") | Should Be $true
        }

        It "Query should contain 4 of the ' char" {
            ($Query.toCharArray() | ForEach-Object {If($_ -eq "'"){$_} }| Measure-Object).Count | Should Be 4
        }

        It "Query should have 2 of the '(' char" {
            ($Query.toCharArray() | ForEach-Object {If($_ -eq "("){$_} }| Measure-Object).Count | Should Be 2
        }

        It "Query should have 2 of the ')' char" {
            ($Query.toCharArray() | ForEach-Object {If($_ -eq ")"){$_} }| Measure-Object).Count | Should Be 2
        }

        It "The second last char in the query should be ')'" {
            $Query[$Query.length - 2] | Should Be ")"
        }

        It "Query should contain '('" {
            $Query.contains("(") | Should Be $true
        }
        
        It "Query should contain ')'" {
            $Query.contains(")") | Should Be $true
        }
    }
}
Remove-Module fimmodule



