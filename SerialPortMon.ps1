<#
.SYNOPSIS
   Monitors data coming from a serial port such as COM ports
.DESCRIPTION
   This script can be used to view data coming from a serial port, such as an Arduino or SBC.
.EXAMPLE
   ./SerialPortMon.ps1 -port COM5
.EXAMPLE
   ./SerialPortMon.ps1 -port COM5 -baud 115200
.EXAMPLE
   ./SerialPortMon.ps1 -port COM5 -baud 115200 -clear
.LINK
   https://github.com/stevemcilwain/SerialPortMon
.AUTHOR
   Steve Mcilwain (@stevemcilwain), 2020
.LICENSE
   MIT
#>

Param (
    [Parameter(Mandatory = $true, HelpMessage = "Name of the COM port to monitor.")][string]$port,
    [Parameter(HelpMessage = "Set the baud rate for the port.")][string]$baud = "9600",
    [Parameter(HelpMessage = "Clear the screen before running.")][switch]$clear
)

# Clear the screen if switch is present
if ($clear) { [System.Console]::Clear(); }

# Banner
Write-Output(" ");
Write-Output("**************************************************")
Write-Output(" SerialPortMon ");
Write-Output("**************************************************")
Write-Output(" ");

# List available ports
$ports = [System.IO.Ports.SerialPort]::getportnames();
$ports_list = $ports -join ",";
Write-Output "[*] Availabe ports: $ports_list";

# Parse baud rate
[Int32]$baudrate = 0;
$result = [Int32]::TryParse($baud, [ref]$baudrate)

# Connect port
$p = new-Object System.IO.Ports.SerialPort $port, $baudrate, None, 8, one;
$p.ReadTimeOut = 1000;
Write-Host "[*] Monitor: Connecting to $port " -NoNewline;

#
# cleanup: try not to leave anything lingering
#
function cleanup() {
    try {
        $p.close();
        Write-Output "[*] Monitor: Closed $port"
    }
    catch {}
}

# This will allow CTRL-C to stop the script
[console]::TreatControlCAsInput = $false;

# Try to access COM port 20 times before giving up
if ( -not $p.IsOpen) {
    for ($num = 1 ; $num -le 20 ; $num++) {

        try {
            $p.open();  
        }
        catch [System.IO.IOException] {
            Write-Host -NoNewline ".";
        }
        catch {
            Write-Host -NoNewline ".";
        }
        
        Start-Sleep -Seconds 1;
    }
}

Write-Output(" ");

# Disable CTRL-C, instead user has to press "Q"
[console]::TreatControlCAsInput = $true;

$currentColor = $host.ui.RawUI.ForegroundColor;
$host.ui.RawUI.ForegroundColor = "Red";
Write-Output "[!] Use Q to exit";
$host.ui.RawUI.ForegroundColor = $currentColor;

# Loop forever while reading lines from serial port
while ($true) {

    if ($p.IsOpen) {
        try {
            $p.ReadLine();
        }
        catch [TimeoutException] {
            #do nothing on timeout
        }
        catch {
            #Write-Output $_;
        }
    }
    else {
        Write-Output "x";
        Write-Output "[*] Monitor: Unable to connect to $port"
        cleanup;
        break;
    }  

    if ($Host.UI.RawUI.KeyAvailable -and ("q" -eq $Host.UI.RawUI.ReadKey("IncludeKeyUp,NoEcho").Character)) {
        Write-Output "[*] Monitor: exiting..."
        cleanup;
        break;
    }

}

Write-Output(" ");