@echo OFF
echo Payroll Engine Setup Publisher

echo ----- copy setup files
echo Publishin setup...
xcopy %~dp0..\Setup\*.* %~dp0..\Bin\*.* /S 
goto exit

:error
pause

:exit
