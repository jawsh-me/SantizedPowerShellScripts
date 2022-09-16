# SantizedPowerShellScripts
A collection of my PowerShell Scripts that I've sanitized for general use

### MyFunctions.ps1
MyFunctions is a (very small) sample of the functions I keep in my PowerShell Profile at my dayjob, though most of my most useful functions cannot easily be sanitized and shared. 

### Unlocker.ps1
Unlocker was one of my earliest PowerShell scripts and was made to quickly and easily allow our helpdesk reps to see locked out accounts and unlock them.

### Get-SecurityLockoutEvents.ps1
This one is *really* handy when you have someone who's getting locked out "for no reason". Once configured for your enviornment, it allows you to easily query your domain controllers (DCs) for lockout events and identify the computer that caused them. This helps pinpoint the cause of these mystery lockouts.

### Set-LinkedMaster.ps1
I work in a multi-domain environment where we use Exchange in only our primary domain. If you need this, you probably already know you need it. This is a massive improvement over the script we used previously, and has some built-in credential managmeent bits (which can be ignored completely) that I find really handy, and will likely break out into their own piece at some point. 