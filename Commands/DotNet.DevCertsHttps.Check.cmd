@echo OFF
echo Generate HTTPS developer certificate...
dotnet dev-certs https --check
echo ErrorLevel: %ERRORLEVEL%
pause