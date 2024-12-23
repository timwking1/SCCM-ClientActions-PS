# SCCM-ClientActions-PS
A Powershell Script for running SCCM client actions quickly

🪦 R.I.P. WMIC 😭

This script will call several useful actions all at once on an SCCM client.
It also contains a few conveniences for my specific use-case including:
*Restarting itself with elevation
*Automatically updating group policy via gpupdate /force
*Getting the system's computer name (can be useful for diagnosing Active Directory issues)

Actions are fairly easy to add or remove by modifying the $commands array while referencing the table on:
https://learn.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client

Note that while the SCCM client will return success status when actions are called, 
this doesn't actually mean it is communicating with an SCCM DP or Management Server.
Therefore this script will not really help for troubleshooting network or SCCM server issues, everything is client side.
