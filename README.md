# SantizedPowerShellScripts
## A collection of my PowerShell Scripts that I've sanitized for more general use

### MyFunctions.ps1
MyFunctions is a (very small) sample of the functions I keep in my PowerShell Profile at my dayjob, though most of my most useful functions cannot easily be sanitized and shared. Get-AccountFromSID is one I use quite a lot (don't forget to fill out your own domain's SID prefix, though!)

### Unlocker.ps1
Unlocker was one of my earliest PowerShell scripts and was made to quickly and easily allow our helpdesk reps to see locked out accounts and unlock them. This runs interactively only.

### Get-SecurityLockoutEvents.ps1
This one is *really* handy when you have someone who's getting locked out "for no reason". Once configured for your enviornment, it allows you to easily query your domain controllers (DCs) for lockout events and identify the computer that caused them. This helps pinpoint the cause of these mystery lockouts.

### Set-LinkedMaster.ps1
I work in a multi-forest environment where we use Exchange in only our primary domain/forest. If you need this, you probably already know you need it. This is a massive improvement over the script we used previously, and has some built-in credential managmeent bits (which can be ignored completely) that I find really handy, and will likely break out into their own piece at some point.

### PSTalkToMe.ps1
A script I wrote for fun a while back to create a speech synth object with PowerShell and give it things to say. Mostly pointless on it's own, but the folks over on my SpiceWorks post about this had some great ideas for incorporating this idea into other scripts and tasks, such as remotely reminding a user that their PC is about to reboot when they "don't see" the pop-up warnings. 

### Copy-GroupMembershipFromADUser.ps1
Copying groups from one user to another in AD is a relatively simple task, but one that I get a lot of requests to do, so I've written this script to automate the task and automatically exclude a list of groups that will likely not be relevant to new employees but shouldn't be deleted. This could be relatively easily modified to disable the ignore list if needed. 

### Grant-SharedMailboxPermission.ps1
Quick script I threw together to add multiple users to shared mailboxes, as, by default, the cmdlets for doing so don't do quite what I needed them to for my environment, and the GUI is excruciatingly slow, even if it does what I need a bit cleaner. This hasn't been particularly well tested yet, so please give any feedback you have on it. 
