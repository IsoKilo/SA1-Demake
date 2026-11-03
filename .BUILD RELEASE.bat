@echo off
".utils/ASM68k" /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /p /e DEBUG_BUILD=0 "Main.asm", "Release.gen", "Release.sym", "Release.lst"
".utils/ROM Padder" "Release.gen" 255 0
".utils/Checksum Calc" "Release.gen"
pause