:: Set current directory and paths
@echo off
C:
CD %~dp0
CD ..\src\core\NGetBinaryClient\bin\Debug\netcoreapp3.1\

NGetBinaryClient nget.nxtel.org:44444

PAUSE