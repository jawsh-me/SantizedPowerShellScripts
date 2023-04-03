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

function Add-Decoration {
	param (
		[CmdletBinding(DefaultParameterSetName='String')]

	# InputList
		[Parameter(
			ValueFromPipeline=$true,
			ParameterSetName='List',
			Mandatory=$true,
			Position=0,
			HelpMessage="This should be an ArrayList object of the lines you want to decorate (usually you'll want to pass this as a viarable)"
		)]
		[System.Collections.ArrayList] $InputList,

	# InputString
		[Parameter(
			ValueFromPipeline=$true,
			ParameterSetName='String',
			Mandatory=$true,
			Position=0,
			HelpMessage="Enter the string you would like decorated:"
		)]
		[string] $InputString,

	# DecorationHashtable
		[Parameter(
			Mandatory=$false,
			Position=1,
			HelpMessage="This is a hashtable that defines the decorations."
		)]
		[ValidateScript({
			if(($_.LeftCorner) -and ($_.RightCorner) -and ($_.LeftLine) -and ($_.RightLine) -and ($_.Middle)){$true}
			else {throw "$_ did not contain one or more of the necessary attributes (LetCorner, RightCorner, LeftLine, & RightLine)"}
		})]
		[System.Collections.Hashtable] $DecorationHashtable = @{
			LeftCorner  = "[]="
			RightCorner = "=[]"
			LeftLine    = "|| "
			RightLine   = " ||"
			Middle      = "="
		}
	)
	
	begin{ # Wrap InputString in an ArrayList for compatibility, splitting newlines into new list objects
		$InputList =[System.Collections.ArrayList]@() 
		if ($InputString){
			foreach ($l in ($InputString.Split("`n"))){
				$InputList.Add($l) | Out-Null
			}
		}
	}
	
	process {
		# Create CornerRow (top and bottom)
			$LineMaxLength = (($InputList | Measure-Object length -Maximum).Maximum)
			$CornerRow = $DecorationHashtable.LeftCorner
			$i = -2
			while ($i -lt $LineMaxLength) {
				$CornerRow += $DecorationHashtable.Middle
				$i++
			}
			$CornerRow += $DecorationHashtable.RightCorner

		# build and export output
			$Output = "$CornerRow`n"
			foreach($line in $InputList){
				$Output +=  "{0} {1, -$LineMaxLength} {2}`n" -f $DecorationHashtable.LeftLine, $line, $DecorationHashtable.RightLine
			}
			$Output += "$CornerRow`n"
			$Output
	}
}
