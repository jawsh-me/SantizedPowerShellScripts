# Create a SpeachSynthesizer
Add-Type -AssemblyName System.speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

# Setup list of voices
$voiceList = $speak.getinstalledvoices().voiceinfo.name
[int]$count = 1
$modifiedVoiceList = [System.Collections.ArrayList]::new()
foreach ($v in $voiceList) {
	$cl = "&" + $count + $v +
	$count++ 
	$modifiedVoiceList.Add($cl)
}

# Prompt user to select voice
$selectVoice = ([System.Management.Automation.Host.ChoiceDescription[]] @($modifiedVoiceList))
[int]$selectVoiceDefault = -1
$voiceInt = $host.UI.PromptForChoice("Which Voice would you like to select?", "test", $selectVoice, $selectVoiceDefault)

$voice = $voiceList[$voiceInt]
$speak.SelectVoice($voice)

# Set rate, volume, and output
$speak.rate = 1.25
$speak.volume = 85
$speak.SetOutputToDefaultAudioDevice()

# Below line can be uncommented to export results to "test.wav" instead. I typically also comment out the above line when doing so.
# $speak.SetOutputToWaveFile(test.wav)

# Do the speaking! Prompt user for what to say, if they say "stop" then end the loop, and therefor the script. 
$speach = "What would you like me to say?"
write-host "Type `"stop`" to exit."
while ("stop" -ne $speach) {
	$speak.speak($speach)
	$speach = Read-Host -Prompt "What would you like it to say?"
}
