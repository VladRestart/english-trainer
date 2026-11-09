@echo off
rem Starts the English app on this computer (with microphone check) and opens it in the browser.
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0server.ps1"
