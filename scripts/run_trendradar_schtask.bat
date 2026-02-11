@echo off
@echo off
:: Ensure Python outputs UTF-8 to avoid UnicodeEncodeError in Windows scheduled tasks
set PYTHONIOENCODING=utf-8
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\ZJB\ai\TrendRadar\scripts\run_trendradar_loop.ps1" -Once
