 Param(
# Exchange-domain account username, also used as subsidiary account name if one isn't provided
	[Parameter(Mandatory=$true)] 
	[System.Management.Automation.ValidateNotNullOrEmptyAttribute()]
	[string] $EXCHAccountUsername,

#Subsidiary account username, if not provided, assume same as Exchange account name
	[System.Management.Automation.ValidateNotNullOrEmptyAttribute()] 
	[string] $PrimaryAccountUsername = $EXCHAccountUsername,

#Subsidiary domains, if updating also add additions to the switch below
	[Parameter(Mandatory=$true)] 
	[ValidateSet('Domain1','Domain2','Domain3','Domain4')]   #---!!!---# Modify for your own environment, see switch statement on Line 38 #---!!!---#
	[string] $SubsidiaryDomain,

#flag to use credential files
	[switch] $UseCredFiles, 

#Folder path for Credential XMLs & check to make sure it's a folder
	[Parameter(Mandatory=$false)]
	[ValidateScript({
		if( -Not ($_ | Test-Path -pathType Container) ){throw "Credential XML folder `"XMLLoc`" does not exist or is a file."}
		return $true
	})]
	[string] $XMLLoc="~\creds\"
)

$EXCHDomain = "ExchangeDomain.com"  #---!!!---# Modify for your own environment #---!!!---#


Import-Module ActiveDirectory
$EXCHDC = (Get-ADDomain $EXCHDomain).PDCEmulator   #---!!!---# Modify for your own environment, doesn't need to be your PDCe #---!!!---#

#Switch to set Variables based on domain  

#---!!!---# Modify Everything between these tags to match your own environment #---!!!---#
# Also make sure the switch options here match the "ValidateSet" in the parameters
Switch ($SubsidiaryDomain){
	Domain1 {
		$AltDC="DC.Domain1.com"
		$CredFile="Domain1_Admin.xml"
	}
	Domain2 {
		$AltDC="DC.Domain2.com"
		$CredFile="Domain2_Admin.xml"
	}
	Domain3 {
		$AltDC="DC.Domain3.com"
		$CredFile="Domain3_Admin.xml"
	}
	Domain4 {
		$AltDC="DC.Domain4.com"
		$CredFile="Domain4_Admin.xml"
	}
}
#---!!!---#/Modify Everything between these tags to match your own environment #---!!!---#

#If the UseCredFiles switch is used, attempt to use existing XMLs in the specified location, if they don't exist, attempt to create them. If UseCredFiles isn't switched on, prompt for credentials
$CredUser = $SubsidiaryDomain + "\" + $env:USERNAME
If ($UseCredFiles){
	If (($XMLLoc.Substring(($XMLLoc.Length) - 1)) -ne "\") {$XMLLoc = $XMLLoc + "\"}
	$FullCredFile = $XMLLoc + $CredFile
	Try{$Cred=Import-Clixml -Path $FullCredFile}
	Catch{
		Write-Host "Could not load XML from $FullCredFile. Will attempt to create Cred XML for you."
		Try{
			$NewCred = Get-Credential -Credential $CredUser
			$Cred = $NewCred
			Export-Clixml -Path $FullCredFile -InputObject $NewCred
		}
		Catch{
			Write-host "Catastrophic failure, exiting..."
			Exit 10
		}
	}
}
Else{
	$Cred = Get-Credential -Credential $CredUser
}

$EXCHAccount = $EXCHDomain + "\" + $EXCHAccountUsername
$AltAccount = $SubsidiaryDomain + "\" + $PrimaryAccountUsername

Set-User -Identity $EXCHAccount -LinkedMasterAccount $AltAccount -DomainController $EXCHDC -LinkedDomainController $AltDC -Credential $Cred
