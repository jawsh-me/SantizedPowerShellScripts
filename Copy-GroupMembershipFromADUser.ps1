<#
.Synopsis
	Copies AD Group Membership from one user to another.
.Description
	Copies AD group membership from $CopyFromUser to $CopyToUser excluding any groups that match names specified in $ExcludeList which should be a return separated list of groups, and defaults to ./ExcludeGroups.txt.
.Example
	Copy-GroupMembershipFromADUser.ps1 -CopyFromUser FBMendelssohn -CopyToUser lvkoopa
.Example
	Copy-GroupMembershipFromADUser.ps1 -CopyFromUser FBMendelssohn -CopyToUser lvkoopa -ExcludeList "C:\AlternateList.txt"
.Notes
	Outputs to the console with a "short" Log, as well a more standardized log output as a file (see $OutFile variable in the Out-JLog function below)
#>
<#
	===================================================================

	NAME:			Copy-GroupMembershipFromADUser
	AUTHOR:			Josh Jones
					Scripts@jawsh.me
					https://github.com/jawsh-me
	CREATED:		2022-11-07
	LAST REVISED:	2022-11-07

	===================================================================

#>

Param(
	[Parameter(Mandatory=$True)]
	[ValidateScript({
		Try{Get-ADUser -Identity $_}
		Catch{Throw "Could not find $_"}
	})]
	[String] $CopyFromUser,

	[Parameter(Mandatory=$True)]
	[ValidateScript({
		Try{Get-ADUser -Identity $_}
		Catch{Throw "Could not find $_"}
	})]
	[String] $CopyToUser,

	[Parameter(Mandatory=$false)]
	[ValidateScript({
		if( -Not ($_ | Test-Path -pathType Leaf) ){throw "$_ does not exist or is not a file."}
		return $true
	})]
	[String] $ExcludeList = "./ExcludeGroups.txt"
)


Function Out-JLog() {
	Param(
		[Parameter(Mandatory=$true, Position=1)]
		[System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
		[string] $LineItem,
		[Parameter(Mandatory=$false)]
		[string] $OutFile = "./log_Copy-GroupMembershipFromADUser.txt",
		[Parameter(Mandatory=$false, Position=2)]
		[bool] $isError = $false
	)
	$AppName = "Copy-GroupMembershipFromADUser.ps1"
	$DateL = get-date -UFormat "%Y-%m-%dT%T %Z"
	$DateS = get-date -Uformat "%T"
	$HostN = $env:COMPUTERNAME
	$LongOutput = "$DateL`t$HostN`t$AppName`[$PID`] : $LineItem"
	Out-File  -Append -FilePath $OutFile -InputObject $LongOutput
	if ($isError) {Write-Host "`[$DateS`]`t$LineItem" -BackgroundColor Black -ForegroundColor Red}
	else {Write-Host "`[$DateS`]`t$LineItem"}
	
}

$excludeGroupNames = Get-Content -Path $ExcludeList
$MemberOfs = ((Get-ADUser -Identity $CopyFromUser -Properties memberOf).memberOf | Get-ADGroup) | Select-Object -ExpandProperty Name

foreach ($G2Add in $MemberOfs) {
	$GroupObj = Get-ADGroup -Identity $G2Add
	$GN = $GroupObj.Name
	If ($excludeGroupNames -notcontains $GN) {
		Try{
			Add-ADGroupMember -Identity $GroupObj -Members $CopyToUser
			Out-JLog -LineItem "[S] Added $CopyToUser to $GN"
		}
		Catch{Out-JLog -LineItem "[!] Failed to add $CopyToUser to $GN! - May need to add manually! `n`n$error`n`n" -isError $True} 
	}
	else {Out-JLog -LineItem "[i] Skipped adding $CopyToUser to $GN due to being on the exclusion list."}
}