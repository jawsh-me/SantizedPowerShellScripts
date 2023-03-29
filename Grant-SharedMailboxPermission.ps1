<#
.Synopsis
	Grants FullAccess and/or Send-as permissions to a shared mailbox for a given list of users
.Description
	Grants the FullAccess and/or the Send-as permissions to a specified user, or list of users, for a specified shared mailbox. Normally this is 2 separate cmdlets (Add-MailboxPermission and Add-RecipientPermission)
.Example
	Grant-SharedMailboxPermission -User LVKoopa@example.org -Identity sharedboxWithFullAccessOnly@example.org -FullAccess
	.Example
	Grant-SharedMailboxPermission -User LVKoopa@example.org,FBMendlessohn@example.org,RGBiv@example.org -Identity sharedboxWithSendAsOnly@example.org -SendAs
	.Example
	Grant-SharedMailboxPermission -User "LVKoopa" -Identity sharedboxWithBoth@example.org -FullAccess -SendAs
.Notes
	Must supply either the FullAccess or SendAs flags for any action to be taken, otherwise this will exit without taking any action. 
	While the User parameter can take a list of inputs, the identity parameter cannot at this time. (Todo)
	
#>
<#
 	===================================================================
	NAME:			Grant-SharedMailboxPermission.ps1
	AUTHOR:			Josh Jones
					Scripts@jawsh.me
					https://github.com/jawsh-me
	CREATED:		2023-03-29
	LAST REVISED:	2023-03-29
	===================================================================

	Changelog:
		0.99
			(Init) Initial build
			(Feat) Allow for array of users
			(Feat) Grant SendAs/FullAccess permission

	ToDo:
		Allow for a list of Identities AND/OR list of users (via parameter sets?)

	===================================================================
#>

# Setup

# Parameter setup
Param(
	[Parameter(Mandatory=$True,
	Position=0,
	HelpMessage="Enter an identifier for the Shared Mailbox you're adjusting the permissions on:"
	)]
	[string] $Identity,

	[Parameter(Mandatory=$True,
	Position=1,
	HelpMessage="Enter an identifier for the user you're granting these permissions to:"
	)]
	[string[]] $User,

	[switch] $FullAccess,

	[switch] $SendAs
)

# Message Splat setup for success/failure
$SuccessArgs = @{
	ForegroundColor = "Green"
	# BackgroundColor = "Black"
}
$FailArgs = @{
	ForegroundColor = "Red"
	# BackgroundColor = "Black"
}

# Action

# If no access is set, exit
if(!$FullAccess -and !$SendAs){
	Write-Host "Nothing to do... Exiting." @FailArgs
	Exit
}
# Main Loop
foreach($u in $User){
	if($FullAccess){ # Add FullAccess
		Write-Verbose "Attempting to add Full Access permission to $Identity for $u"
		try {
			Add-MailboxPermission -AccessRights FullAccess -AutoMapping $True -Identity $Identity -User $u -ErrorAction stop
			Write-Host "Added FullAccess permission to $Identity for $u." @SuccessArgs

		}
		catch {
			Write-Host "[!] Unable to add FullAccess permission to $Identity for $u." @FailArgs
			$Error
		}
	}
	if($SendAs){ # Add Send-as
		Write-Verbose "Attempting to add Send-as permission to $Identity for $u"
		try {
			Add-RecipientPermission -Identity $Identity -AccessRights SendAs -Trustee $u -confirm:$false -ErrorAction stop
			Write-Host "Added Send-as permission to $Identity for $u." @SuccessArgs

		}
		catch {
			Write-Host "[!] Unable to add Send-as permission to $Identity for $u." @FailArgs
			$Error
		}
	}
}