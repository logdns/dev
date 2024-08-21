@echo off
setlocal enabledelayedexpansion

rem 设置代码页为 UTF-8
chcp 65001 > nul

rem 设置控制台颜色
color 0A

rem 显示欢迎信息
echo.
echo ===================================
echo    文件夹和文件创建工具 v1.0
echo ===================================
echo.

rem 设置起始日期和结束日期
set "start_date=2024-09-01"
set "end_date=2024-09-30"

rem 计算总天数
for /f %%a in ('powershell -Command "(New-TimeSpan -Start '%start_date%' -End '%end_date%').Days + 1"') do set "total_days=%%a"

rem 初始化计数器
set "counter=0"

rem 循环处理日期范围内的每一天
for /f "tokens=1-3 delims=-/" %%a in ('powershell -Command "(Get-Date '%start_date%').ToString('yyyy-MM-dd')"') do (
    set "year=%%a"
    set "month=%%b"
    set "day=%%c"
)

:loop
rem 检查是否为工作日（1-5 表示周一到周五）
for /f %%a in ('powershell -Command "(Get-Date '%year%-%month%-%day%').DayOfWeek.value__"') do set "dow=%%a"
if %dow% geq 1 if %dow% leq 5 (
    rem 创建文件夹
    mkdir "%year%-%month%-%day%" 2>nul

    rem 在文件夹中创建三个文本文件
    echo. > "%year%-%month%-%day%\1.txt"
    echo. > "%year%-%month%-%day%\2.txt"
    echo. > "%year%-%month%-%day%\3.txt"

    rem 显示创建信息
    echo [+] 已创建文件夹: %year%-%month%-%day% 及其文件
)

rem 增加计数器
set /a "counter+=1"

rem 计算和显示进度条
set /a "progress=counter*100/total_days"
set "progressbar="
for /l %%i in (1,1,50) do (
    if %%i leq !progress! (
        set "progressbar=!progressbar!#"
    ) else (
        set "progressbar=!progressbar!-"
    )
)
echo [!progressbar!] !progress!%%

rem 增加一天
for /f "tokens=1-3 delims=-/" %%a in ('powershell -Command "(Get-Date '%year%-%month%-%day%').AddDays(1).ToString('yyyy-MM-dd')"') do (
    set "year=%%a"
    set "month=%%b"
    set "day=%%c"
)

rem 检查是否达到结束日期
if "%year%-%month%-%day%" leq "%end_date%" goto loop

rem 显示完成信息
echo.
echo ===================================
echo       任务完成！文件夹已创建
echo ===================================
echo.

rem 暂停以查看结果
pause
