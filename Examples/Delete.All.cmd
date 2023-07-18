@ECHO OFF

REM --- call delete in all subfolders ---
FOR /D %%d IN (*) DO (
     pushd %%d
	 if exist Setup.cmd (
		call Delete.cmd /waiterror
	 )
	 popd
	)
