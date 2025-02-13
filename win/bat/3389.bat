@echo off
echo -------------------------------
echo - %~nx0
echo -
echo - Modify Windows Remote Desktop Port
echo - Note: The default remote port is 3389 (hexadecimal 0xD3D)
echo -
echo - Current Port (Decimal):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber"
echo -------------------------------
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [Administrator Mode]
) else (
    echo Error: Please right-click the file and select "Run as administrator"
    pause
    goto :EOF
)
:: Prompt user to enter the new RDP port
set /p rdp_port="Enter the port number to change (default is 3389): "
if "%rdp_port%"=="" set rdp_port=3389
echo - Press any key to confirm setting the Remote Desktop port to: %rdp_port%
pause
:: Update the registry with the new port number
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber" /t REG_DWORD /d %rdp_port% /f
echo - New Port (Decimal):
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber"
echo - Adding the new port to Firewall exceptions...
netsh advfirewall firewall add rule name="RDP Port %rdp_port%" profile=any protocol=TCP action=allow dir=in localport=%rdp_port%
echo -------------------------------
echo - Press any key to restart the TermService service to apply the new settings (Remote Desktop will be disconnected)
echo - If Remote Desktop is disconnected and cannot reconnect, try restarting the system to apply the changes
pause
echo - Restarting Remote Desktop service...
net stop TermService /y
net start TermService /y
:DONE
echo -------------------------------
echo - Completed
pause
