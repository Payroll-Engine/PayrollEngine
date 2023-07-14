@ECHO OFF

REM --- call test in all *.test subfolders ---
FOR /D %%d IN (*.Test) DO (
     pushd %%d
	 if exist *.pt.json (
		call Test.cmd
	 )
	 popd
	)
