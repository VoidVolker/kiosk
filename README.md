# kiosk
Few simple experimental scripts to make kiosk mode

# Linux

Linux kiosk mode need next steps:

* Simple window manager
* Configuration of this window manager to use your application as shell
* User for autologon
* _[Option]_ Reverse ssh tunnel (inside script is test example) with autorun and autoreconnect
* _[Option]_ VPN connection to own server

# Windows
Windows kiosk mode need next steps:
* Create user for kiosk mode
* Set next registry key for this user as path to your programm:

```
Windows Registry Editor Version 5.00

[HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Winlogon]
"Shell"="C:\\full\\path\\to\\your\\programm.exe>"

``` 
* _[Option]_ If you need to disable Ctrl+Alt+Del, then use this registry key value (""):

```
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\taskmgr.exe]
"Debugger"="\"\""

```

