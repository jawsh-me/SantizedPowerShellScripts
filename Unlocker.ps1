#   ===========================================================================
#
#   NAME:			Unlocker.ps1
#   AUTHOR:			github@jawsh.me
#   LAST REVISED:	January 16, 2019
#   VERSION:		1.01
#
#   Displays accounts that are locked out in current domain and asks for the 
#   account name of the one you'd like to unlock and attempts to unlock it.
#   Loops until given the string "stop"
#   Passing the string "r" will display a new list of locked users.
#   
#   Requires the ActiveDirectory module to be available.
#
#   ===========================================================================

Import-Module ActiveDirectory
$accToUnlock = $null
# main loop, stops when $accToUnlock = stop
while ($accToUnlock -ne 'stop') {
	#display the currently locked accounts and ask to enter SamAccountName of the one you'd like to unlock
	Write-Host "The following accounts are currently locked out:"
	Search-ADAccount -LockedOut | Format-Table Name, SamAccountName
	$accToUnlock = Read-Host -Prompt 'Please enter the SamAccountName for the account you would like to unlock: ("stop" to cancel, "r" to reload the list)'
	if ($accToUnlock -eq 'stop') {continue} # If given stop, this is necessary to break the loop here
	if ($accToUnlock -eq 'r') {continue} # restart the loop on 'r' to refresh the list of locked accounts without running the lower part of the loop.

	#attempt to unlock given account
	Write-Host "Unlocking '$accToUnlock'..."
	Unlock-ADAccount -Identity $accToUnlock
}
Write-Host "Stopping..."
