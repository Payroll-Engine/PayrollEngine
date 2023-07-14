@ECHO OFF

REM --- call setup in all subfolders ---
FOR /D %%d IN (*) DO (
     pushd %%d
	 if exist Setup.cmd (
		call Setup.cmd /waiterror
	 )
	 popd
	)
