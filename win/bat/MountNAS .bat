@echo off
setlocal enabledelayedexpansion
:: 强制使用 UTF-8 编码以支持中文 [cite: 1]
chcp 65001 >nul
title Windows 11 NAS 映射工具 - 制作人: 小沨 [cite: 1]

:: --- ANSI 颜色代码定义 ---
set "ESC= "
for /F %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"
set "Cyan=%ESC%[96m"
set "Green=%ESC%[92m"
set "Red=%ESC%[91m"
set "Yellow=%ESC%[93m"
set "Reset=%ESC%[0m"

:: --- 视觉样式定义 ---
set "Line=%Cyan%==================================================%Reset%"
set "Author=%Yellow%               制作人: 小沨%Reset%"

:START
cls
echo %Line%
echo %Cyan%           NAS 映射自动化工具 (v3.1)%Reset%
echo %Author%
echo %Line%
echo.

:: --- 1. 权限与环境修复 [cite: 1] ---
echo [%Yellow%步骤 1%Reset%] 正在配置系统访问权限...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v "AllowInsecureGuestAuth" /t REG_DWORD /d 1 /f >nul 2>&1
sc config LanmanWorkstation start= auto >nul
net start LanmanWorkstation >nul 2>&1
echo [%Green%完成%Reset%] 系统环境检查完毕。
echo.

:: --- 2. 彻底清除旧链接与凭据 ---
echo [%Yellow%步骤 2%Reset%] 清理旧的连接环境...
set /p "NAS_IP= > 请输入 NAS IP 地址: " [cite: 2]

echo.
echo 正在强制断开与 %NAS_IP% 的旧连接并清除密码快取...
net use \\%NAS_IP% /delete /y >nul 2>&1
cmdkey /delete:%NAS_IP% >nul 2>&1
echo [%Green%完成%Reset%] 环境已清理干净。
echo.

:: --- 3. 账户认证信息 [cite: 2] ---
echo %Line%
echo [%Yellow%步骤 3%Reset%] 账户认证信息
echo %Line%

for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "Read-Host ' > 请输入用户名'"`) do set "NAS_USER=%%i" [cite: 2]
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$p = Read-Host ' > 请输入密码'; [Console]::WriteLine($p)"`) do set "NAS_PASS=%%i" [cite: 2]

if "%NAS_PASS%"=="" (
    echo.
    echo %Red%[错误] 密码不能为空！按任意键重新开始...%Reset%
    pause >nul
    goto START
)

echo.
set /p "SAVE_CRED= > 是否记住账户密码？(Y/N): "
if /i "%SAVE_CRED%"=="Y" (
    echo [%Green%状态%Reset%] 正在将认证信息写入凭据管理器...
    cmdkey /add:%NAS_IP% /user:%NAS_USER% /pass:"%NAS_PASS%" >nul
    set "PERSISTENT_VAL=yes"
) else (
    set "PERSISTENT_VAL=no"
)

:: --- 4. 循环映射逻辑开始 ---
:FOLDER_LOOP
cls
echo %Line%
echo    当前连接目标: %Green%\\%NAS_IP%%Reset%
echo %Line%
echo [%Yellow%步骤 4%Reset%] 正在扫描共享目录清单... [cite: 3]
echo.

:: 尝试连接以刷新缓存 [cite: 3]
net use \\%NAS_IP% "%NAS_PASS%" /user:%NAS_USER% /persistent:no >nul 2>&1

set count=0
set "SELECTED_FOLDER="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "Get-SmbShare -CimSession %NAS_IP% | Where-Object { $_.Name -notmatch '\$|ADMIN|IPC' } | Select-Object -ExpandProperty Name" 2^>nul`) do (
    set /a count+=1
    set "folder[!count!]=%%i"
    echo   [%Cyan%!count!%Reset%] %%i
)

echo.
if %count% equ 0 (
    echo %Yellow%[提示] 无法自动获取目录，可能是 NAS 权限限制。%Reset%
    set /p "SELECTED_FOLDER= > 请手动输入文件夹名称: "
) else (
    set /p "choice= > 请选择欲映射的序号 (1-%count%): "
    for %%i in (!choice!) do set "SELECTED_FOLDER=!folder[%%i]!"
)

:: 检查变量是否为空，防止挂载失败 
if "%SELECTED_FOLDER%"=="" (
    echo %Red%[错误] 未选择或输入任何文件夹！%Reset%
    pause
    goto FOLDER_LOOP
)

:: --- 5. 映射盘符  ---
echo.
set /p "DRIVE_LETTER= > 请输入映射盘符 (如 Z): "
set "DRIVE=%DRIVE_LETTER%:"

if exist %DRIVE% (
    echo [%Yellow%提示%Reset%] 盘符 %DRIVE% 已被占用，正在清理...
    net use %DRIVE% /delete /y >nul 2>&1
)

echo.
echo 正在挂载: %Cyan%%DRIVE%%Reset% --^> %Cyan%\\%NAS_IP%\%SELECTED_FOLDER%%Reset%
:: 关键修复：确保所有路径都被双引号严密包裹 
net use %DRIVE% "\\%NAS_IP%\%SELECTED_FOLDER%" "%NAS_PASS%" /user:%NAS_USER% /persistent:%PERSISTENT_VAL%

if %errorlevel% equ 0 (
    echo.
    echo %Green%------------------------------------------%Reset%
    echo           [成功] 映射已成功建立！
    echo %Green%------------------------------------------%Reset%
    start "" "%DRIVE%"
) else (
    echo.
    echo %Red%[失败] 无法建立映射。错误代码: %errorlevel%%Reset%
    echo %Yellow%请检查：%Reset%1. 文件夹名是否正确 2. 账号是否有权访问该目录
)

:: --- 6. 询问是否继续 ---
echo.
set /p "CONTINUE= > 是否继续映射该 NAS 的其他文件夹？(Y/N): "
if /i "%CONTINUE%"=="Y" goto FOLDER_LOOP

echo.
echo %Line%
echo    %Yellow%感谢使用！映射任务结束。 (制作人: 小沨)%Reset%
echo %Line%
pause