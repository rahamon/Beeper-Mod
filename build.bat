@echo OFF
cls
rem ------------------------------------------------------
rem MODO
rem 0 = Standard MPAG
rem 1 = Modificacion cargador para Pac-man
set mod=1
rem ------------------------------------------------------
rem Modificaciones de cargador:
rem nombre para tu juego
set gamename=Pacman48
rem ------------------------------------------------------
rem Modificaciones de sonido
rem 0 = Standard
rem 1 = ZX Spectrum 48k Beeper
set modsnd=1
rem ------------------------------------------------------

if %mod% == 0 (
	if %modsnd% == 0 (
		rem Compile AGD file
			copy AGDsource\%1.agd AGD
			cd AGD
			CompilerZX %1
		rem Assemble game
			copy %1.asm ..\sjasmplus\
			copy ..\..\user.asm ..\sjasmplus\
			del %1.*
			cd ..\sjasmplus
			copy leader.txt+%1.asm+trailer.txt agdcode.asm
			sjasmplus.exe agdcode.asm --lst=list.txt
			copy test.tap ..\speccy
		rem limpieza en sjasmplus
			del %1.asm
			del user.asm
			del agdcode.asm
			del test.tap
		rem Start emulator
			cd ..\speccy
			speccy -128 test.tap
			del test.tap
			cd ..
			exit
		)
	)
rem con cargador y con música o sin música
if %modsnd% == 0 (
	rem Compile AGD file
		copy AGDsource\%1.agd AGD
		cd AGD
		CompilerZX %1
	)
if %modsnd% == 1 (
	rem Compile AGD file
		echo Pacman Beeper Mod build ....
		copy AGDsource\%1.agd AGDsoundMod
		cd AGDsoundMod
		..\Tools\CompilerZX %1
	)
rem assemble game
	copy %1.asm ..\assembly\
	copy ..\..\user.asm ..\assembly\
	del %1.*
	cd ..\assembly
rem actualizar fuentes
	if %modsnd% == 1 (
		copy ..\AGDsoundMod\Beeper\*.asm ..\assembly
		copy ..\sound\*.asm ..\assembly
		)
	if %mod% == 1 (
		echo Modificación Cargador para Pac-man
		copy ..\Basic\loader48k.bas ..\assembly\
		..\Tools\bas2tap -e -a1 -s%gamename% loader48k.bas loader.tap
		..\Tools\fart %1.asm 24832 32000
		..\Tools\fart %1.asm "jp gamelp " "jp game"
		)
	if %mod% == 0 (
		echo Cargador Standard
		copy ..\Basic\loader.bas ..\assembly\
		..\Tools\bas2tap -e -a1 -s%gamename% loader.bas loader.tap
		)
		copy ..\Tapes\SC.tap ..\assembly\
	if %modsnd% == 1 (
		..\tools\fart %1.asm "plsnd  ret" "	   include \"48k.asm\""
		)
	..\Tools\Pasmo --tap --name AG %1.asm AG.tap
rem mas arreglos de empacaje?
	copy /b loader.tap + SC.tap + AG.tap %gamename%.tap
rem limpieza en assembly
	copy %gamename%.tap ..\
	del *.asm
	del loader*.*
	del AG.tap
	del SC.tap
rem Start emulator
	..\speccy\speccy -128 %gamename%.tap
	cd ..
)
