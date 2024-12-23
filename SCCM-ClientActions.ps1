#
#
#   SCCM Client Actions (Powershell)
#   tking251
#   17-Dec 2024
#
#
#Some initialization required
$path = (Get-Command powershell.exe).Path
[string]$hostname = (Get-WmiObject Win32_Computersystem).name
[bool]$debug = $false

# Elevated Console?
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Restarting PowerShell with elevation..."
# Restart as elevated Powershell instance
    Start-Process -FilePath $path -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    exit
}

#Welcome message
Write-Host `n"Tim's Magic SCCM Actions Powershell!" -ForegroundColor Green

Write-Host `n"Powershell is running with elevation on $($hostname)"

#
#   SCCMCommand
#   This class holds the data for the SCCM commands
#   Variables:
#                   Name (string) - Holds the display name of each command
#                   GUID (string) - Holds the GUID value that is passed to WMIC to call the command
#                   result        - Holds the output of Invoke-WmiMethod
#   Functions:
#                   InvokeCommand (void) - Passes the data to WMI through "Invoke-WmiMethod" cmdlet      
#                   This is also where the name and result of the command are displayed in the console
#                   https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/invoke-wmimethod?view=powershell-5.1
#     
#                   Hopefully MS does not remove this functionality in future Windows releases >:(
#              
#                   Oh Microsoft, you've made a change,
#                   A shift that feels both harsh and strange.
#                   WMIC's gone, my script’s undone,
#                   A tool I trusted, now no longer fun :(
#

class SCCMCommand {
    [string]$Name
    [string]$Guid

    #constructor
    SCCMCommand([string]$name, [string]$guid){
        $this.Name = $name
        $this.Guid = $guid
    }

    [void]InvokeCommand() {
        try {
            $result = Invoke-WmiMethod -Namespace root\ccm -Class SMS_CLIENT -Name TriggerSchedule -ArgumentList $this.guid
            $this.SuccessMessage($result)
        }
        catch {
            Write-Error "$($this.Name): FAILED: $($_.Exception.Message)"
            #Used for testing this script when it breaks ¯\_(ツ)_/¯
            if($debug = $true)
            {
                Write-Host "Exception details: $($_.Exception)"
                Read-Host -Prompt "Press Enter to continue"
            }
        }
    }

    [void]SuccessMessage([string]$details)
    {
            Write-Host `n"$($this.Name): Successfully pushed for client"
            Write-Host "Output: $details" -ForegroundColor DarkGray
    }
}

# Create new objects for each command this script performs.
# You can add new commands as needed by referencing the table on:
# https://learn.microsoft.com/en-us/mem/configmgr/develop/reference/core/clients/client-classes/triggerschedule-method-in-class-sms_client

$commands = @(
    [SCCMCommand]::new("Discovery Data Collection Cycle", "{00000000-0000-0000-0000-000000000003}"),
    [SCCMCommand]::new("File Collection Cycle", "{00000000-0000-0000-0000-000000000010}"),
    [SCCMCommand]::new("Hardware Inventory Cycle", "{00000000-0000-0000-0000-000000000001}"),
    [SCCMCommand]::new("Machine Assignments Cycle", "{00000000-0000-0000-0000-000000000021}"),
    [SCCMCommand]::new("Machine Policy Evaluation Cycle", "{00000000-0000-0000-0000-000000000022}"),
    [SCCMCommand]::new("Application Policy Cycle", "{00000000-0000-0000-0000-000000000121}"),
    [SCCMCommand]::new("Software Inventory Cycle", "{00000000-0000-0000-0000-000000000002}"),
    [SCCMCommand]::new("Software Updates Evaluation Cycle", "{00000000-0000-0000-0000-000000000108}"),
    [SCCMCommand]::new("Software Update Scan", "{00000000-0000-0000-0000-000000000113}")
)

#Loop through execution of each command


$i = 0 #Can be used for a progress bar
foreach ($command in $commands) {
    $command.InvokeCommand()
    $i++
}

Write-Host `n"SCCM Actions Finished, it is now safe to remove USB." -ForegroundColor Yellow
Write-Host `n"Updating Group Polciy..."
Invoke-Command -ScriptBlock {gpupdate /force}

#OPTIONAL - comment the next line out if you want the script to end immediately after gpupdate.
#Read-Host -Prompt "Press Enter to exit"