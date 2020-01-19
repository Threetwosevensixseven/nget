:: Set current directory and paths
@echo off
C:
CD %~dp0

:: Prepare NGetServer for publishing
PATH=%PATH%;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin
CD ..\src\core\NGetServer

:: Publish NGetServer
msbuild NGetServer.csproj /p:Configuration="Release" /p:Platform="AnyCPU"

:: Deploy NGetServer
DEL  /F /Q /S Publish\netcoreapp3.1\*.pdb
DEL  /F /Q /S Publish\netcoreapp3.1\NGetServer.appsettings.json
XCOPY /Y "Publish\netcoreapp3.1\*.*" "%USERPROFILE%\Documents\Visual Studio 2015\Projects\NXtelDeploy\NGetServer\"

:: Stage and commit deployment changes for the server
for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
cd "%USERPROFILE%\Documents\Visual Studio 2015\Projects\NXtelDeploy\NGetServer\"
git add *
git commit -a -m "Autocommit %mydate% %time% from build script."
git push

PAUSE