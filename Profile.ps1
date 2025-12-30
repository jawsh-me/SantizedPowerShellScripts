# Jawsh-me's PSProfile, Sanitized for distribution
# organization template loosely based on TFL/DoctorDNS's template at https://github.com/doctordns/PacktPS72/blob/main/Scripts/Goodies/Microsoft.PowerShell_Profile.ps1

# 1. Statics
if ($PSVersionTable.PSVersion.Major -le 5) {$EscapeChar = [char]27
} else {$EscapeChar = "`e"}
$ResetSeq = "$EscapeChar[0m"
# $ResetNet = $([System.Console]::ResetColor())  # Might be able to replace the if statement due to this? Needs tested
$Today = get-date
switch ([System.Environment]::OSVersion.Platform) {
	Unix { $OS = "Unix" }
	Default { $OS = "$([char]0xf17a) Windows"}
}
if ($IsLinux) {$OS = " Linux"}
if ($IsMacOS) {$OS = " MacOS"}
$ShortOS = $OS.Substring(0,1)

# 2. Setup header and add host details
$Header = [System.Collections.ArrayList]@() #Header needs to be an ArrayList
$ME = ([Security.Principal.WindowsIdentity]::GetCurrent()).Name #Get Username via .Net for cross-compatibility
$PSVer = ($PSVersionTable.PSVersion.ToString())
$Header.Add("Logged on as [$ME]") | Out-Null # Out-Null when adding to header for speed and to prevent extra output
$Header.Add("On host      [$(hostname)]") | Out-Null
$Header.Add("PowerShell   [$PSVer]") | Out-Null
$Header.Add("At           [$Today]") | Out-Null
$Header.Add("OS Type      [$OS]") | Out-Null


# 3 change WindowTitle
$OrgWindowTitle = $host.ui.RAWUI.WindowTitle
$host.ui.RAWUI.WindowTitle = "PS $PSVer - $ME @ $(hostname) - $OrgWindowTitle"

# 4. Setup common paths
$Dt = "~\Desktop\"

# 5. Setup common company-specifics

	# Scrubbed - sorry! :) 


# 6. Setup functions

function Get-IsAdmin {
    if (($PSVersionTable.PSVersion.Major -le 5) -or ($PSVersionTable.Platform -like "Win*")) {
        return (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    } else {
        return ("root" -eq [System.Environment]::UserName)
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
		if ($InputString){
			$InputList =[System.Collections.ArrayList]@() 
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

function Get-ANSIColorTest {
	for ($i = 0; $i -lt 256; $i++) {
    	$ansi = "$EscapeChar[38;5;${i}m"
    	$text = "{0,-4}" -f $i
    	Write-Host "$ansi$text$ResetSeq" -NoNewline
    	if (($i + 1) % 16 -eq 0) { Write-Host "" }
	}
	for ($i = 0; $i -lt 256; $i++) {
    	$ansi = "$EscapeChar[48;5;${i}m"
    	$text = "{0,-4}" -f $i
    	Write-Host "$ansi$text$ResetSeq" -NoNewline
    	if (($i + 1) % 16 -eq 0) { Write-Host "" }
	}	
}

# 7. Set Aliases 
New-Alias -Name push -Value Push-Location
New-Alias -Name pop -Value Pop-Location


# 8. Display Header
Add-Decoration -InputList $Header

# 9. Prompt

# Define Colors by index
# 0 = EndedText, 1 = TimeText, 2 = UsernameText, 3 = EndedBG, 4 = IsAdminBG, 5 = PathBG, 6 = UserBG, 7 = TimeBGColor
$ThemeColors = "0", "46", "15", "22", "52", "159", "127", "0"
$FancyPrompt = $true # If True, use fancy Prompt
function tfp { $global:FancyPrompt = !$global:FancyPrompt } # Quick Toggle

function prompt {
    # Get last command time
    $LastCommand = Get-History -Count 1
    $ElapsedTime = ""
    if ($LastCommand) {
        $RunTime = ($LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime)
        $ElapsedTime = $RunTime.ToString("%hh\:%mm\:%s\.%fff")
    }

    # Choose characters based on $FancyPrompt
    if ($FancyPrompt) {
        $SeparatorChar = [char]0xe0b0  # 
        $UserInfoStarter = "$EscapeChar[38;5;$($ThemeColors[6])m" + [char]0xe0be  # 
        $PathReplaceChar = [char]0xe0bf  # 
        $SlashReplaceChar = [char]0xe0bd  # 
		$PSIndicator = "$([char]0xDB82)$([char]0xDE0A)" # 󰨊 
		if (Get-IsAdmin){ $PomptIndicator =  [char]0xf4df } else { $PomptIndicator =  [char]0xe0b1 }  #  or 
    } else {
        $SeparatorChar = ""
        $UserInfoStarter = ""
        $PathReplaceChar = "\"
        $SlashReplaceChar = "/"
		$PSIndicator = "PS"
		if (Get-IsAdmin){ $PomptIndicator =  "#" } else { $PomptIndicator =  ">" }  #  or 
		$ShortOS = ""
    }

    # Format path
    $PromptPath = " $(($PWD.ProviderPath).Replace($HOME, "~").Replace("\", $PathReplaceChar).Replace("/", $SlashReplaceChar))"

    # Compose header segment
    $HeaderSegment = @(
        "$EscapeChar[48;5;$($ThemeColors[3])m$EscapeChar[38;5;$($ThemeColors[0])m Ended: $(Get-Date -Format "ddd HH:mm:ss - yyyy/MM/dd") $EscapeChar[48;5;$($ThemeColors[7])m$EscapeChar[38;5;$($ThemeColors[3])m$SeparatorChar",
        "$EscapeChar[48;5;$($ThemeColors[7])m$EscapeChar[38;5;$($ThemeColors[1])m Took: [$ElapsedTime] $ResetSeq$EscapeChar[38;5;$($ThemeColors[7])m$SeparatorChar"
    ) -join ""

    # Compose user segment
    $UserInfoSegment = "$EscapeChar[38;5;$($ThemeColors[6])m$UserInfoStarter$EscapeChar[48;5;$($ThemeColors[6])m$EscapeChar[38;5;$($ThemeColors[2])m $([System.Environment]::UserName) @ $([System.Environment]::UserDomainName) "

    # Compose admin or transition separator
    if (Get-IsAdmin) {
        $AdminSeparator = "$EscapeChar[48;5;$($ThemeColors[4])m$EscapeChar[38;5;$($ThemeColors[6])m$SeparatorChar"
        $AdminSegment = "$AdminSeparator$EscapeChar[48;5;$($ThemeColors[4])m$EscapeChar[38;5;$($ThemeColors[2])m as Admin "
        $PathSeparator = "$EscapeChar[48;5;$($ThemeColors[5])m$EscapeChar[38;5;$($ThemeColors[4])m$SeparatorChar"
    } else {
        $AdminSegment = ""
        $PathSeparator = "$EscapeChar[48;5;$($ThemeColors[5])m$EscapeChar[38;5;$($ThemeColors[6])m$SeparatorChar"
    }

    $PathSegment = "$PathSeparator$EscapeChar[48;5;$($ThemeColors[5])m$EscapeChar[38;5;$($ThemeColors[7])m $PromptPath $ResetSeq$EscapeChar[38;5;$($ThemeColors[5])m$SeparatorChar"

    $UserSegment = @($UserInfoSegment, $AdminSegment, $PathSegment) -join ""

    Write-Host "`n$HeaderSegment$ResetSeq`n$ResetSeq`n$UserSegment$ResetSeq"

    return "  $ShortOS $PSIndicator $($PSVersionTable.PSVersion.Major) $PomptIndicator $ResetSeq"
}
