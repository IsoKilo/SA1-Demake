@echo off
".utils/ASM68k" /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /p /e DEBUG_BUILD=1 "Main.asm", "Debug.gen", "Debug.sym", "Debug.lst"
".utils/ROM Padder" "Debug.gen" 255 0
".utils/Checksum Calc" "Debug.gen"
pause