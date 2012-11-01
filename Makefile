!if $d(DEBUG)
TASMOPT=/zi
LINKOPT=/v
!else
TASMOPT=
LINKOPT=/t
!endif

LED.EXE: LED.OBJ BIN2ASC.OBJ
        tlink /x $(LINKOPT) led bin2asc
.ASM.OBJ:
        tasm $(TASMOPT) $&.asm
