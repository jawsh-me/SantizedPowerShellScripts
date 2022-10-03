Function Out-JLogLine() { #Logs output to both the console (in simple log form) and a log file (with extra info for your log parsing tool to use later)
	Param(
		[Parameter(Mandatory=$true, Position=1)]
		[System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
		[string] $LineItem,
		[Parameter(Mandatory=$true, Position=0)]
		[System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
		[string] $AppName,
		[Parameter(Mandatory=$false)]
		[string] $OutFile = "./log.txt"
	)
	$DateL = get-date -UFormat "%Y-%m-%dT%T %Z"
	$DateS = get-date -Uformat "%T"
	$HostN = $env:COMPUTERNAME
	$LongOutput = "$DateL`t$HostN`t$AppName`[$PID`] : $LineItem"
	Out-File  -Append -FilePath $OutFile -InputObject $LongOutput
	Write-Host "`[$DateS`]`t$LineItem"
}

Function Get-AccountFromSID() { # Gets a human-readable account name from the SID. Replace the *s below with your primary domain's identifier for quick-usage with only the RID. E.g. When I do "Get-AccountFromSID 500" I get the defualt domain admin account.
	Param(
		[Parameter(position=0, Mandatory=$True)]
		[System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
		[String] $InSID
	)
	if ($InSID -notlike "S-1-5-21*") {$WorkingSID = "S-1-5-21-******************" + $InSID}
	else {$WorkingSID = $InSID}
	$ObjectSID = New-Object System.Security.Principal.SecurityIdentifier ($WorkingSID) 
	$OutUser = $ObjectSID.Translate([System.Security.Principal.NTAccount]) 
	$OutUser.Value
}

Function Get-JConfirm { # Uses prompt for choice for a simple yes/no question. I use this in some of my simpler interactive scripts as a quick "Are you sure?" 
	Param($Question)
	$options = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
	[int]$defaultchoice = 0
	$opt = $host.UI.PromptForChoice($Question , $null , $Options,$defaultchoice)
	switch($opt)
	{
		0 {return $True}
		1 {return $False}
	}
}
