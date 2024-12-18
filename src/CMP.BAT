@echo off
set code=mkspr
mkmsg mkspr
lha a c:\olf_soft\lzh\%code% mksprite.exe *.icn *.mou *.msg setup.cfg ..\divers\setdflt.exe ..\mkpal\standard.pal *.spr
set code=
echo on
