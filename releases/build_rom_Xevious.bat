@echo off

set    zip=xevious.zip
set ifiles=xvi_1.3p+xvi_2.3m+xvi_3.2m+xvi_4.2l+xvi_5.3f+xvi_6.3j+xvi_7.2c+xvi_12.3b+xvi_13.3c+xvi_14.3d+xvi_15.4m+xvi_17.4p+xvi_16.4n+xvi_18.4r+xvi_9.2a+xvi_10.2b+xvi_11.2c+50xx.bin+51xx.bin+54xx.bin
set  ofile=a.xevs.rom

rem =====================================
setlocal ENABLEDELAYEDEXPANSION

set pwd=%~dp0
echo.
echo.

if EXIST %zip% (

	!pwd!7za x -otmp %zip%
	if !ERRORLEVEL! EQU 0 ( 
		cd tmp

		copy /b/y %ifiles% !pwd!%ofile%
		if !ERRORLEVEL! EQU 0 ( 
			echo.
			echo ** done **
			echo.
			echo Copy "%ofile%" into root of SD card
		)
		cd !pwd!
		rmdir /s /q tmp
	)

) else (

	echo Error: Cannot find "%zip%" file
	echo.
	echo Put "%zip%", "7za.exe" and "%~nx0" into the same directory
)

echo.
echo.
pause
