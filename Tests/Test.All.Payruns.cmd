@ECHO OFF

REM --- Test ---
FOR /D %%d IN (*.Test) DO (
     pushd %%d
	 if exist *.pt.json (
		call Test.cmd
	 )
	 popd
	)
