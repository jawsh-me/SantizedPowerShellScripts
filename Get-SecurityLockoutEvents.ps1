# Things you'll need to change:
	# 	The "ValidateSet" in the Parameters for location below, these define the sets of domain controllers you'll be checking against. It's named location, because in our enviornment we always know what location someone will be connecting from, but not what DC they'll necessarily authenticate against. Anything on this list must have a matching entry in the switch statement below
	# 	The $DomainSuffix variable below the Param block to match your own domain's suffix. If you're working with multiple domains, you could instead modify this script to use the FQDN in the switch statement. 
	# 	The DCs for each location/group in the switch statement

# Things you might /want/ to change:
	#	The $OutPath Variable if you don't like the default naming convention of the results file
	#	The $IgnoreThisAccount variable if you want to ignore specific accounts
	#	Uncomment the last line of the script to automatically open the results in notepad when finished.

Param(
	[Parameter(Mandatory=$false)]
	# Change the below set to your own locations/DCs/groups of DCs, must have matching entries in the switch statement below
	[ValidateSet('HQS','Site1','Site2','Colo', 'Azure')]
	[string] $Location = "HQS", # Change this to set the default DC/group
	[Parameter(Mandatory=$false)]
	[ValidateScript({
		if( -Not ($_ | Test-Path -pathType Container) ){throw "Folder does not exist or is a file."}
		return $true
	})]
	[String] $FolderPath = "~\Desktop\" # Change this to change where the default output is.
)

$DomainSuffix = ".ad.example.com" # Change to your own domain suffix (must have the first ".")
$IgnoreThisAccount = "_SVC_*" # Used to ignore Service accounts in my environment, you can modify this and/or the "-notlike" statement it's used in below to ignore accounts you don't care about events for in your environment. 

# Append a \ if path doesn't already have one, just in case it's changed on the CLI
If (($FolderPath.Substring(($FolderPath.Length) - 1)) -ne "\") {$FolderPath = $FolderPath + "\"}

$CurDate = Get-Date -UFormat "%Y-%m-%d"
$OutPath = "$FolderPath$CurDate-$Location.csv"

switch ($Location){ # Must have matching entries in the ValidateSet in the param block
	HQS 	{
			 $DCList = ("HQS-DC01",
						"HQS-DC02", 
						"HQS-BDC01", 
						"HQS-RODC01")
			}
	Site1 	{$DCList = "S1-DC01"}
	Site2 	{$DCList = "S2-DC01"}
	Colo 	{
			 $DCList = ("Colo-DC01",
						"Colo-DC02",
						"Colo-RODC01")
	   }
	Azure 	{
			 $DCList = ("AZ-DC21",
			 			"AZ-DC22")
			}
	Default {exit}
}

# The loop that actually collects the events and writes them to the output file
ForEach ($DCName in $DCList) {
	Write-Host "Checking $DCName..." -ForegroundColor Green
	$count = 0
	$IgnoredCount = 0
	$DCFQDN = $DCName + $DomainSuffix
	$ColEvents = (Get-WinEvent -ComputerName $DCFQDN -FilterHashTable @{LogName='Security'; ProviderName='Microsoft-Windows-Security-Auditing'; ID=4740})
	ForEach ($Event in $ColEvents) {
		$EventHash = @{
			Server = $DCName
			Time = $Event.TimeCreated
			UserID = [String]$Event.Properties[0].Value
			CallingComputer = [String]$Event.Properties[1].Value
		}
		if ($EventHash.UserID -notlike $IgnoreThisAccount) {
			$EventHashObject = New-Object PSObject -Property $EventHash
			$EventHashObject | Select-Object Server, Time, UserID, CallingComputer | Sort-Object -Property Time -Descending |  Export-Csv -Path $OutPath -NoTypeInformation -Append
			$count++
		}
		else {
			$IgnoredCount++
		}

	}
	Write-Host "Wrote $count events for $DCName and ignored $IgnoredCount entries."
}
Write-Host "Finished Write operation."
# Uncomment the below to automatically open results when done.
# notepad.exe $OutPath
