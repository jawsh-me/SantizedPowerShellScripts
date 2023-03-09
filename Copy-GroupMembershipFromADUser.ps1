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
	LAST REVISED:	2023-03-09

	Changelog:
		Rev 1 2023-02-01
			(somewhat sloppy) re-write of main section to account for Security vs Distribution groups

		Rev 2 2023-03-09
			Added comments explaining the code
			cleaned up some formatting
			renamed some of the "sloppy" variables to reflect their purpose

	Todo:
	- Cleanup main loop, too much redundant code (maybe try to make it a switch statement as well?)
	- Clarify/modularize the success/error/information symbols and move that functionaility into the Out-Jlog function
	- Test with other PowerShell/Exchange versions and environments where Exchange is not present
	- Add option to set log output as parameter

	===================================================================

#>

# Parameter setups
Param(
	# CopyFromUser:
	[Parameter(Mandatory=$True)]
	[ValidateScript({
		# This try/catch block makes sure the user can be found, and stops the script from running if it cannot find them
		Try{Get-ADUser -Identity $_ -ErrorAction stop}
		Catch{Throw "Could not find $_"}
	})]
	[String] $CopyFromUser,

	# CopyToUser:
	[Parameter(Mandatory=$True)]
	[ValidateScript({
		# Same as above, this ensures the CopyToUser can be found, and stops execution if it cannot.
		Try{Get-ADUser -Identity $_ -ErrorAction stop}
		Catch{Throw "Could not find $_"}
	})]
	[String] $CopyToUser,

	# ExcludeList:
	[Parameter(Mandatory=$false)]
	[ValidateScript({
		# Validate that the file exists and is a file (specifically not a directory.) This does /not/ ensure the file is a valid list of groups, however.
		if( -Not ($_ | Test-Path -pathType Leaf) ){throw "$_ does not exist or is not a file."}
		return $true
	})]
	# Assume the list is a file called ExcludeGroups.txt in the current directory if not specified
	[String] $ExcludeList = "./ExcludeGroups.txt"
)


Function Out-JLog() {
<# This function does 2 things when called:
	1. Outputs what I call a "Short log" to the console with a basic timestamp and the passed information, if labeled a warning, do so in a red/black color scheme.
	2. Writes a log file to the $OutFile location, set just below this, with default value of "log_Copy-GroupMembershipFromADUser.txt" in the current directory in a more format that is more compatible with systems designed to ingest linux logs. This doesn't follow that standard exactly, however, and may need adjustments if you want this to play nicely with your log parsing software.
#>
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
	$DateLong = get-date -UFormat "%Y-%m-%dT%T %Z"
	$DateShort = get-date -Uformat "%T"
	$PCHostname = $env:COMPUTERNAME
	$LongOutput = "$DateLong`t$PCHostname`t$AppName`[$PID`] : $LineItem"
	Out-File  -Append -FilePath $OutFile -InputObject $LongOutput
	if ($isError) {Write-Host "`[$DateShort`]`t$LineItem" -BackgroundColor Black -ForegroundColor Red}
	else {Write-Host "`[$DateShort`]`t$LineItem"}
}

# Grab the contents of the $ExcludeList file to be compared against
$excludeGroupNames = Get-Content -Path $ExcludeList

# Grab the group membership information from $CopyFromUser and store that list. Also stores the "GroupCategory" to determine distribution/security group, as the commands for working with the two are different (at least in the Windows PowerShell/Exchange versions we use)
$MemberOfs = ((Get-ADUser -Identity $CopyFromUser -Properties memberOf).memberOf | Get-ADGroup) | Select-Object Name,GroupCategory

# The remainder of the script is the main loop. For each group to add, determine if the group is distribution or security, then try to run the appropriate command to join $CopyToUser to that group, assuming the group doesn't exist in the ExcludeList file. Log all relevant information with the Out-JLog function.
foreach ($GroupToAdd in $MemberOfs) {
	# Set the $AddSuccessState to false at the beginning of each loop, this is referenced below to determine if a group was able to be added. This /shouldn't/ be needed as the catch blocks will set this to false, but having it here (hopefully) means it should be impossible to produce a false positive message.
	$AddSuccessState = $false

	# Distribution Group Handling
	If ("Distribution" -eq $GroupToAdd.GroupCategory){
		$GroupObject = Get-DistributionGroup -Identity $GroupToAdd
		$GroupName = $GroupObject.Name
		If ($excludeGroupNames -notcontains $GroupName) {
			Try{
				Add-DistributionGroupMember -Identity $GroupObject -Members $CopyToUser -ErrorAction stop
				$AddSuccessState = $True
			}
			Catch{$AddSuccessState = $false}
		}else {Out-JLog -LineItem "[i] Skipped adding $CopyToUser to $GroupName due to being on the exclusion list."}
	}

	# Security Group Handling
	elseif ("Security" -eq $GroupToAdd.GroupCategory) {
		$GroupObject = Get-ADGroup -Identity $GroupToAdd
		$GroupName = $GroupObject.Name
		If ($excludeGroupNames -notcontains $GroupName) {
			Try{
				Add-ADGroupMember -Identity $GroupObject -Members $CopyToUser -ErrorAction stop
				$AddSuccessState = $True
			}
			Catch{$AddSuccessState = $false}
		}else {Out-JLog -LineItem "[i] Skipped adding $CopyToUser to $GroupName due to being on the exclusion list."}
	}

	# Throw an error if the group type is not Security nor Distribution
	Else {
		$ErroringGroupName = $GroupToAdd.Name
		Out-JLog -LineItem "[!!] Unable to process due to unaccounted for GroupCategory of $ErroringGroupName" -isError $True
	}

	# Log the success/failure via Out-Jlog
	if($AddSuccessState){
		Out-JLog -LineItem "[S] Added $CopyToUser to $GroupName"
	}
	else{
		Out-JLog -LineItem "[!] Failed to add $CopyToUser to $GroupName! - May need to add manually! `n`n$error`n`n" -isError $True
	}

}
