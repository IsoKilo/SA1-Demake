; ****************************************************************************************************
; SONIC ADVENTURE 16-BIT DEMAKE
; SONIC THE HEDGEHOG ROM HACK
; CREATED BY KILO
; 06-10-2024
; ****************************************************************************************************

; ==================================================
; Main.asm
; Includes all files together.
; Contains any functions or data not fit to be split elsewhere.
;
; Author: Kilo
; 06-10-2024
; ==================================================

; ----------<Definitions>----------
		include	".def/68k Ports.lib"
		include	".def/68k Consts.lib"
		include	".def/68k Macros.lib"

		include	".def/Game Vars.lib"
		include	".def/Game Consts.lib"
		include	".def/Game Macros.lib"

align macro
	cnop 0,\1
	endm
	
ROM_Start:
Vectors:	dc.l sys_stackptr&$FFFFFF, EntryPoint, ErrorTrap, ErrorTrap
		dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap, ErrorTrap, ErrorTrap,	ErrorTrap
		dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap, ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap, ErrorTrap, ErrorTrap,	ErrorTrap
		dc.l PalToCRAM,	ErrorTrap, loc_B10, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap
		dc.l ErrorTrap,	ErrorTrap, ErrorTrap, ErrorTrap

Header_System:
		dc.b	"SEGA MEGA DRIVE "

Header_Copyright:
		dc.b	"(X)KILO 2024.OCT"

Header_TitleDom:
		dc.b	"SONIC ADVENTURE 16-BIT DEMAKE                   "

Header_TitleInt:
		dc.b	"SONIC ADVENTURE 16-BIT DEMAKE                   "

Header_Serial:
		dc.b	"RH 11001901-00"

Header_Checksum:
		dc.w	$0000

Header_IOType:
		dc.b	"J               "

Header_ROMRange:
		dc.l	ROM_Start, ROM_End-1

Header_RAMRange:
		dc.l	ram_start, ram_end-1

Header_SRAMType:
		dc.b	"    "

Header_SRAMRange:
		dc.l	sram_start, sram_end-1

Header_ModemType:
		dc.b	"            "

Header_Notes:
		dc.b	"                                        "

Header_RegionType:
		dc.b	"JUE             "

Header_End:

; ===========================================================================

ErrorTrap:
		nop	
		nop	
		bra.s	ErrorTrap
; ===========================================================================

EntryPoint:
		tst.l	(io_ctrl1-1).l	; test port A control
		bne.s	PortA_Ok
		tst.w	(io_ctrlext-1).l	; test port C control

PortA_Ok:
		bne.s	PortC_Ok
		lea	SetupValues(pc),a5
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	io_ver-z80_busline(a1),d0	; get hardware version
		andi.b	#$F,d0
		beq.s	SkipSecurity
		move.l	#'SEGA',io_tmssstr-z80_busline(a1)

SkipSecurity:
		move.w	(a4),d0		; check	if VDP works
		moveq	#0,d0
		movea.l	d0,a6
		move.l	a6,usp		; set usp to $0
		moveq	#$17,d1

VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to	VDP register
		add.w	d7,d5		; next register
		dbf	d1,VDPInitLoop
		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear	the screen
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset	the Z80

WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.s	WaitForZ80	; if not, branch
		moveq	#$25,d2

Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop
		move.w	d0,(a2)
		move.w	d0,(a1)		; start	the Z80
		move.w	d7,(a2)		; reset	the Z80

ClrRAMLoop:
		move.l	d0,-(a6)
		dbf	d6,ClrRAMLoop	; clear	the entire RAM
		move.l	(a5)+,(a4)	; set VDP display mode and increment
		move.l	(a5)+,(a4)	; set VDP to CRAM write
		moveq	#$1F,d3

ClrCRAMLoop:
		move.l	d0,(a3)
		dbf	d3,ClrCRAMLoop	; clear	the CRAM
		move.l	(a5)+,(a4)
		moveq	#$13,d4

ClrVDPStuff:
		move.l	d0,(a3)
		dbf	d4,ClrVDPStuff
		moveq	#3,d5

PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset	the PSG
		dbf	d5,PSGInitLoop
		move.w	d0,(a2)
		movem.l	(a6),d0-a6	; clear	all registers
		move	#$2700,sr	; set the sr

PortC_Ok:
		bra.s	GameProgram
; ===========================================================================
SetupValues:	dc.w $8000		; XREF: PortA_Ok
		dc.w $3FFF
		dc.w $100

		dc.l z80_ram		; start	of Z80 RAM
		dc.l z80_busline		; Z80 bus request
		dc.l z80_resetln		; Z80 reset
		dc.l vdp_data
		dc.l vdp_ctrl		; address for VDP registers

		dc.b 4,	$14, $30, $3C	; values for VDP registers
		dc.b 7,	$6C, 0,	0
		dc.b 0,	0, $FF,	0
		dc.b $81, $37, 0, 1
		dc.b 1,	0, 0, $FF
		dc.b $FF, 0, 0,	$80

		dc.l $40000080

		dc.b $AF, 1, $D9, $1F, $11, $27, 0, $21, $26, 0, $F9, $77 ; Z80	instructions
		dc.b $ED, $B0, $DD, $E1, $FD, $E1, $ED,	$47, $ED, $4F
		dc.b $D1, $E1, $F1, 8, $D9, $C1, $D1, $E1, $F1,	$F9, $F3
		dc.b $ED, $56, $36, $E9, $E9

		dc.w $8104		; value	for VDP	display	mode
		dc.w $8F02		; value	for VDP	increment
		dc.l $C0000000		; value	for CRAM write mode
		dc.l $40000010

		dc.b $9F, $BF, $DF, $FF	; values for PSG channel volumes
; ===========================================================================

GameProgram:
		tst.w	(vdp_ctrl).l
		btst	#6,($A1000D).l
		beq.s	CheckSumCheck
		cmpi.l	#'init',(sys_initflag).w ; has checksum routine already run?
		beq.w	GameInit	; if yes, branch

CheckSumCheck:
		movea.w	#Header_End,a0 ; prepare start address
		move.l	(Header_ROMRange+4).w,d7 ; load size
		sub.l	a0,d7 ; minus start address
		move.b	d7,d5 ; copy end nybble
		andi.w	#$F,d5 ; get only the remaining nybble
		lsr.l	#4,d7 ; divide the size by 20
		move.w	d7,d6 ; load lower word size
		swap	d7 ; get upper word size
		moveq	#0,d0 ; clear d0

CS_MainBlock:
		add.w	(a0)+,d0 ; modular checksum (8 words)
		add.w	(a0)+,d0 ; ''
		add.w	(a0)+,d0 ; ''
		add.w	(a0)+,d0 ; ''
		add.w	(a0)+,d0 ; ''
		add.w	(a0)+,d0 ; ''
		add.w	(a0)+,d0 ; ''
		add.w	(a0)+,d0 ; ''
		dbf		d6,CS_MainBlock ; repeat until all main block sections are done
		dbf		d7,CS_MainBlock ; ''
		subq.w	#1,d5 ; decrease remaining nybble for dbf
		bpl.s	CS_Finish ; if there is no remaining nybble, branch

CS_Remains:
		add.w	(a0)+,d0 ; add remaining words
		dbf		d5,CS_Remains ; repeat until the remaining words are done

CS_Finish:
		cmp.w	(Header_Checksum).w,d0 ; does the checksum match?
		bne.w	CheckSumError ; if not, branch
		lea	(sys_stackptr).w,a6
		moveq	#0,d7
		move.w	#$7F,d6

loc_348:
		move.l	d7,(a6)+
		dbf	d6,loc_348
		move.b	($A10001).l,d0
		andi.b	#$C0,d0
		move.b	d0,(sys_region).w
		move.l	#'init',(sys_initflag).w ; set flag so checksum won't be run again

GameInit:
		lea	(ram_start).l,a6
		moveq	#0,d7
		move.w	#$3F7F,d6

GameClrRAM:
		move.l	d7,(a6)+
		dbf	d6,GameClrRAM	; fill RAM ($0000-$FDFF) with $0
		bsr.w	VDPSetupGame
		bsr.w	SoundDriverLoad
		bsr.w	Joypad_Init
		move.b	#0,(gm_scene).w ; set Game Mode to Sega Screen

MainGameLoop:
		move.b	(gm_scene).w,d0 ; load	Game Mode
		andi.w	#$1C,d0
		jsr	GameModeArray(pc,d0.w) ; jump to apt location in ROM
		bra.s	MainGameLoop
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:
		bra.w	Scene_Title	; Title	Screen ($04)
; ===========================================================================
		bra.w	Level		; Demo Mode ($08)
; ===========================================================================

CheckSumError:
		bsr.w	VDPSetupGame
		move.l	#$C0000000,($C00004).l ; set VDP to CRAM write
		moveq	#$3F,d7

CheckSum_Red:
		move.w	#$E,($C00000).l	; fill screen with colour red
		dbf	d7,CheckSum_Red	; repeat $3F more times

CheckSum_Loop:
		bra.s	CheckSum_Loop
; ===========================================================================

loc_B10:				; XREF: Vectors
		movem.l	d0-a6,-(sp)
		tst.b	(vint_routine).w
		beq.s	loc_B88
		move.w	($C00004).l,d0
		move.l	#$40000010,($C00004).l
		move.l	(vdp_fgypos).w,($C00000).l
		btst	#6,(sys_region).w
		beq.s	loc_B42
		move.w	#$700,d0

loc_B3E:
		dbf	d0,loc_B3E

loc_B42:
		move.b	(vint_routine).w,d0
		move.b	#0,(vint_routine).w
		move.w	#1,(vdp_dohint).w
		andi.w	#$3E,d0
		move.w	off_B6E(pc,d0.w),d0
		jsr	off_B6E(pc,d0.w)

loc_B5E:				; XREF: loc_B88
		jsr	sub_71B4C

loc_B64:				; XREF: loc_D50
		addq.l	#1,(vint_count).w
		movem.l	(sp)+,d0-a6
		rte	
; ===========================================================================
off_B6E:	dc.w loc_B88-off_B6E, loc_C32-off_B6E
		dc.w loc_C44-off_B6E, loc_C5E-off_B6E
		dc.w loc_C6E-off_B6E, loc_DA6-off_B6E
		dc.w loc_E72-off_B6E, loc_E72-off_B6E
		dc.w loc_C64-off_B6E, loc_F9A-off_B6E
		dc.w loc_C36-off_B6E, loc_FA6-off_B6E
		dc.w loc_E72-off_B6E
; ===========================================================================

loc_B88:				; XREF: loc_B10; off_B6E
		cmpi.b	#$80|SCNID_GAME,(gm_scene).w
		beq.s	loc_B9A
		cmpi.b	#SCNID_GAME,(gm_scene).w
		bne.w	loc_B5E

loc_B9A:
		cmpi.b	#1,(lvl_id).w ; is level LZ ?
		bne.w	loc_B5E		; if not, branch
		move.w	($C00004).l,d0
		btst	#6,(sys_region).w
		beq.s	loc_BBA
		move.w	#$700,d0

loc_BB6:
		dbf	d0,loc_BB6

loc_BBA:
		move.w	#1,(vdp_dohint).w
		move.w	#$100,($A11100).l

loc_BC8:
		btst	#0,($A11100).l
		bne.s	loc_BC8
		tst.b	(water_fullscr).w
		bne.s	loc_BFE
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		bra.s	loc_C22
; ===========================================================================

loc_BFE:				; XREF: loc_BC8
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)

loc_C22:				; XREF: loc_BC8
		move.w	(vdp_hintpos).w,(a5)
		move.w	#0,($A11100).l
		bra.w	loc_B5E
; ===========================================================================

loc_C32:				; XREF: off_B6E
		bsr.w	sub_106E

loc_C36:				; XREF: off_B6E
		tst.w	(gm_timer).w
		beq.w	locret_C42
		subq.w	#1,(gm_timer).w

locret_C42:
		rts	
; ===========================================================================

loc_C44:				; XREF: off_B6E
		bsr.w	sub_106E
		jsr	sub_6886
		bsr.w	sub_1642
		tst.w	(gm_timer).w
		beq.w	locret_C5C
		subq.w	#1,(gm_timer).w

locret_C5C:
		rts	
; ===========================================================================

loc_C5E:				; XREF: off_B6E
		bsr.w	sub_106E
		rts	
; ===========================================================================

loc_C64:				; XREF: off_B6E
		cmpi.b	#$10,(gm_scene).w ; is	game mode = $10	(special stage)	?
		beq.w	loc_DA6		; if yes, branch

loc_C6E:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_C76:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_C76		; if not, branch
		bsr.w	Joypad_Process
		tst.b	(water_fullscr).w
		bne.s	loc_CB0
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		bra.s	loc_CD4
; ===========================================================================

loc_CB0:				; XREF: loc_C76
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)

loc_CD4:				; XREF: loc_C76
		move.w	(vdp_hintpos).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		tst.b	($FFFFF767).w
		beq.s	loc_D50
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.b	#0,($FFFFF767).w

loc_D50:
		move.w	#0,($A11100).l
		movem.l	(lvl_fgxpos).w,d0-d7
		movem.l	d0-d7,(redraw_fgxpos).w
		movem.l	($FFFFF754).w,d0-d1
		movem.l	d0-d1,(redraw_fgfcopy).w
		cmpi.b	#$60,(vdp_hintpos+1).w
		bcc.s	Demo_Time
		move.b	#1,($FFFFF64F).w
		addq.l	#4,sp
		bra.w	loc_B64

; ---------------------------------------------------------------------------
; Subroutine to	run a demo for an amount of time
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Demo_Time:				; XREF: loc_D50; PalToCRAM
		jsr	LoadTilesAsYouMove
		jsr	AniArt_Load
		jsr	HudUpdate
		bsr.w	sub_165E
		tst.w	(gm_timer).w	; is there time	left on	the demo?
		beq.w	Demo_TimeEnd	; if not, branch
		subq.w	#1,(gm_timer).w ; subtract 1 from time	left

Demo_TimeEnd:
		rts	
; End of function Demo_Time

; ===========================================================================

loc_DA6:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_DAE:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_DAE		; if not, branch
		bsr.w	Joypad_Process
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.w	#0,($A11100).l
		tst.b	($FFFFF767).w
		beq.s	loc_E64
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.b	#0,($FFFFF767).w

loc_E64:
		tst.w	(gm_timer).w
		beq.w	locret_E70
		subq.w	#1,(gm_timer).w

locret_E70:
		rts	
; ===========================================================================

loc_E72:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_E7A:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_E7A		; if not, branch
		bsr.w	Joypad_Process
		tst.b	(water_fullscr).w
		bne.s	loc_EB4
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		bra.s	loc_ED8
; ===========================================================================

loc_EB4:				; XREF: loc_E7A
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)

loc_ED8:				; XREF: loc_E7A
		move.w	(vdp_hintpos).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)

loc_EEE:
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		tst.b	($FFFFF767).w
		beq.s	loc_F54
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.b	#0,($FFFFF767).w

loc_F54:
		move.w	#0,($A11100).l	; start	the Z80
		movem.l	(lvl_fgxpos).w,d0-d7
		movem.l	d0-d7,(redraw_fgxpos).w
		movem.l	($FFFFF754).w,d0-d1
		movem.l	d0-d1,(redraw_fgfcopy).w
		jsr	LoadTilesAsYouMove
		jsr	AniArt_Load
		jsr	HudUpdate
		bsr.w	sub_1642
		rts	
; ===========================================================================

loc_F9A:				; XREF: off_B6E
		bsr.w	sub_106E
		move.w	(vdp_hintpos).w,(a5)
		bra.w	sub_1642
; ===========================================================================

loc_FA6:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_FAE:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_FAE		; if not, branch
		bsr.w	Joypad_Process
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.w	#0,($A11100).l	; start	the Z80
		tst.b	($FFFFF767).w
		beq.s	loc_1060
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.b	#0,($FFFFF767).w

loc_1060:
		tst.w	(gm_timer).w
		beq.w	locret_106C
		subq.w	#1,(gm_timer).w

locret_106C:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_106E:				; XREF: loc_C32; et al
		move.w	#$100,($A11100).l ; stop the Z80

loc_1076:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.s	loc_1076	; if not, branch
		bsr.w	Joypad_Process
		tst.b	(water_fullscr).w
		bne.s	loc_10B0
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		bra.s	loc_10D4
; ===========================================================================

loc_10B0:				; XREF: sub_106E
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)

loc_10D4:				; XREF: sub_106E
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,(vdp_dmalohold).w
		move.w	(vdp_dmalohold).w,(a5)
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function sub_106E

; ---------------------------------------------------------------------------
; Subroutine to	move pallets from the RAM to CRAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalToCRAM:
		move	#$2700,sr
		tst.w	(vdp_dohint).w
		beq.s	locret_119C
		move.w	#0,(vdp_dohint).w
		movem.l	a0-a1,-(sp)
		lea	($C00000).l,a1
		lea	(pal_water).w,a0 ; load	pallet from RAM
		move.l	#$C0000000,4(a1) ; set VDP to CRAM write
		move.l	(a0)+,(a1)	; move pallet to CRAM
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.w	#$8ADF,4(a1)
		movem.l	(sp)+,a0-a1
		tst.b	($FFFFF64F).w
		bne.s	loc_119E

locret_119C:
		rte	
; ===========================================================================

loc_119E:				; XREF: PalToCRAM
		clr.b	($FFFFF64F).w
		movem.l	d0-a6,-(sp)
		bsr.w	Demo_Time
		jsr	sub_71B4C
		movem.l	(sp)+,d0-a6
		rte	
; End of function PalToCRAM

		include	"System/Joypad.asm"

VDPSetupGame:				; XREF: GameClrRAM; ChecksumError
		lea	($C00004).l,a0
		lea	($C00000).l,a1
		lea	(VDPSetupArray).l,a2
		moveq	#$12,d7

VDP_Loop:
		move.w	(a2)+,(a0)
		dbf	d7,VDP_Loop	; set the VDP registers

		move.w	(VDPSetupArray+2).l,d0
		move.w	d0,(vdp_mode2hold).w
		move.w	#$8ADF,(vdp_hintpos).w
		moveq	#0,d0
		move.l	#$C0000000,($C00004).l ; set VDP to CRAM write
		move.w	#$3F,d7

VDP_ClrCRAM:
		move.w	d0,(a1)
		dbf	d7,VDP_ClrCRAM	; clear	the CRAM

		clr.l	(vdp_fgypos).w
		move.l	d1,-(sp)
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$94FF93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000080,(a5)
		move.w	#0,($C00000).l	; clear	the screen

loc_128E:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_128E

		move.w	#$8F02,(a5)
		move.l	(sp)+,d1
		rts	
; End of function VDPSetupGame

; ===========================================================================
VDPSetupArray:	dc.w $8004, $8134, $8230, $8328	; XREF: VDPSetupGame
		dc.w $8407, $857C, $8600, $8700
		dc.w $8800, $8900, $8A00, $8B00
		dc.w $8C81, $8D3F, $8E00, $8F02
		dc.w $9001, $9100, $9200

; ---------------------------------------------------------------------------
; Subroutine to	clear the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VDP_Clear:
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000083,(a5)
		move.w	#0,($C00000).l

loc_12E6:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_12E6

		move.w	#$8F02,(a5)
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$60000083,(a5)
		move.w	#0,($C00000).l

loc_1314:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	loc_1314

		move.w	#$8F02,(a5)
		move.l	#0,(vdp_fgypos).w
		lea	(spr_buffer).w,a1
		moveq	#0,d0
		move.w	#$A0,d1

loc_133A:
		move.l	d0,(a1)+
		dbf	d1,loc_133A

		lea	(scr_horibuff).w,a1
		moveq	#0,d0
		move.w	#$100,d1

loc_134A:
		move.l	d0,(a1)+
		dbf	d1,loc_134A
		rts	
; End of function VDP_Clear

; ---------------------------------------------------------------------------
; Subroutine to	load the sound driver
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SoundDriverLoad:			; XREF: GameClrRAM; TitleScreen
		nop	
		move.w	#$100,($A11100).l ; stop the Z80
		move.w	#$100,($A11200).l ; reset the Z80
		lea	(Kos_Z80).l,a0	; load sound driver
		lea	($A00000).l,a1
		bsr.w	KosDec		; decompress
		move.w	#0,($A11200).l
		nop	
		nop	
		nop	
		nop	
		move.w	#$100,($A11200).l ; reset the Z80
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function SoundDriverLoad

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_CueMusic:
		move.b	d0,($FFFFF00A).w
		rts	
; End of function Sound_CueMusic

; ---------------------------------------------------------------------------
; Subroutine to	play a special sound/music (E0-E4)
;
; E0 - Fade out
; E1 - Sega
; E2 - Speed up
; E3 - Normal speed
; E4 - Stop
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_CueSFX:
		move.b	d0,($FFFFF00B).w
		rts	
; End of function Sound_CueSFX

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	pause the game
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PauseGame:				; XREF: Level_MainLoop; et al
;		tst.b	($FFFFFE12).w	; do you have any lives	left?
;		beq.s	Unpause		; if not, branch
		tst.w	(gm_paused).w	; is game already paused?
		bne.s	loc_13BE	; if yes, branch
		btst	#7,(jpad_pressed).w ; is Start button pressed?
		beq.s	Pause_DoNothing	; if not, branch

loc_13BE:
		move.w	#1,(gm_paused).w ; freeze time
		move.b	#1,($FFFFF003).w ; pause music

loc_13CA:
		move.b	#$10,(vint_routine).w
		bsr.w	VSync
		btst	#7,(jpad_pressed).w ; is Start button pressed?
		beq.s	loc_13CA	; if not, branch
		move.b	#$80,($FFFFF003).w

Unpause:				; XREF: PauseGame
		move.w	#0,(gm_paused).w ; unpause the game

Pause_DoNothing:			; XREF: PauseGame
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	display	patterns via the VDP
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VDP_DrawTilemap:			; XREF: SegaScreen; TitleScreen; SS_BGLoad
		lea	($C00000).l,a6
		move.l	#$800000,d4

loc_142C:
		move.l	d0,4(a6)
		move.w	d1,d3

loc_1432:
		move.w	(a1)+,(a6)
		dbf	d3,loc_1432
		add.l	d4,d0
		dbf	d2,loc_142C
		rts	
; End of function VDP_DrawTilemap

; ==============================================================================
; ------------------------------------------------------------------------------
; Nemesis decompression routine
; ------------------------------------------------------------------------------
; Optimized by vladikcomper
; ------------------------------------------------------------------------------

Decomp_Nem_RAM:
	movem.l	d0-a1/a3-a6,-(sp)
	lea	Decomp_Nem_WriteRowToRAM(pc),a3
	bra.s	Decomp_Nem_Main

; ------------------------------------------------------------------------------
Decomp_Nem:
	movem.l	d0-a1/a3-a6,-(sp)
	lea	$C00000,a4		; load VDP Data Port     
	lea	Decomp_Nem_WriteRowToVDP(pc),a3

Decomp_Nem_Main:
	lea		(dec_nembuff).w,a1		; load Nemesis decompression buffer
	move.w	(a0)+,d2		; get number of patterns
	bpl.s	@0			; are we in Mode 0?
	lea	$A(a3),a3		; if not, use Mode 1
@0	lsl.w	#3,d2
	movea.w	d2,a5
	moveq	#7,d3
	moveq	#0,d2
	moveq	#0,d4
	bsr.w	Decomp_Nem4
	move.b	(a0)+,d5		; get first byte of compressed data
	asl.w	#8,d5			; shift up by a byte
	move.b	(a0)+,d5		; get second byte of compressed data
	move.w	#$10,d6			; set initial shift value
	bsr.s	Decomp_Nem2
	movem.l	(sp)+,d0-a1/a3-a6
	rts

; ---------------------------------------------------------------------------
; Part of the Nemesis decompressor, processes the actual compressed data
; ---------------------------------------------------------------------------

Decomp_Nem2:
	move.w	d6,d7
	subq.w	#8,d7			; get shift value
	move.w	d5,d1
	lsr.w	d7,d1			; shift so that high bit of the code is in bit position 7
	cmpi.b	#%11111100,d1		; are the high 6 bits set?
	bcc.s	Decomp_Nem_InlineData	; if they are, it signifies inline data
	andi.w	#$FF,d1
	add.w	d1,d1
	sub.b	(a1,d1.w),d6		; ~~ subtract from shift value so that the next code is read next time around
	cmpi.w	#9,d6			; does a new byte need to be read?
	bcc.s	@0			; if not, branch
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5		; read next byte
@0	move.b	1(a1,d1.w),d1
	move.w	d1,d0
	andi.w	#$F,d1			; get palette index for pixel
	andi.w	#$F0,d0

Decomp_Nem_GetRepeatCount:
	lsr.w	#4,d0			; get repeat count

Decomp_Nem_WritePixel:
	lsl.l	#4,d4			; shift up by a nybble
	or.b	d1,d4			; write pixel
	dbf	d3,Decomp_Nem_WritePixelLoop; ~~
	jmp	(a3)			; otherwise, write the row to its destination
; ---------------------------------------------------------------------------

Decomp_Nem3:
	moveq	#0,d4			; reset row
	moveq	#7,d3			; reset nybble counter

Decomp_Nem_WritePixelLoop:
	dbf	d0,Decomp_Nem_WritePixel
	bra.s	Decomp_Nem2
; ---------------------------------------------------------------------------

Decomp_Nem_InlineData:
	subq.w	#6,d6			; 6 bits needed to signal inline data
	cmpi.w	#9,d6
	bcc.s	@0
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
@0	subq.w	#7,d6			; and 7 bits needed for the inline data itself
	move.w	d5,d1
	lsr.w	d6,d1			; shift so that low bit of the code is in bit position 0
	move.w	d1,d0
	andi.w	#$F,d1			; get palette index for pixel
	andi.w	#$70,d0			; high nybble is repeat count for pixel
	cmpi.w	#9,d6
	bcc.s	Decomp_Nem_GetRepeatCount
	addq.w	#8,d6
	asl.w	#8,d5
	move.b	(a0)+,d5
	bra.s	Decomp_Nem_GetRepeatCount

; ---------------------------------------------------------------------------
; Subroutines to output decompressed entry
; Selected depending on current decompression mode
; ---------------------------------------------------------------------------

Decomp_Nem_WriteRowToVDP:
loc_1502:
	move.l	d4,(a4)			; write 8-pixel row
	subq.w	#1,a5
	move.w	a5,d4			; have all the 8-pixel rows been written?
	bne.s	Decomp_Nem3			; if not, branch
	rts
; ---------------------------------------------------------------------------

Decomp_Nem_WriteRowToVDP_XOR:
	eor.l	d4,d2			; XOR the previous row by the current row
	move.l	d2,(a4)			; and write the result
	subq.w	#1,a5
	move.w	a5,d4
	bne.s	Decomp_Nem3
	rts
; ---------------------------------------------------------------------------

Decomp_Nem_WriteRowToRAM:
	move.l	d4,(a4)+		; write 8-pixel row
	subq.w	#1,a5
	move.w	a5,d4			; have all the 8-pixel rows been written?
	bne.s	Decomp_Nem3			; if not, branch
	rts
; ---------------------------------------------------------------------------

Decomp_Nem_WriteRowToRAM_XOR:
	eor.l	d4,d2			; XOR the previous row by the current row
	move.l	d2,(a4)+		; and write the result
	subq.w	#1,a5
	move.w	a5,d4
	bne.s	Decomp_Nem3
	rts

; ---------------------------------------------------------------------------
; Part of the Nemesis decompressor, builds the code table (in RAM)
; ---------------------------------------------------------------------------

Decomp_Nem4:
	move.b	(a0)+,d0		; read first byte

@ChkEnd:
	cmpi.b	#$FF,d0			; has the end of the code table description been reached?
	bne.s	@NewPalIndex		; if not, branch
	rts
; ---------------------------------------------------------------------------

@NewPalIndex:
	move.w	d0,d7

@ItemLoop:
	move.b	(a0)+,d0		; read next byte
	bmi.s	@ChkEnd			; ~~
	move.b	d0,d1
	andi.w	#$F,d7			; get palette index
	andi.w	#$70,d1			; get repeat count for palette index
	or.w	d1,d7			; combine the two
	andi.w	#$F,d0			; get the length of the code in bits
	move.b	d0,d1
	lsl.w	#8,d1
	or.w	d1,d7			; combine with palette index and repeat count to form code table entry
	moveq	#8,d1
	sub.w	d0,d1			; is the code 8 bits long?
	bne.s	@ItemShortCode		; if not, a bit of extra processing is needed
	move.b	(a0)+,d0		; get code
	add.w	d0,d0			; each code gets a word-sized entry in the table
	move.w	d7,(a1,d0.w)		; store the entry for the code
	bra.s	@ItemLoop		; repeat
; ---------------------------------------------------------------------------

@ItemShortCode:
	move.b	(a0)+,d0		; get code
	lsl.w	d1,d0			; shift so that high bit is in bit position 7
	add.w	d0,d0			; get index into code table
	moveq	#1,d5
	lsl.w	d1,d5
	subq.w	#1,d5			; d5 = 2^d1 - 1
	lea	(a1,d0.w),a6		; ~~

@ItemShortCodeLoop:
	move.w	d7,(a6)+		; ~~ store entry
	dbf	d5,@ItemShortCodeLoop	; repeat for required number of entries
	bra.s	@ItemLoop

; ---------------------------------------------------------------------------
; Subroutine to	load pattern load cues
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		lea	(gfx_queue).w,a2

loc_1598:
		tst.l	(a2)
		beq.s	loc_15A0
		addq.w	#6,a2
		bra.s	loc_1598
; ===========================================================================

loc_15A0:				; XREF: LoadPLC
		move.w	(a1)+,d0
		bmi.s	loc_15AC

loc_15A4:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbf	d0,loc_15A4

loc_15AC:
		movem.l	(sp)+,a1-a2
		rts	
; End of function LoadPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadPLC2:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		bsr.s	ClearPLC
		lea	(gfx_queue).w,a2
		move.w	(a1)+,d0
		bmi.s	loc_15D8

loc_15D0:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbf	d0,loc_15D0

loc_15D8:
		movem.l	(sp)+,a1-a2
		rts	
; End of function LoadPLC2

; ---------------------------------------------------------------------------
; Subroutine to	clear the pattern load cues
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ClearPLC:				; XREF: LoadPLC2
		lea	(gfx_queue).w,a2
		moveq	#$1F,d0

ClearPLC_Loop:
		clr.l	(a2)+
		dbf	d0,ClearPLC_Loop
		rts	
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to	use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC_RAM:				; XREF: PalFade_ToTarget
		tst.l	(gfx_queue).w
		beq.s	locret_1640
		tst.w	(gfx_counter).w
		bne.s	locret_1640
		movea.l	(gfx_queue).w,a0
		lea	(loc_1502).l,a3
		lea	(dec_nembuff).w,a1
		move.w	(a0)+,d2
		bpl.s	loc_160E
		adda.w	#$A,a3

loc_160E:
		andi.w	#$7FFF,d2
		bsr.w	Decomp_Nem4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,(gfx_queue).w
		move.l	a3,(gfx_a3).w
		move.l	d0,(gfx_d0).w
		move.l	d0,(gfx_d1).w
		move.l	d0,(gfx_d2).w
		move.l	d5,(gfx_d5).w
		move.l	d6,(gfx_d6).w
		move.w	d2,(gfx_counter).w

locret_1640:
		rts	
; End of function RunPLC_RAM


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1642:				; XREF: loc_C44; loc_F54; loc_F9A
		tst.w	(gfx_counter).w
		beq.w	locret_16DA
		move.w	#9,(gfx_counter2).w
		moveq	#0,d0
		move.w	(gfx_queue+4).w,d0
		addi.w	#$120,(gfx_queue+4).w
		bra.s	loc_1676
; End of function sub_1642


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_165E:				; XREF: Demo_Time
		tst.w	(gfx_counter).w
		beq.s	locret_16DA
		move.w	#3,(gfx_counter2).w
		moveq	#0,d0
		move.w	(gfx_queue+4).w,d0
		addi.w	#$60,(gfx_queue+4).w

loc_1676:				; XREF: sub_1642
		lea	($C00004).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	(gfx_queue).w,a0
		movea.l	(gfx_a3).w,a3
		move.l	(gfx_d0).w,d0
		move.l	(gfx_d1).w,d1
		move.l	(gfx_d2).w,d2
		move.l	(gfx_d5).w,d5
		move.l	(gfx_d6).w,d6
		lea	(dec_nembuff).w,a1

loc_16AA:				; XREF: sub_165E
		movea.w	#8,a5
		bsr.w	Decomp_Nem3
		subq.w	#1,(gfx_counter).w
		beq.s	loc_16DC
		subq.w	#1,(gfx_counter2).w
		bne.s	loc_16AA
		move.l	a0,(gfx_queue).w
		move.l	a3,(gfx_a3).w
		move.l	d0,(gfx_d0).w
		move.l	d1,(gfx_d1).w
		move.l	d2,(gfx_d2).w
		move.l	d5,(gfx_d5).w
		move.l	d6,(gfx_d6).w

locret_16DA:				; XREF: sub_1642
		rts	
; ===========================================================================

loc_16DC: ; XREF: sub_165E
		lea		(gfx_queue).w,a0
		lea		6(a0),a1
		moveq	#$E,d0 ; do $F cues

loc_16E2: ; XREF: sub_165E
		move.l	(a1)+,(a0)+
		move.w	(a1)+,(a0)+
		dbf		d0,loc_16E2

		moveq	#0,d0
		move.l	d0,(a0)+ ; clear the last cue to avoid overcopying it
		move.w	d0,(a0)+ ;
		rts
; End of function sub_165E

; ---------------------------------------------------------------------------
; Subroutine to	execute	the pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC_ROM:
		lea	(ArtLoadCues).l,a1 ; load the PLC index
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1	; load number of entries in the	PLC

RunPLC_Loop:
		movea.l	(a1)+,a0	; get art pointer
		moveq	#0,d0
		move.w	(a1)+,d0	; get VRAM address
		lsl.l	#2,d0		; divide address by $20
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,($C00004).l	; put the VRAM address into VDP
		bsr.w	Decomp_Nem		; decompress
		dbf	d1,RunPLC_Loop	; loop for number of entries
		rts	
; End of function RunPLC_ROM

; ---------------------------------------------------------------------------
; Enigma decompression algorithm
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Decomp_Eni:
		movem.l	d0-d7/a1-a5,-(sp)
		movea.w	d0,a3
		move.b	(a0)+,d0
		ext.w	d0
		movea.w	d0,a5
		move.b	(a0)+,d4
		lsl.b	#3,d4
		movea.w	(a0)+,a2
		adda.w	a3,a2
		movea.w	(a0)+,a4
		adda.w	a3,a4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6

loc_173E:				; XREF: loc_1768
		moveq	#7,d0
		move.w	d6,d7
		sub.w	d0,d7
		move.w	d5,d1
		lsr.w	d7,d1
		andi.w	#$7F,d1
		move.w	d1,d2
		cmpi.w	#$40,d1
		bcc.s	loc_1758
		moveq	#6,d0
		lsr.w	#1,d2

loc_1758:
		bsr.w	sub_188C
		andi.w	#$F,d2
		lsr.w	#4,d1
		add.w	d1,d1
		jmp	loc_17B4(pc,d1.w)
; End of function Decomp_Eni

; ===========================================================================

loc_1768:				; XREF: loc_17B4
		move.w	a2,(a1)+
		addq.w	#1,a2
		dbf	d2,loc_1768
		bra.s	loc_173E
; ===========================================================================

loc_1772:				; XREF: loc_17B4
		move.w	a4,(a1)+
		dbf	d2,loc_1772
		bra.s	loc_173E
; ===========================================================================

loc_177A:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_177E:
		move.w	d1,(a1)+
		dbf	d2,loc_177E
		bra.s	loc_173E
; ===========================================================================

loc_1786:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_178A:
		move.w	d1,(a1)+
		addq.w	#1,d1
		dbf	d2,loc_178A
		bra.s	loc_173E
; ===========================================================================

loc_1794:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_1798:
		move.w	d1,(a1)+
		subq.w	#1,d1
		dbf	d2,loc_1798
		bra.s	loc_173E
; ===========================================================================

loc_17A2:				; XREF: loc_17B4
		cmpi.w	#$F,d2
		beq.s	loc_17C4

loc_17A8:
		bsr.w	loc_17DC
		move.w	d1,(a1)+
		dbf	d2,loc_17A8
		bra.s	loc_173E
; ===========================================================================

loc_17B4:				; XREF: Decomp_Eni
		bra.s	loc_1768
; ===========================================================================
		bra.s	loc_1768
; ===========================================================================
		bra.s	loc_1772
; ===========================================================================
		bra.s	loc_1772
; ===========================================================================
		bra.s	loc_177A
; ===========================================================================
		bra.s	loc_1786
; ===========================================================================
		bra.s	loc_1794
; ===========================================================================
		bra.s	loc_17A2
; ===========================================================================

loc_17C4:				; XREF: loc_17A2
		subq.w	#1,a0
		cmpi.w	#$10,d6
		bne.s	loc_17CE
		subq.w	#1,a0

loc_17CE:
		move.w	a0,d0
		lsr.w	#1,d0
		bcc.s	loc_17D6
		addq.w	#1,a0

loc_17D6:
		movem.l	(sp)+,d0-d7/a1-a5
		rts	
; ===========================================================================

loc_17DC:				; XREF: loc_17A2
		move.w	a3,d3
		move.b	d4,d1
		add.b	d1,d1
		bcc.s	loc_17EE
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_17EE
		ori.w	#-$8000,d3

loc_17EE:
		add.b	d1,d1
		bcc.s	loc_17FC
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_17FC
		addi.w	#$4000,d3

loc_17FC:
		add.b	d1,d1
		bcc.s	loc_180A
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_180A
		addi.w	#$2000,d3

loc_180A:
		add.b	d1,d1
		bcc.s	loc_1818
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_1818
		ori.w	#$1000,d3

loc_1818:
		add.b	d1,d1
		bcc.s	loc_1826
		subq.w	#1,d6
		btst	d6,d5
		beq.s	loc_1826
		ori.w	#$800,d3

loc_1826:
		move.w	d5,d1
		move.w	d6,d7
		sub.w	a5,d7
		bcc.s	loc_1856
		move.w	d7,d6
		addi.w	#$10,d6
		neg.w	d7
		lsl.w	d7,d1
		move.b	(a0),d5
		rol.b	d7,d5
		add.w	d7,d7
		and.w	word_186C-2(pc,d7.w),d5
		add.w	d5,d1

loc_1844:				; XREF: loc_1868
		move.w	a5,d0
		add.w	d0,d0
		and.w	word_186C-2(pc,d0.w),d1
		add.w	d3,d1
		move.b	(a0)+,d5
		lsl.w	#8,d5
		move.b	(a0)+,d5
		rts	
; ===========================================================================

loc_1856:				; XREF: loc_1826
		beq.s	loc_1868
		lsr.w	d7,d1
		move.w	a5,d0
		add.w	d0,d0
		and.w	word_186C-2(pc,d0.w),d1
		add.w	d3,d1
		move.w	a5,d0
		bra.s	sub_188C
; ===========================================================================

loc_1868:				; XREF: loc_1856
		moveq	#$10,d6

loc_186A:
		bra.s	loc_1844
; ===========================================================================
word_186C:	dc.w 1,	3, 7, $F, $1F, $3F, $7F, $FF, $1FF, $3FF, $7FF
		dc.w $FFF, $1FFF, $3FFF, $7FFF,	$FFFF	; XREF: loc_1856

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_188C:				; XREF: Decomp_Eni
		sub.w	d0,d6
		cmpi.w	#9,d6
		bcc.s	locret_189A
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5

locret_189A:
		rts	
; End of function sub_188C

; ===========================================================================
; ---------------------------------------------------------------------------
; Kosinski decompression routine
;
; Created by vladikcomper
; Special thanks to flamewing and MarkeyJester
; ---------------------------------------------------------------------------

_Kos_RunBitStream macro
	dbf	d2,@skip\@
	moveq	#7,d2
	move.b	d1,d0
	swap	d3
	bpl.s	@skip\@
	move.b	(a0)+,d0			; get desc. bitfield
	move.b	(a0)+,d1			;
	move.b	(a4,d0.w),d0			; reload converted desc. bitfield from a LUT
	move.b	(a4,d1.w),d1			;
@skip\@
	endm
; ---------------------------------------------------------------------------

KosDec:
	moveq	#7,d7
	moveq	#0,d0
	moveq	#0,d1
	lea	KosDec_ByteMap(pc),a4
	move.b	(a0)+,d0			; get desc field low-byte
	move.b	(a0)+,d1			; get desc field hi-byte
	move.b	(a4,d0.w),d0			; reload converted desc. bitfield from a LUT
	move.b	(a4,d1.w),d1			;
	moveq	#7,d2				; set repeat count to 8
	moveq	#-1,d3				; d3 will be desc field switcher
	clr.w	d3				;
	bra.s	KosDec_FetchNewCode

KosDec_FetchCodeLoop:
	; code 1 (Uncompressed byte)
	_Kos_RunBitStream
	move.b	(a0)+,(a1)+

KosDec_FetchNewCode:
	add.b	d0,d0				; get a bit from the bitstream
	bcs.s	KosDec_FetchCodeLoop		; if code = 0, branch

	; codes 00 and 01
	_Kos_RunBitStream
	moveq	#0,d4				; d4 will contain copy count
	add.b	d0,d0				; get a bit from the bitstream
	bcs.s	KosDec_Code_01

	; code 00 (Dictionary ref. short)
	_Kos_RunBitStream
	add.b	d0,d0				; get a bit from the bitstream
	addx.w	d4,d4
	_Kos_RunBitStream
	add.b	d0,d0				; get a bit from the bitstream
	addx.w	d4,d4
	_Kos_RunBitStream
	moveq	#-1,d5
	move.b	(a0)+,d5			; d5 = displacement

KosDec_StreamCopy:
	lea	(a1,d5),a3
	move.b	(a3)+,(a1)+			; do 1 extra copy (to compensate for +1 to copy counter)

KosDec_copy:
	move.b	(a3)+,(a1)+
	dbf	d4,KosDec_copy
	bra.w	KosDec_FetchNewCode
; ---------------------------------------------------------------------------
KosDec_Code_01:
	; code 01 (Dictionary ref. long / special)
	_Kos_RunBitStream
	move.b	(a0)+,d6			; d6 = %LLLLLLLL
	move.b	(a0)+,d4			; d4 = %HHHHHCCC
	moveq	#-1,d5
	move.b	d4,d5				; d5 = %11111111 HHHHHCCC
	lsl.w	#5,d5				; d5 = %111HHHHH CCC00000
	move.b	d6,d5				; d5 = %111HHHHH LLLLLLLL
	and.w	d7,d4				; d4 = %00000CCC
	bne.s	KosDec_StreamCopy		; if CCC=0, branch

	; special mode (extended counter)
	move.b	(a0)+,d4			; read cnt
	beq.s	KosDec_Quit			; if cnt=0, quit decompression
	subq.b	#1,d4
	beq.w	KosDec_FetchNewCode		; if cnt=1, fetch a new code

	lea	(a1,d5),a3
	move.b	(a3)+,(a1)+			; do 1 extra copy (to compensate for +1 to copy counter)
	move.w	d4,d6
	not.w	d6
	and.w	d7,d6
	add.w	d6,d6
	lsr.w	#3,d4
	jmp	KosDec_largecopy(pc,d6.w)

KosDec_largecopy:
	rept 8
	move.b	(a3)+,(a1)+
	endr
	dbf	d4,KosDec_largecopy
	bra.w	KosDec_FetchNewCode

KosDec_Quit:
	rts

; ---------------------------------------------------------------------------
; A look-up table to invert bits order in desc. field bytes
; ---------------------------------------------------------------------------

KosDec_ByteMap:
	dc.b	$00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
	dc.b	$08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
	dc.b	$04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
	dc.b	$0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
	dc.b	$02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
	dc.b	$0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
	dc.b	$06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
	dc.b	$0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
	dc.b	$01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
	dc.b	$09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
	dc.b	$05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
	dc.b	$0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
	dc.b	$03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
	dc.b	$0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
	dc.b	$07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
	dc.b	$0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF

; ===========================================================================

; ---------------------------------------------------------------------------
; Pallet cycling routine loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Load:				; XREF: Demo; Level_MainLoop; End_MainLoop
		moveq	#0,d2
		moveq	#0,d0
		move.b	(lvl_id).w,d0 ; get level number
		add.w	d0,d0		; multiply by 2
		move.w	PalCycle(pc,d0.w),d0 ; load animated pallets offset index into d0
		jmp	PalCycle(pc,d0.w) ; jump to PalCycle + offset index
; End of function PalCycle_Load

; ===========================================================================
; ---------------------------------------------------------------------------
; Pallet cycling routines
; ---------------------------------------------------------------------------
PalCycle:	dc.w PalCycle_GHZ-PalCycle

PalCycle_GHZ:				; XREF: PalCycle
		rts	
; End of function PalCycle_SBZ

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	fade out and fade in
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalFade_ToTarget:
		move.w	#$3F,(fade_start).w

PalFade_ToTarget2:
		moveq	#0,d0
		lea	(pal_buffer).w,a0
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		moveq	#0,d1
		move.b	(fade_length).w,d0

Pal_ToBlack:
		move.w	d1,(a0)+
		dbf	d0,Pal_ToBlack	; fill pallet with $000	(black)
		moveq	#$0E,d4					; MJ: prepare maximum colour check
		moveq	#$00,d6					; MJ: clear d6

loc_1DCE:
		bsr.w	RunPLC_RAM
		move.b	#$12,(vint_routine).w
		bsr.w	VSync
		bchg	#$00,d6					; MJ: change delay counter
		beq	loc_1DCE				; MJ: if null, delay a frame
		bsr.s	Pal_FadeIn
		subq.b	#$02,d4					; MJ: decrease colour check
		bne	loc_1DCE				; MJ: if it has not reached null, branch
		move.b	#$12,(vint_routine).w			; MJ: wait for V-blank again (so colours transfer)
		bra	VSync				; MJ: ''

; End of function PalFade_ToTarget

; ---------------------------------------------------------------------------
; Pallet fade-in subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeIn:				; XREF: PalFade_ToTarget
		moveq	#0,d0
		lea	(pal_buffer).w,a0
		lea	(pal_target).w,a1
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(fade_length).w,d0

loc_1DFA:
		bsr.s	Pal_AddColor
		dbf	d0,loc_1DFA
		cmpi.b	#1,(lvl_id).w
		bne.s	locret_1E24
		moveq	#0,d0
		lea	(pal_water).w,a0
		lea	(pal_watertgt).w,a1
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(fade_length).w,d0

loc_1E1E:
		bsr.s	Pal_AddColor
		dbf	d0,loc_1E1E

locret_1E24:
		rts	
; End of function Pal_FadeIn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_AddColor:				; XREF: Pal_FadeIn
		move.b	(a1),d5					; MJ: load blue
		move.w	(a1)+,d1				; MJ: load green and red
		move.b	d1,d2					; MJ: load red
		lsr.b	#$04,d1					; MJ: get only green
		andi.b	#$0E,d2					; MJ: get only red
		move.w	(a0),d3					; MJ: load current colour in buffer
		cmp.b	d5,d4					; MJ: is it time for blue to fade?
		bhi	FCI_NoBlue				; MJ: if not, branch
		addi.w	#$0200,d3				; MJ: increase blue

FCI_NoBlue:
		cmp.b	d1,d4					; MJ: is it time for green to fade?
		bhi	FCI_NoGreen				; MJ: if not, branch
		addi.b	#$20,d3					; MJ: increase green

FCI_NoGreen:
		cmp.b	d2,d4					; MJ: is it time for red to fade?
		bhi	FCI_NoRed				; MJ: if not, branch
		addq.b	#$02,d3					; MJ: increase red

FCI_NoRed:
		move.w	d3,(a0)+				; MJ: save colour
		rts						; MJ: return

; End of function Pal_AddColor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalFade_ToBlack:
		move.w	#$3F,(fade_start).w
		moveq	#$07,d4					; MJ: set repeat times
		moveq	#$00,d6					; MJ: clear d6

loc_1E5C:
		bsr.w	RunPLC_RAM
		move.b	#$12,(vint_routine).w
		bsr.w	VSync
		bchg	#$00,d6					; MJ: change delay counter
		beq	loc_1E5C				; MJ: if null, delay a frame
		bsr.s	Pal_FadeOut
		dbf	d4,loc_1E5C
		rts	
; End of function PalFade_ToBlack

; ---------------------------------------------------------------------------
; Pallet fade-out subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeOut:				; XREF: PalFade_ToBlack
		moveq	#0,d0
		lea	(pal_buffer).w,a0
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		move.b	(fade_length).w,d0

loc_1E82:
		bsr.s	Pal_DecColor
		dbf	d0,loc_1E82

		moveq	#0,d0
		lea	(pal_water).w,a0
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		move.b	(fade_length).w,d0

loc_1E98:
		bsr.s	Pal_DecColor
		dbf	d0,loc_1E98
		rts	
; End of function Pal_FadeOut


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_DecColor:				; XREF: Pal_FadeOut
		move.w	(a0),d5					; MJ: load colour
		move.w	d5,d1					; MJ: copy to d1
		move.b	d1,d2					; MJ: load green and red
		move.b	d1,d3					; MJ: load red
		andi.w	#$0E00,d1				; MJ: get only blue
		beq	FCO_NoBlue				; MJ: if blue is finished, branch
		subi.w	#$0200,d5				; MJ: decrease blue

FCO_NoBlue:
		andi.w	#$00E0,d2				; MJ: get only green (needs to be word)
		beq	FCO_NoGreen				; MJ: if green is finished, branch
		subi.b	#$20,d5					; MJ: decrease green

FCO_NoGreen:
		andi.b	#$0E,d3					; MJ: get only red
		beq	FCO_NoRed				; MJ: if red is finished, branch
		subq.b	#$02,d5					; MJ: decrease red

FCO_NoRed:
		move.w	d5,(a0)+				; MJ: save new colour
		rts						; MJ: return

; End of function Pal_DecColor

; ---------------------------------------------------------------------------
; Subroutine to	fill the pallet	with white (special stage)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalFlash_ToTarget:				; XREF: SpecialStage
		move.w	#$3F,(fade_start).w
		moveq	#0,d0
		lea	(pal_buffer).w,a0
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		move.w	#$EEE,d1
		move.b	(fade_length).w,d0

PalWhite_Loop:
		move.w	d1,(a0)+
		dbf	d0,PalWhite_Loop
		move.w	#$15,d4

loc_1EF4:
		move.b	#$12,(vint_routine).w
		bsr.w	VSync
		bsr.s	Pal_WhiteToBlack
		bsr.w	RunPLC_RAM
		dbf	d4,loc_1EF4
		rts	
; End of function PalFlash_ToTarget


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_WhiteToBlack:			; XREF: PalFlash_ToTarget
		moveq	#0,d0
		lea	(pal_buffer).w,a0
		lea	(pal_target).w,a1
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(fade_length).w,d0

loc_1F20:
		bsr.s	Pal_DecColor2
		dbf	d0,loc_1F20

		cmpi.b	#1,(lvl_id).w
		bne.s	locret_1F4A
		moveq	#0,d0
		lea	(pal_water).w,a0
		lea	(pal_watertgt).w,a1
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(fade_length).w,d0

loc_1F44:
		bsr.s	Pal_DecColor2
		dbf	d0,loc_1F44

locret_1F4A:
		rts	
; End of function Pal_WhiteToBlack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_DecColor2:				; XREF: Pal_WhiteToBlack
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.s	loc_1F78
		move.w	d3,d1
		subi.w	#$200,d1	; decrease blue	value
		bcs.s	loc_1F64
		cmp.w	d2,d1
		bcs.s	loc_1F64
		move.w	d1,(a0)+
		rts	
; ===========================================================================

loc_1F64:				; XREF: Pal_DecColor2
		move.w	d3,d1
		subi.w	#$20,d1		; decrease green value
		bcs.s	loc_1F74
		cmp.w	d2,d1
		bcs.s	loc_1F74
		move.w	d1,(a0)+
		rts	
; ===========================================================================

loc_1F74:				; XREF: loc_1F64
		subq.w	#2,(a0)+	; decrease red value
		rts	
; ===========================================================================

loc_1F78:				; XREF: Pal_DecColor2
		addq.w	#2,a0
		rts	
; End of function Pal_DecColor2

; ---------------------------------------------------------------------------
; Subroutine to	make a white flash when	you enter a special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalFlash_ToWhite:				; XREF: SpecialStage
		move.w	#$3F,(fade_start).w
		move.w	#$15,d4

loc_1F86:
		move.b	#$12,(vint_routine).w
		bsr.w	VSync
		bsr.s	Pal_ToWhite
		bsr.w	RunPLC_RAM
		dbf	d4,loc_1F86
		rts	
; End of function PalFlash_ToWhite


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_ToWhite:				; XREF: PalFlash_ToWhite
		moveq	#0,d0
		lea	(pal_buffer).w,a0
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		move.b	(fade_length).w,d0

loc_1FAC:
		bsr.s	Pal_AddColor2
		dbf	d0,loc_1FAC
		moveq	#0,d0
		lea	(pal_water).w,a0
		move.b	(fade_start).w,d0
		adda.w	d0,a0
		move.b	(fade_length).w,d0

loc_1FC2:
		bsr.s	Pal_AddColor2
		dbf	d0,loc_1FC2
		rts	
; End of function Pal_ToWhite


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_AddColor2:				; XREF: Pal_ToWhite
		move.w	(a0),d2
		cmpi.w	#$EEE,d2
		beq.s	loc_2006
		move.w	d2,d1
		andi.w	#$E,d1
		cmpi.w	#$E,d1
		beq.s	loc_1FE2
		addq.w	#2,(a0)+	; increase red value
		rts	
; ===========================================================================

loc_1FE2:				; XREF: Pal_AddColor2
		move.w	d2,d1
		andi.w	#$E0,d1
		cmpi.w	#$E0,d1
		beq.s	loc_1FF4
		addi.w	#$20,(a0)+	; increase green value
		rts	
; ===========================================================================

loc_1FF4:				; XREF: loc_1FE2
		move.w	d2,d1
		andi.w	#$E00,d1
		cmpi.w	#$E00,d1
		beq.s	loc_2006
		addi.w	#$200,(a0)+	; increase blue	value
		rts	
; ===========================================================================

loc_2006:				; XREF: Pal_AddColor2
		addq.w	#2,a0
		rts	
; End of function Pal_AddColor2

; ---------------------------------------------------------------------------
; Subroutines to load pallets
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_LoadTarget:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		adda.w	#$80,a3
		move.w	(a1)+,d7

loc_2110:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2110
		rts	
; End of function Pal_LoadTarget


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_LoadDirect:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		move.w	(a1)+,d7

loc_2128:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2128
		rts	
; End of function Pal_LoadDirect

; ---------------------------------------------------------------------------
; Underwater pallet loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_LoadDrctWater:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$80,a3
		move.w	(a1)+,d7

loc_2144:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2144
		rts	
; End of function Pal_LoadDrctWater


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_LoadTrgrtWater:
		lea	(PalPointers).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$100,a3
		move.w	(a1)+,d7

loc_2160:
		move.l	(a2)+,(a3)+
		dbf	d7,loc_2160
		rts	
; End of function Pal_LoadTrgrtWater

; ===========================================================================
; ---------------------------------------------------------------------------
; Pallet pointers
; ---------------------------------------------------------------------------
PalPointers:
	dc.l Pal_GHZ		; pallet address
	dc.w $FB00		; RAM address
	dc.w (64/2)-1		; (pallet length / 2) - 1
	dc.l TitleNorm_Pal
	dc.w $FB00
	dc.w (64/2)-1
	dc.l TitleLight_Pal
	dc.w $FB00
	dc.w (64/2)-1
	dc.l Action_MainPal
	dc.w $FB00
	dc.w (32/2)-1
	dc.l Pal_GHZ
	dc.w $FB40
	dc.w (32/2)-1

; ---------------------------------------------------------------------------
; Pallet data
; ---------------------------------------------------------------------------
Pal_GHZ:	incbin	"Action Stage/Emerald/Palette.pal"


VSync:
		move	#$2300,sr

@Wait:
		tst.b	(vint_routine).w
		bne.s	@Wait
		rts


RandomNumber:
		move.l	(math_rannum).w,d1
		bne.s	loc_29C0
		move.l	#$2A6D365A,d1

loc_29C0:
		move.l	d1,d0
		asl.l	#2,d1
		add.l	d0,d1
		asl.l	#3,d1
		add.l	d0,d1
		move.w	d1,d0
		swap	d1
		add.w	d1,d0
		move.w	d0,d1
		swap	d1
		move.l	d1,(math_rannum).w
		rts	
; End of function RandomNumber


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Math_GetSine:				; XREF: SS_BGAnimate; et al
		andi.w	#$FF,d0
		add.w	d0,d0
		addi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d1
		subi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d0
		rts	
; End of function Math_GetSine

; ===========================================================================

Sine_Data:
		dc.w	$00, $06, $0C, $12, $19, $1F, $25, $2B, $31, $38, $3E, $44, $4A, $50, $56, $5C, $61, $67, $6D, $73, $78, $7E
		dc.w	$83, $88, $8E, $93, $98, $9D, $A2, $A7, $AB, $B0, $B5, $B9, $BD, $C1, $C5, $C9, $CD, $D1, $D4, $D8, $DB, $DE
		dc.w	$E1, $E4, $E7, $EA, $EC, $EE, $F1, $F3, $F4, $F6, $F8, $F9, $FB, $FC, $FD, $FE, $FE, $FF, $FF, $FF, $100, $FF
		dc.w	$FF, $FF, $FE, $FE, $FD, $FC, $FB, $F9, $F8, $F6, $F4, $F3, $F1, $EE, $EC, $EA, $E7, $E4, $E1, $DE, $DB, $D8
		dc.w	$D4, $D1, $CD, $C9, $C5, $C1, $BD, $B9, $B5, $B0, $AB, $A7, $A2, $9D, $98, $93, $8E, $88, $83, $7E, $78, $73
		dc.w	$6D, $67, $61, $5C, $56, $50, $4A, $44, $3E, $38, $31, $2B, $25, $1F, $19, $12, $0C, $06, $00
		dc.w	$FFFA, $FFF4, $FFEE, $FFE7, $FFE1, $FFDB, $FFD5, $FFCF, $FFC8, $FFC2, $FFBC, $FFB6, $FFB0, $FFAA, $FFA4
		dc.w	$FF9F, $FF99, $FF93, $FF8B, $FF88, $FF82, $FF7D, $FF78, $FF72, $FF6D, $FF68, $FF63, $FF5E, $FF59, $FF55
		dc.w	$FF50, $FF4B, $FF47, $FF43, $FF3F, $FF3B, $FF37, $FF33, $FF2F, $FF2C, $FF28, $FF25, $FF22, $FF1F, $FF1C
		dc.w	$FF19, $FF16, $FF14, $FF12, $FF0F, $FF0D, $FF0C, $FF0A, $FF08, $FF07, $FF05, $FF04, $FF03, $FF02, $FF02
		dc.w	$FF01, $FF01, $FF01, $FF00, $FF01, $FF01, $FF01, $FF02, $FF02, $FF03, $FF04, $FF05, $FF07, $FF08, $FF0A
		dc.w	$FF0C, $FF0D, $FF0F, $FF12, $FF14, $FF16, $FF19, $FF1C, $FF1F, $FF22, $FF25, $FF28, $FF2C, $FF2F, $FF33
		dc.w	$FF37, $FF3B, $FF3F, $FF43, $FF47, $FF4B, $FF50, $FF55, $FF59, $FF5E, $FF63, $FF68, $FF6D, $FF72, $FF78
		dc.w	$FF7D, $FF82, $FF88, $FF8B, $FF93, $FF99, $FF9F, $FFA4, $FFAA, $FFB0, $FFB6, $FFBC, $FFC2, $FFC8, $FFCF
		dc.w	$FFD5, $FFDB, $FFE1, $FFE7, $FFEE, $FFF4, $FFFA
		dc.w	$00, $06, $0C, $12, $19, $1F, $25, $2B, $31, $38, $3E, $44, $4A, $50, $56, $5C, $61, $67, $6D, $73, $78, $7E
		dc.w	$83, $88, $8E, $93, $98, $9D, $A2, $A7, $AB, $B0, $B5, $B9, $BD, $C1, $C5, $C9, $CD, $D1, $D4, $D8, $DB, $DE
		dc.w	$E1, $E4, $E7, $EA, $EC, $EE, $F1, $F3, $F4, $F6, $F8, $F9, $FB, $FC, $FD, $FE, $FE, $FF, $FF, $FF
		even

; ===========================================================================
		movem.l	d1-d2,-(sp)
		move.w	d0,d1
		swap	d1
		moveq	#0,d0
		move.w	d0,d1
		moveq	#7,d2

loc_2C80:
		rol.l	#2,d1
		add.w	d0,d0
		addq.w	#1,d0
		sub.w	d0,d1
		bcc.s	loc_2C9A
		add.w	d0,d1
		subq.w	#1,d0
		dbf	d2,loc_2C80
		lsr.w	#1,d0
		movem.l	(sp)+,d1-d2
		rts	
; ===========================================================================

loc_2C9A:
		addq.w	#1,d0
		dbf	d2,loc_2C80
		lsr.w	#1,d0
		movem.l	(sp)+,d1-d2
		rts	

; -------------------------------------------------------------------------
; 2-argument arctangent (angle between (0,0) and (x,y))
; Based on http://codebase64.org/doku.php?id=base:8bit_atan2_8-bit_angle
; -------------------------------------------------------------------------
; PARAMETERS:
;       d1.w - X value
;       d2.w - Y value
; RETURNS:
;       d0.b - 2-argument arctangent value (angle between (0,0) and (x,y))
; -------------------------------------------------------------------------

CalcAngle:
        moveq   #0,d0                           ; Default to bottom right quadrant
        tst.w   d1                              ; Is the X value negative?
        beq.s   CalcAngle_XZero                 ; If the X value is zero, branch
        bpl.s   CalcAngle_CheckY                ; If not, branch
        neg.w   d1                              ; If so, get the absolute value
        moveq   #4,d0                           ; Shift to left quadrant
 
CalcAngle_CheckY:
        tst.w   d2                              ; Is the Y value negative?
        beq.s   CalcAngle_YZero                 ; If the Y value is zero, branch
        bpl.s   CalcAngle_CheckOctet            ; If not, branch
        neg.w   d2                              ; If so, get the absolute value
        addq.b  #2,d0                           ; Shift to top quadrant

CalcAngle_CheckOctet:
        cmp.w   d2,d1                           ; Are we horizontally closer to the center?
        bcc.s   CalcAngle_Divide                ; If not, branch
        exg.l   d1,d2                           ; If so, divide Y from X instead
        addq.b  #1,d0                           ; Use octant that's horizontally closer to the center
 
CalcAngle_Divide:
        move.w  d1,-(sp)                        ; Shrink X and Y down into bytes
        moveq   #0,d3
        move.b  (sp)+,d3
        move.b  WordShiftTable(pc,d3.w),d3
        lsr.w   d3,d1
        lsr.w   d3,d2

        lea     Log2Table(pc),a2                ; Perform logarithmic division
        move.b  (a2,d2.w),d2
        sub.b   (a2,d1.w),d2
        bne.s   CalcAngle_GetAtan2Val
        move.w  #$FF,d2                         ; Edge case where X and Y values are too close for the division to handle

CalcAngle_GetAtan2Val:
        lea     Atan2Table(pc),a2               ; Get atan2 value
        move.b  (a2,d2.w),d2
        move.b  OctantAdjust(pc,d0.w),d0
        eor.b   d2,d0
        rts

; -------------------------------------------------------------------------

CalcAngle_YZero:
        tst.b   d0                              ; Was the X value negated?
        beq.s   CalcAngle_End                   ; If not, branch (d0 is already 0, so no need to set it again on branch)
        moveq   #$FFFFFF80,d0                   ; 180 degrees

CalcAngle_End:
        rts

CalcAngle_XZero:
        tst.w   d2                              ; Is the Y value negative?
        bmi.s   CalcAngle_XZeroYNeg             ; If so, branch
        moveq   #$40,d0                         ; 90 degrees
        rts

CalcAngle_XZeroYNeg:
        moveq   #$FFFFFFC0,d0                   ; 270 degrees
        rts
 
; -------------------------------------------------------------------------

OctantAdjust:
        dc.b    %00000000                       ; +X, +Y, |X|>|Y|
        dc.b    %00111111                       ; +X, +Y, |X|<|Y|
        dc.b    %11111111                       ; +X, -Y, |X|>|Y|
        dc.b    %11000000                       ; +X, -Y, |X|<|Y|
        dc.b    %01111111                       ; -X, +Y, |X|>|Y|
        dc.b    %01000000                       ; -X, +Y, |X|<|Y|
        dc.b    %10000000                       ; -X, -Y, |X|>|Y|
        dc.b    %10111111                       ; -X, -Y, |X|<|Y|

WordShiftTable:
        dc.b    $00, $01, $02, $02, $03, $03, $03, $03
        dc.b    $04, $04, $04, $04, $04, $04, $04, $04
        dc.b    $05, $05, $05, $05, $05, $05, $05, $05
        dc.b    $05, $05, $05, $05, $05, $05, $05, $05
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $06, $06, $06
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07
        dc.b    $07, $07, $07, $07, $07, $07, $07, $07

Log2Table:
        dc.b    $00, $00, $1F, $32, $3F, $49, $52, $59
        dc.b    $5F, $64, $69, $6E, $72, $75, $79, $7C
        dc.b    $7F, $82, $84, $87, $89, $8C, $8E, $90
        dc.b    $92, $94, $95, $97, $99, $9A, $9C, $9E
        dc.b    $9F, $A0, $A2, $A3, $A4, $A6, $A7, $A8
        dc.b    $A9, $AA, $AC, $AD, $AE, $AF, $B0, $B1
        dc.b    $B2, $B3, $B4, $B5, $B5, $B6, $B7, $B8
        dc.b    $B9, $BA, $BA, $BB, $BC, $BD, $BE, $BE
        dc.b    $BF, $C0, $C0, $C1, $C2, $C2, $C3, $C4
        dc.b    $C4, $C5, $C6, $C6, $C7, $C8, $C8, $C9
        dc.b    $C9, $CA, $CA, $CB, $CC, $CC, $CD, $CD
        dc.b    $CE, $CE, $CF, $CF, $D0, $D0, $D1, $D1
        dc.b    $D2, $D2, $D3, $D3, $D4, $D4, $D5, $D5
        dc.b    $D5, $D6, $D6, $D7, $D7, $D8, $D8, $D8
        dc.b    $D9, $D9, $DA, $DA, $DA, $DB, $DB, $DC
        dc.b    $DC, $DC, $DD, $DD, $DE, $DE, $DE, $DF
        dc.b    $DF, $DF, $E0, $E0, $E0, $E1, $E1, $E1
        dc.b    $E2, $E2, $E2, $E3, $E3, $E3, $E4, $E4
        dc.b    $E4, $E5, $E5, $E5, $E6, $E6, $E6, $E7
        dc.b    $E7, $E7, $E8, $E8, $E8, $E8, $E9, $E9
        dc.b    $E9, $EA, $EA, $EA, $EA, $EB, $EB, $EB
        dc.b    $EC, $EC, $EC, $EC, $ED, $ED, $ED, $ED
        dc.b    $EE, $EE, $EE, $EE, $EF, $EF, $EF, $F0
        dc.b    $F0, $F0, $F0, $F1, $F1, $F1, $F1, $F1
        dc.b    $F2, $F2, $F2, $F2, $F3, $F3, $F3, $F3
        dc.b    $F4, $F4, $F4, $F4, $F5, $F5, $F5, $F5
        dc.b    $F5, $F6, $F6, $F6, $F6, $F7, $F7, $F7
        dc.b    $F7, $F7, $F8, $F8, $F8, $F8, $F8, $F9
        dc.b    $F9, $F9, $F9, $F9, $FA, $FA, $FA, $FA
        dc.b    $FA, $FB, $FB, $FB, $FB, $FB, $FC, $FC
        dc.b    $FC, $FC, $FC, $FD, $FD, $FD, $FD, $FD
        dc.b    $FE, $FE, $FE, $FE, $FE, $FE, $FF, $FF

Atan2Table:
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $00, $00
        dc.b    $00, $00, $00, $00, $00, $00, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $01, $01, $01, $01, $01, $01, $01
        dc.b    $01, $02, $02, $02, $02, $02, $02, $02
        dc.b    $02, $02, $02, $02, $02, $02, $02, $02
        dc.b    $02, $02, $02, $02, $02, $02, $02, $02
        dc.b    $03, $03, $03, $03, $03, $03, $03, $03
        dc.b    $03, $03, $03, $03, $03, $03, $03, $03
        dc.b    $04, $04, $04, $04, $04, $04, $04, $04
        dc.b    $04, $04, $04, $05, $05, $05, $05, $05
        dc.b    $05, $05, $05, $05, $05, $06, $06, $06
        dc.b    $06, $06, $06, $06, $06, $07, $07, $07
        dc.b    $07, $07, $07, $08, $08, $08, $08, $08
        dc.b    $08, $09, $09, $09, $09, $09, $09, $0A
        dc.b    $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0B
        dc.b    $0C, $0C, $0C, $0C, $0D, $0D, $0D, $0D
        dc.b    $0E, $0E, $0E, $0F, $0F, $0F, $0F, $10
        dc.b    $10, $10, $11, $11, $11, $12, $12, $12
        dc.b    $13, $13, $13, $14, $14, $14, $15, $15
        dc.b    $16, $16, $16, $17, $17, $17, $18, $18
        dc.b    $19, $19, $1A, $1A, $1A, $1B, $1B, $1C
        dc.b    $1C, $1C, $1D, $1D, $1E, $1E, $1F, $1F

; ===========================================================================

		include	"Title Screen/Script.asm"

; ---------------------------------------------------------------------------
; Music	playlist
; ---------------------------------------------------------------------------
MusicList:
		dc.b	$81, $82, $83, $84, $85, $86, $8D
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

Level:					; XREF: GameModeArray
		bset	#7,(gm_scene).w ; add $80 to screen mode (for pre level sequence)
		move.b	#$E0,d0
		bsr.w	Sound_CueSFX ; fade out music
		bsr.w	ClearPLC
		bsr.w	PalFade_ToBlack
		move	#$2700,sr
		move.l	#$70000002,($C00004).l
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	Decomp_Nem
		move	#$2300,sr
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	loc_37FC
		bsr.w	LoadPLC		; load level patterns

loc_37FC:
		moveq	#1,d0
		bsr.w	LoadPLC		; load standard	patterns
		lea	(act_buffer).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Level_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrObjRam ; clear object RAM

		lea	($FFFFF628).w,a1
		moveq	#0,d0
		move.w	#$15,d1

Level_ClrVars:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars ; clear misc variables

		lea	(lvl_fgxpos).w,a1
		moveq	#0,d0
		move.w	#$3F,d1

Level_ClrVars2:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars2 ; clear misc variables

		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$47,d1

Level_ClrVars3:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars3 ; clear object variables

		move	#$2700,sr
		bsr.w	VDP_Clear
		lea	($C00004).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$857C,(a6)
		move.w	#$9001,(a6)
		move.w	#$8004,(a6)
		move.w	#$8720,(a6)
		move.w	#$8C81,(a6)
		move.w	#$8ADF,(vdp_hintpos).w
		move.w	(vdp_hintpos).w,(a6)
		cmpi.b	#1,(lvl_id).w ; is level LZ?
		bne.s	Level_LoadPal	; if not, branch
		move.w	#$8014,(a6)
		moveq	#0,d0
		move.b	($FFFFFE11).w,d0
		add.w	d0,d0
		lea	(WaterHeight).l,a1 ; load water	height array
		move.w	(a1,d0.w),d0
		move.w	d0,($FFFFF646).w ; set water heights
		move.w	d0,(water_avg).w
		move.w	d0,($FFFFF64A).w
		clr.b	(water_routine).w	; clear	water routine counter
		clr.b	(water_fullscr).w	; clear	water movement
		move.b	#1,($FFFFF64C).w ; enable water

Level_LoadPal:
		move.w	#$1E,($FFFFFE14).w
		move	#$2300,sr
		moveq	#3,d0
		bsr.w	Pal_LoadDirect	; load Sonic's pallet line
		cmpi.b	#1,(lvl_id).w ; is level LZ?
		bne.s	Level_GetBgm	; if not, branch
		moveq	#$B,d0		; pallet number	$0F (LZ)
		bsr.w	Pal_LoadDrctWater	; load underwater pallet (see d0)
		tst.b	(cp_idx).w
		beq.s	Level_GetBgm
		move.b	(cp_waterfull).w,(water_fullscr).w

Level_GetBgm:
		tst.w	($FFFFFFF0).w
		bmi.s	loc_3946
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		cmpi.w	#$103,(lvl_id).w ; is level SBZ3?
		bne.s	Level_BgmNotLZ4	; if not, branch
		moveq	#5,d0		; move 5 to d0

Level_BgmNotLZ4:
		cmpi.w	#$502,(lvl_id).w ; is level FZ?
		bne.s	Level_PlayBgm	; if not, branch
		moveq	#6,d0		; move 6 to d0

Level_PlayBgm:
		lea	(MusicList).l,a1 ; load	music playlist
		move.b	(a1,d0.w),d0	; add d0 to a1
		bsr.w	Sound_CueMusic	; play music
		move.b	#$34,($FFFFD080).w ; load title	card object

Level_TtlCard:
		move.b	#$C,(vint_routine).w
		bsr.w	VSync
		jsr	Actor_Execute
		jsr	Sprites_Render
		bsr.w	RunPLC_RAM
		move.w	($FFFFD108).w,d0
		cmp.w	($FFFFD130).w,d0 ; has title card sequence finished?
		bne.s	Level_TtlCard	; if not, branch
		tst.l	(gfx_queue).w	; are there any	items in the pattern load cue?
		bne.s	Level_TtlCard	; if yes, branch
		jsr	Hud_Base

loc_3946:
		moveq	#3,d0
		bsr.w	Pal_LoadTarget	; load Sonic's pallet line
		bsr.w	LevelSizeLoad
		bsr.w	DeformBgLayer
		bset	#2,($FFFFF754).w
		bsr.w	MainLoadBlockLoad ; load block mappings	and pallets
		bsr.w	LoadTilesFromStart
		bsr.w	ColIndexLoad
		move.b	#1,($FFFFD000).w ; load	Sonic object
		tst.w	($FFFFFFF0).w
		bmi.s	Level_ChkDebug
		move.b	#$21,($FFFFD040).w ; load HUD object

Level_ChkDebug:
		tst.b	($FFFFFFE2).w	; has debug cheat been entered?
		beq.s	Level_ChkWater	; if not, branch
		btst	#6,(jpad_held).w ; is A	button pressed?
		beq.s	Level_ChkWater	; if not, branch
		move.b	#1,($FFFFFFFA).w ; enable debug	mode

Level_ChkWater:
		move.w	#0,(plyr_btnheld).w
		move.w	#0,(jpad_held).w
		cmpi.b	#1,(lvl_id).w ; is level LZ?
		bne.s	Level_LoadObj	; if not, branch
		move.b	#$1B,($FFFFD780).w ; load water	surface	object
		move.w	#$60,($FFFFD788).w
		move.b	#$1B,($FFFFD7C0).w
		move.w	#$120,($FFFFD7C8).w

Level_LoadObj:
		jsr	ObjPosLoad
		jsr	Actor_Execute
		jsr	Sprites_Render
		moveq	#0,d0
		tst.b	(cp_idx).w	; are you starting from	a lamppost?
		bne.s	loc_39E8	; if yes, branch
		move.w	d0,(plyr_rings).w ; clear rings
		move.l	d0,(time_minutes).w ; clear time

loc_39E8:
		move.b	d0,(plyr_air).w
		move.b	d0,(plyr_shieldflag).w ; clear shield
		move.b	d0,(plyr_invincflag).w ; clear invincibility
		move.b	d0,(plyr_speedflag).w ; clear speed shoes
		move.w	d0,($FFFFFE08).w
		move.w	d0,($FFFFFE02).w
		move.w	d0,($FFFFFE04).w
		bsr.w	OscillateNumInit
		move.b	#1,($FFFFFE1F).w ; update score	counter
		move.b	#1,($FFFFFE1D).w ; update rings	counter
		move.b	#1,($FFFFFE1E).w ; update time counter
		move.w	#0,($FFFFF790).w
		cmpi.b	#1,(lvl_id).w ; is level LZ/SBZ3?
		bne.s	Level_Delay	; if not, branch
		moveq	#$A,d0		; pallet $0B (LZ underwater)
		bsr.w	Pal_LoadTrgrtWater

Level_Delay:
		move.w	#3,d1

Level_DelayLoop:
		move.b	#8,(vint_routine).w
		bsr.w	VSync
		dbf	d1,Level_DelayLoop

		move.w	#$202F,(fade_start).w
		bsr.w	PalFade_ToTarget2
		tst.w	($FFFFFFF0).w
		bmi.s	Level_ClrCardArt
		addq.b	#2,($FFFFD0A4).w ; make	title card move
		addq.b	#4,($FFFFD0E4).w
		addq.b	#4,($FFFFD124).w
		addq.b	#4,($FFFFD164).w
		bra.s	Level_StartGame
; ===========================================================================

Level_ClrCardArt:
		moveq	#2,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		addi.w	#$15,d0
		jsr	(LoadPLC).l	; load animal patterns (level no. + $15)

Level_StartGame:
		bclr	#7,(gm_scene).w ; subtract 80 from screen mode

; ---------------------------------------------------------------------------
; Main level loop (when	all title card and loading sequences are finished)
; ---------------------------------------------------------------------------

Level_MainLoop:
		bsr.w	PauseGame
		move.b	#8,(vint_routine).w
		bsr.w	VSync
		addq.w	#1,($FFFFFE04).w ; add 1 to level timer
		jsr	Actor_Execute
		tst.w	($FFFFFE02).w	; is the level set to restart?
		bne.w	Level		; if yes, branch
		tst.w	($FFFFFE08).w
		bne.s	loc_3B10
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.s	loc_3B14

loc_3B10:
		bsr.w	DeformBgLayer

loc_3B14:
		jsr	Sprites_Render
		jsr	ObjPosLoad
		bsr.w	PalCycle_Load
		bsr.w	RunPLC_RAM
		bsr.w	OscillateNumDo
		bsr.w	ChangeRingFrame
		bsr.w	SignpostArtLoad
		cmpi.b	#SCNID_GAME,(gm_scene).w
		beq.w	Level_MainLoop	; if screen mode is $0C	(level), branch
		rts	
; ---------------------------------------------------------------------------
; Labyrinth default water heights
; ---------------------------------------------------------------------------
WaterHeight:
		dc.w	$00B8, $0328, $0900, $0228
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Collision index loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ColIndexLoad:				; XREF: Level
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		lsl.w	#$03,d0					; MJ: multiply by 8 not 4
		move.l	ColPointers(pc,d0.w),($FFFFFFD0).w	; MJ: get first collision set
		add.w	#$04,d0					; MJ: increase to next location
		move.l	ColPointers(pc,d0.w),($FFFFFFD4).w	; MJ: get second collision set
		rts	
; End of function ColIndexLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision index pointers
; ---------------------------------------------------------------------------
ColPointers:
	dc.l Col_GHZ_1
	dc.l Col_GHZ_2
; ---------------------------------------------------------------------------
; Oscillating number subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


OscillateNumInit:			; XREF: Level
		lea	(math_oscvals).w,a1
		lea	(Osc_Data).l,a2
		moveq	#$20,d1

Osc_Loop:
		move.w	(a2)+,(a1)+
		dbf	d1,Osc_Loop
		rts	
; End of function OscillateNumInit

; ===========================================================================
Osc_Data:	dc.w $7C, $80		; baseline values
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$50F0
		dc.w $11E, $2080
		dc.w $B4, $3080
		dc.w $10E, $5080
		dc.w $1C2, $7080
		dc.w $276, $80
		dc.w 0,	$80
		dc.w 0
		even

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


OscillateNumDo:				; XREF: Level
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.s	locret_41C4
		lea	(math_oscvals).w,a1
		lea	(Osc_Data2).l,a2
		move.w	(a1)+,d3
		moveq	#$F,d1

loc_4184:
		move.w	(a2)+,d2
		move.w	(a2)+,d4
		btst	d1,d3
		bne.s	loc_41A4
		move.w	2(a1),d0
		add.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bhi.s	loc_41BA
		bset	d1,d3
		bra.s	loc_41BA
; ===========================================================================

loc_41A4:				; XREF: OscillateNumDo
		move.w	2(a1),d0
		sub.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bls.s	loc_41BA
		bclr	d1,d3

loc_41BA:
		addq.w	#4,a1
		dbf	d1,loc_4184
		move.w	d3,(math_oscvals).w

locret_41C4:
		rts	
; End of function OscillateNumDo

; ===========================================================================
Osc_Data2:	dc.w 2,	$10		; XREF: OscillateNumDo
		dc.w 2,	$18
		dc.w 2,	$20
		dc.w 2,	$30
		dc.w 4,	$20
		dc.w 8,	8
		dc.w 8,	$40
		dc.w 4,	$40
		dc.w 2,	$50
		dc.w 2,	$50
		dc.w 2,	$20
		dc.w 3,	$30
		dc.w 5,	$50
		dc.w 7,	$70
		dc.w 2,	$10
		dc.w 2,	$10
		even

; ---------------------------------------------------------------------------
; Subroutine to	change object animation	variables (rings, giant	rings)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChangeRingFrame:			; XREF: Level
		subq.b	#1,(ani_ringtime).w
		bpl.s	loc_4250
		move.b	#7,(ani_ringtime).w
		addq.b	#1,(ani_ringframe).w
		andi.b	#3,(ani_ringframe).w

loc_4250:
		tst.b	(ani_drprngtime).w
		beq.s	locret_4272
		moveq	#0,d0
		move.b	(ani_drprngtime).w,d0
		add.w	(ani_drprngaccu).w,d0
		move.w	d0,(ani_drprngaccu).w
		rol.w	#7,d0
		andi.w	#3,d0
		move.b	d0,(ani_drprngframe).w
		subq.b	#1,(ani_drprngtime).w

locret_4272:
		rts	
; End of function ChangeRingFrame

; ---------------------------------------------------------------------------
; End-of-act signpost pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SignpostArtLoad:			; XREF: Level
		tst.w	($FFFFFE08).w	; is debug mode	being used?
		bne.w	Signpost_Exit	; if yes, branch
		cmpi.b	#2,($FFFFFE11).w ; is act number 02 (act 3)?
		beq.s	Signpost_Exit	; if yes, branch
		move.w	(lvl_fgxpos).w,d0
		move.w	(bound_right).w,d1
		subi.w	#$100,d1
		cmp.w	d1,d0		; has Sonic reached the	edge of	the level?
		blt.s	Signpost_Exit	; if not, branch
		tst.b	($FFFFFE1E).w
		beq.s	Signpost_Exit
		cmp.w	(bound_left).w,d1
		beq.s	Signpost_Exit
		move.w	d1,(bound_left).w ; move	left boundary to current screen	position
		moveq	#$12,d0
		bra.w	LoadPLC2	; load signpost	patterns
; ===========================================================================

Signpost_Exit:
		rts	
; End of function SignpostArtLoad

; ---------------------------------------------------------------------------
; Subroutine to	load level boundaries and start	locations
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelSizeLoad:				; XREF: TitleScreen; Level; EndingSequence
		moveq	#0,d0
		move.b	d0,($FFFFF740).w
		move.b	d0,($FFFFF741).w
		move.b	d0,($FFFFF746).w
		move.b	d0,($FFFFF748).w
		move.b	d0,(lvl_eventid).w
		move.w	(lvl_id).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		lea	LevelSizeArray(pc,d0.w),a0 ; load level	boundaries
		move.w	(a0)+,d0
		move.w	d0,($FFFFF730).w
		move.l	(a0)+,d0
		move.l	d0,(bound_left).w
		move.l	d0,( bound_ltarget).w
		move.l	(a0)+,d0
		move.l	d0,(bound_up).w
		move.l	d0,(bound_utarget).w
		move.w	(bound_left).w,d0
		addi.w	#$240,d0
		move.w	d0,($FFFFF732).w
		move.w	#$1010,(redraw_dofgx).w
		move.w	(a0)+,d0
		move.w	d0,(cam_ypos).w
		bra.w	LevSz_ChkLamp
; ===========================================================================
; ---------------------------------------------------------------------------
; Level size array and ending start location array
; ---------------------------------------------------------------------------
LevelSizeArray:
		dc.w $0004, $0000, $24BF, $0000, $0300, $0060
		even

; ===========================================================================

LevSz_ChkLamp:				; XREF: LevelSizeLoad
		tst.b	(cp_idx).w	; have any lampposts been hit?
		beq.s	LevSz_StartLoc	; if not, branch
		jsr	Obj79_LoadInfo
		move.w	(ACTSLOT_PLAYER+act_xpos).w,d1
		move.w	(ACTSLOT_PLAYER+act_ypos).w,d0
		bra.s	loc_60D0
; ===========================================================================

LevSz_StartLoc:				; XREF: LevelSizeLoad
		move.w	(lvl_id).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(StartLocArray).l,a1			; MJ: load location array
		lea	(a1,d0.w),a1				; MJ: load Sonic's start location address
		moveq	#0,d1
		move.w	(a1)+,d1
		move.w	d1,(ACTSLOT_PLAYER+act_xpos).w ; set Sonic's position on x-axis
		moveq	#0,d0
		move.w	(a1),d0
		move.w	d0,(ACTSLOT_PLAYER+act_ypos).w ; set Sonic's position on y-axis
		move.b	(gm_scene).w,d2			; MJ: load game mode
		andi.w	#$00FC,d2				; MJ: keep in range
		cmpi.b	#$04,d2					; MJ: is screen mode at title?
		bne	loc_60D0				; MJ: if not, branch
		move.w	#$0050,d1				; MJ: set positions for title screen
		move.w	#$03B0,d0				; MJ: ''
		move.w	d1,(ACTSLOT_PLAYER+act_xpos).w			; MJ: save to object 1 so title screen follows
		move.w	d0,(ACTSLOT_PLAYER+act_ypos).w			; MJ: ''

loc_60D0:				; XREF: LevSz_ChkLamp
		subi.w	#$A0,d1
		bcc.s	loc_60D8
		moveq	#0,d1

loc_60D8:
		move.w	(bound_right).w,d2
		cmp.w	d2,d1
		bcs.s	loc_60E2
		move.w	d2,d1

loc_60E2:
		move.w	d1,(lvl_fgxpos).w
		subi.w	#$60,d0
		bcc.s	loc_60EE
		moveq	#0,d0

loc_60EE:
		cmp.w	(bound_down).w,d0
		blt.s	loc_60F8
		move.w	(bound_down).w,d0

loc_60F8:
		move.w	d0,(lvl_fgypos).w
		bsr.w	BgScrollSpeed
		bra.w	LevSz_Unk

; ===========================================================================
; ---------------------------------------------------------------------------
; MJ: Sonic start location array
; ---------------------------------------------------------------------------

StartLocArray:	incbin	"Action Stage/Emerald/Sonic Start.pos"
		even

LevSz_Unk:				; XREF: LevelSizeLoad
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		lsl.w	#3,d0
		lea	dword_61B4(pc,d0.w),a1
		lea	($FFFFF7F0).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		rts	
; End of function LevelSizeLoad

; ===========================================================================
dword_61B4:	dc.l $700100, $1000100

; ---------------------------------------------------------------------------
; Subroutine to	set scroll speed of some backgrounds
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BgScrollSpeed:				; XREF: LevelSizeLoad
		tst.b	(cp_idx).w
		bne.s	loc_6206
		move.w	d0,(lvl_bg1ypos).w
		move.w	d0,(lvl_bg2ypos).w
		move.w	d1,(lvl_bg1xpos).w
		move.w	d1,(lvl_bg2xpos).w
		move.w	d1,(lvl_bg3xpos).w

loc_6206:
		moveq	#0,d2
		move.b	(lvl_id).w,d2
		add.w	d2,d2
		move.w	BgScroll_Index(pc,d2.w),d2
		jmp	BgScroll_Index(pc,d2.w)
; End of function BgScrollSpeed

; ===========================================================================
BgScroll_Index:	dc.w BgScroll_GHZ-BgScroll_Index
; ===========================================================================

BgScroll_GHZ:				; XREF: BgScroll_Index
		clr.l	(lvl_bg1xpos).w
		clr.l	(lvl_bg1ypos).w
		clr.l	(lvl_bg2ypos).w
		clr.l	(lvl_bg3ypos).w
		lea	(scr_blockbuff).w,a2
		clr.l	(a2)+
		clr.l	(a2)+
		clr.l	(a2)+
		rts 
; ---------------------------------------------------------------------------
; Background layer deformation subroutines
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DeformBgLayer:				; XREF: TitleScreen; Level; EndingSequence
		tst.b	(scr_disable).w
		beq.s	loc_628E
		rts	
; ===========================================================================

loc_628E:
		clr.w	($FFFFF754).w
		clr.w	(redraw_bg1flags).w
		clr.w	(redraw_bg2flags).w
		clr.w	(redraw_bg3flags).w
		bsr.w	ScrollHoriz
		bsr.w	ScrollVertical
		bsr.w	DynScrResizeLoad
		move.w	(lvl_fgypos).w,(vdp_fgypos).w
		move.w	(lvl_bg1ypos).w,(vdp_bgypos).w
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		add.w	d0,d0
		move.w	Deform_Index(pc,d0.w),d0
		jmp	Deform_Index(pc,d0.w)
; End of function DeformBgLayer

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for background layer deformation	code
; ---------------------------------------------------------------------------
Deform_Index:	dc.w Deform_GHZ-Deform_Index
; ---------------------------------------------------------------------------
; Green	Hill Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_GHZ:
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#5,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#0,d6
		bsr.w	ScrollBlock6
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#7,d4
		moveq	#0,d6
		bsr.w	ScrollBlock5
		lea	(scr_horibuff).w,a1
		move.w	(lvl_fgypos).w,d0
		andi.w	#$7FF,d0
		lsr.w	#5,d0
		neg.w	d0
		addi.w	#$20,d0	; ' '
		bpl.s	Deform_GHZ_1
		moveq	#0,d0

Deform_GHZ_1:				; XREF: Deform_GHZ
		move.w	d0,d4
		move.w	d0,(vdp_bgypos).w
		move.w	(lvl_fgxpos).w,d0
		neg.w	d0
		swap	d0
		lea	(scr_blockbuff).w,a2
		addi.l	#$10000,(a2)+
		addi.l	#$C000,(a2)+
		addi.l	#$8000,(a2)+
		move.w	(scr_blockbuff).w,d0
		add.w	(lvl_bg3xpos).w,d0
		neg.w	d0
		move.w	#$1F,d1
		sub.w	d4,d1
		bcs.s	Deform_GHZ_4

Deform_GHZ_3:				; XREF: Deform_GHZ
		move.l	d0,(a1)+
		dbf	d1,Deform_GHZ_3

Deform_GHZ_4:				; XREF: Deform_GHZ
		move.w	($FFFFA804).w,d0
		add.w	(lvl_bg3xpos).w,d0
		neg.w	d0
		move.w	#$F,d1

Deform_GHZ_5:				; XREF: Deform_GHZ
		move.l	d0,(a1)+
		dbf	d1,Deform_GHZ_5
		move.w	($FFFFA808).w,d0
		add.w	(lvl_bg3xpos).w,d0
		neg.w	d0
		move.w	#$F,d1

Deform_GHZ_6:				; XREF: Deform_GHZ
		move.l	d0,(a1)+
		dbf	d1,Deform_GHZ_6
		move.w	#$2F,d1	; '/'
		move.w	(lvl_bg3xpos).w,d0
		neg.w	d0

Deform_GHZ_7:				; XREF: Deform_GHZ
		move.l	d0,(a1)+
		dbf	d1,Deform_GHZ_7
		move.w	#$27,d1	; '''
		move.w	(lvl_bg2xpos).w,d0
		neg.w	d0

Deform_GHZ_8:				; XREF: Deform_GHZ
		move.l	d0,(a1)+
		dbf	d1,Deform_GHZ_8
		move.w	(lvl_bg2xpos).w,d0
		move.w	(lvl_fgxpos).w,d2
		sub.w	d0,d2
		ext.l	d2
		asl.l	#8,d2
		divs.w	#$68,d2	; 'h'
		ext.l	d2
		asl.l	#8,d2
		moveq	#0,d3
		move.w	d0,d3
		move.w	#$47,d1	; 'G'
		add.w	d4,d1

Deform_GHZ_9:				; XREF: Deform_GHZ
		move.w	d3,d0
		neg.w	d0
		move.l	d0,(a1)+
		swap	d3
		add.l	d2,d3
		swap	d3
		dbf	d1,Deform_GHZ_9
		rts	
; End of function Deform_GHZ

Deform_All:				; XREF: Deform_MZ, Deform_SYZ, ...
		lea	(scr_horibuff).w,a1
		move.w	#$E,d1
		move.w	(lvl_fgxpos).w,d0
		neg.w	d0
		swap	d0
		andi.w	#$F,d2
		add.w	d2,d2
		move.w	(a2)+,d0
		jmp	Deform_All_2(pc,d2.w)
; End of function Deform_MZ

; ===========================================================================

Deform_All_1:				; XREF: Deform_All
		move.w	(a2)+,d0

Deform_All_2:
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		dbf	d1,Deform_All_1
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	scroll the level horizontally as Sonic moves
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollHoriz:				; XREF: DeformBgLayer
		move.w	(lvl_fgxpos).w,d4
		bsr.s	ScrollHoriz2
		move.w	(lvl_fgxpos).w,d0
		andi.w	#$10,d0
		move.b	(redraw_dofgx).w,d1
		eor.b	d1,d0
		bne.s	locret_65B0
		eori.b	#$10,(redraw_dofgx).w
		move.w	(lvl_fgxpos).w,d0
		sub.w	d4,d0
		bpl.s	loc_65AA
		bset	#2,($FFFFF754).w
		rts	
; ===========================================================================

loc_65AA:
		bset	#3,($FFFFF754).w

locret_65B0:
		rts	
; End of function ScrollHoriz


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollHoriz2:				; XREF: ScrollHoriz
		move.w	(ACTSLOT_PLAYER+act_xpos).w,d0
		sub.w	(lvl_fgxpos).w,d0
		subi.w	#$90,d0
		bmi.s	loc_65F6				; cs to mi (for negative)
		subi.w	#$10,d0
		bpl.s	loc_65CC				; cc to pl (for negative)
		clr.w	($FFFFF73A).w
		rts
; ===========================================================================

loc_65CC:
		cmpi.w	#$10,d0
		bcs.s	loc_65D6
		move.w	#$10,d0

loc_65D6:
		add.w	(lvl_fgxpos).w,d0
		cmp.w	(bound_right).w,d0
		blt.s	loc_65E4
		move.w	(bound_right).w,d0

loc_65E4:
		move.w	d0,d1
		sub.w	(lvl_fgxpos).w,d1
		asl.w	#8,d1
		move.w	d0,(lvl_fgxpos).w
		move.w	d1,($FFFFF73A).w
		rts	
; ===========================================================================

loc_65F6:				; XREF: ScrollHoriz2
		add.w	(lvl_fgxpos).w,d0
		cmp.w	(bound_left).w,d0
		bgt.s	loc_65E4
		move.w	(bound_left).w,d0
		bra.s	loc_65E4
; End of function ScrollHoriz2

; ===========================================================================
		tst.w	d0
		bpl.s	loc_6610
		move.w	#-2,d0
		bra.s	loc_65F6
; ===========================================================================

loc_6610:
		move.w	#2,d0
		bra.s	loc_65CC

; ---------------------------------------------------------------------------
; Subroutine to	scroll the level vertically as Sonic moves
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollVertical:				; XREF: DeformBgLayer
		moveq	#0,d1
		move.w	(ACTSLOT_PLAYER+act_ypos).w,d0
		sub.w	(lvl_fgypos).w,d0
		btst	#2,(ACTSLOT_PLAYER+act_status).w
		beq.s	loc_662A
		subq.w	#5,d0

loc_662A:
		btst	#1,(ACTSLOT_PLAYER+act_status).w
		beq.s	loc_664A
		addi.w	#$20,d0
		sub.w	(cam_ypos).w,d0
		bcs.s	loc_6696
		subi.w	#$40,d0
		bcc.s	loc_6696
		tst.b	(bound_ismoving).w
		bne.s	loc_66A8
		bra.s	loc_6656
; ===========================================================================

loc_664A:
		sub.w	(cam_ypos).w,d0
		bne.s	loc_665C
		tst.b	(bound_ismoving).w
		bne.s	loc_66A8

loc_6656:
		clr.w	($FFFFF73C).w
		rts	
; ===========================================================================

loc_665C:
		cmpi.w	#$60,(cam_ypos).w
		bne.s	loc_6684
		move.w	(ACTSLOT_PLAYER+act_gvel).w,d1
		bpl.s	loc_666C
		neg.w	d1

loc_666C:
		cmpi.w	#$800,d1
		bcc.s	loc_6696
		move.w	#$600,d1
		cmpi.w	#6,d0
		bgt.s	loc_66F6
		cmpi.w	#-6,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_6684:
		move.w	#$200,d1
		cmpi.w	#2,d0
		bgt.s	loc_66F6
		cmpi.w	#-2,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_6696:
		move.w	#$1000,d1
		cmpi.w	#$10,d0
		bgt.s	loc_66F6
		cmpi.w	#-$10,d0
		blt.s	loc_66C0
		bra.s	loc_66AE
; ===========================================================================

loc_66A8:
		moveq	#0,d0
		move.b	d0,(bound_ismoving).w

loc_66AE:
		moveq	#0,d1
		move.w	d0,d1
		add.w	(lvl_fgypos).w,d1
		tst.w	d0
		bpl.w	loc_6700
		bra.w	loc_66CC
; ===========================================================================

loc_66C0:
		neg.w	d1
		ext.l	d1
		asl.l	#8,d1
		add.l	(lvl_fgypos).w,d1
		swap	d1

loc_66CC:
		cmp.w	(bound_up).w,d1
		bgt.s	loc_6724
		cmpi.w	#-$100,d1
		bgt.s	loc_66F0
		andi.w	#$7FF,d1
		andi.w	#$7FF,(ACTSLOT_PLAYER+act_ypos).w
		andi.w	#$7FF,(lvl_fgypos).w
		andi.w	#$3FF,(lvl_bg1ypos).w
		bra.s	loc_6724
; ===========================================================================

loc_66F0:
		move.w	(bound_up).w,d1
		bra.s	loc_6724
; ===========================================================================

loc_66F6:
		ext.l	d1
		asl.l	#8,d1
		add.l	(lvl_fgypos).w,d1
		swap	d1

loc_6700:
		cmp.w	(bound_down).w,d1
		blt.s	loc_6724
		subi.w	#$800,d1
		bcs.s	loc_6720
		andi.w	#$7FF,(ACTSLOT_PLAYER+act_ypos).w
		subi.w	#$800,(lvl_fgypos).w
		andi.w	#$3FF,(lvl_bg1ypos).w
		bra.s	loc_6724
; ===========================================================================

loc_6720:
		move.w	(bound_down).w,d1

loc_6724:
		move.w	(lvl_fgypos).w,d4
		swap	d1
		move.l	d1,d3
		sub.l	(lvl_fgypos).w,d3
		ror.l	#8,d3
		move.w	d3,($FFFFF73C).w
		move.l	d1,(lvl_fgypos).w
		move.w	(lvl_fgypos).w,d0
		andi.w	#$10,d0
		move.b	($FFFFF74B).w,d1
		eor.b	d1,d0
		bne.s	locret_6766
		eori.b	#$10,($FFFFF74B).w
		move.w	(lvl_fgypos).w,d0
		sub.w	d4,d0
		bpl.s	loc_6760
		bset	#0,($FFFFF754).w
		rts	
; ===========================================================================

loc_6760:
		bset	#1,($FFFFF754).w

locret_6766:
		rts	
; End of function ScrollVertical


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock1:				; XREF: Deform_LZ, Deform_SBZ
		move.l	(lvl_bg1xpos).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(lvl_bg1xpos).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74C).w,d3
		eor.b	d3,d1
		bne.s	ScrollBlock1_2
		eori.b	#$10,($FFFFF74C).w
		sub.l	d2,d0
		bpl.s	ScrollBlock1_1
		bset	#2,(redraw_bg1flags).w
		bra.s	ScrollBlock1_2
; ===========================================================================

ScrollBlock1_1:				; XREF: ScrollBlock1
		bset	#3,(redraw_bg1flags).w

ScrollBlock1_2:				; XREF: ScrollBlock1, Deform_SBZ, ...
		move.l	(lvl_bg1ypos).w,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,(lvl_bg1ypos).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.s	ScrollBlock1_End
		eori.b	#$10,($FFFFF74D).w
		sub.l	d3,d0
		bpl.s	ScrollBlock1_3
		bset	#0,(redraw_bg1flags).w
		rts	
; ===========================================================================

ScrollBlock1_3:				; XREF: ScrollBlock1
		bset	#1,(redraw_bg1flags).w

ScrollBlock1_End:			; XREF: ScrollBlock1
		rts	
; End of function ScrollBlock1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock2:				; XREF: Deform_MZ, Deform_SYZ
		move.l	(lvl_bg1ypos).w,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,(lvl_bg1ypos).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.s	ScrollBlock2_End
		eori.b	#$10,($FFFFF74D).w
		sub.l	d3,d0
		bpl.s	ScrollBlock2_1
		bset	#4,(redraw_bg1flags).w
		rts	
; ===========================================================================

ScrollBlock2_1:				; XREF: ScrollBlock2
		bset	#5,(redraw_bg1flags).w

ScrollBlock2_End:			; XREF: ScrollBlock2
		rts	
; End of function ScrollBlock2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock3:				; XREF: Deform_MZ
		move.w	(lvl_bg1ypos).w,d3
		move.w	d0,(lvl_bg1ypos).w
		move.w	d0,d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.s	ScrollBlock3_End
		eori.b	#$10,($FFFFF74D).w
		sub.w	d3,d0
		bpl.s	ScrollBlock3_1
		bset	#0,(redraw_bg1flags).w
		rts	
; ===========================================================================

ScrollBlock3_1:				; XREF: ScrollBlock3
		bset	#1,(redraw_bg1flags).w

ScrollBlock3_End:			; XREF: ScrollBlock3
		rts	
; End of function ScrollBlock3


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock4:				; XREF: Deform_MZ, Deform_SBZ
		move.l	(lvl_bg1xpos).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(lvl_bg1xpos).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74C).w,d3
		eor.b	d3,d1
		bne.s	ScrollBlock4_End
		eori.b	#$10,($FFFFF74C).w
		sub.l	d2,d0
		bpl.s	ScrollBlock4_1
		bset	d6,(redraw_bg1flags).w
		bra.s	ScrollBlock4_End
; ===========================================================================

ScrollBlock4_1:				; XREF: ScrollBlock4
		addq.b	#1,d6
		bset	d6,(redraw_bg1flags).w

ScrollBlock4_End:			; XREF: ScrollBlock4
		rts	
; End of function ScrollBlock4


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock5:				; XREF: Deform_GHZ, Deform_MZ, ...
		move.l	(lvl_bg2xpos).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(lvl_bg2xpos).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74E).w,d3
		eor.b	d3,d1
		bne.s	ScrollBlock5_End
		eori.b	#$10,($FFFFF74E).w
		sub.l	d2,d0
		bpl.s	ScrollBlock5_1
		bset	d6,(redraw_bg2flags).w
		bra.s	ScrollBlock5_End
; ===========================================================================

ScrollBlock5_1:				; XREF: ScrollBlock5
		addq.b	#1,d6
		bset	d6,(redraw_bg2flags).w

ScrollBlock5_End:			; XREF: ScrollBlock5
		rts	
; End of function ScrollBlock5


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock6:				; XREF: Deform_GHZ, Deform_MZ, ...
		move.l	(lvl_bg3xpos).w,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,(lvl_bg3xpos).w
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	(redraw_dobg3x).w,d3
		eor.b	d3,d1
		bne.s	ScrollBlock6_End
		eori.b	#$10,(redraw_dobg3x).w
		sub.l	d2,d0
		bpl.s	ScrollBlock6_1
		bset	d6,(redraw_bg3flags).w
		bra.s	ScrollBlock6_End
; ===========================================================================

ScrollBlock6_1:				; XREF: ScrollBlock6
		addq.b	#1,d6
		bset	d6,(redraw_bg3flags).w

ScrollBlock6_End:			; XREF: ScrollBlock6
		rts	
; End of function ScrollBlock6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6886:		
		lea	(vdp_ctrl).l,a5
		lea	(vdp_data).l,a6
		lea	(redraw_bg1flags).w,a2
		lea	(lvl_bg1xpos).w,a3
		movea.l (lvl_bgaddr).w,a4    ; MJ: Load address of layout BG
		move.w	#$6000,d2
		bsr.w	sub_6D0A
		lea	(redraw_bg2flags).w,a2
		lea	(lvl_bg2xpos).w,a3
		bra.w	sub_6DA6
; End of function sub_6886

; ---------------------------------------------------------------------------
; Subroutine to	display	correct	tiles as you move
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesAsYouMove:			; XREF: Demo_Time
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	(redraw_bg1fcopy).w,a2
		lea	(redraw_bg1xpos).w,a3
		movea.l (lvl_bgaddr).w,a4    ; MJ: Load address of layout BG
		move.w	#$6000,d2
		bsr.w	sub_6D0A
		lea	(redraw_bg2fcopy).w,a2
		lea	(redraw_bg2xpos).w,a3
		bsr.w	sub_6DA6
		lea	(redraw_bg3fcopy).w,a2
		lea	(redraw_bg3xpos).w,a3
		bsr.w	sub_6EA4
		lea	(redraw_fgfcopy).w,a2
		lea	(redraw_fgxpos).w,a3
		movea.l (lvl_fgaddr).w,a4    ; MJ: Load address of layout
		move.w	#$4000,d2
		tst.b	($FFFFF745).w
		beq.s	Draw_FG
		move.b	#0,($FFFFF745).w	;Reset the redraw flag
		moveq	#-$10,d4			;Go to top line oflevel data relative camera position
		moveq	#$F,d6				;

Draw_All:
		movem.l	d4-d6,-(sp)			; This whole routine basically redraws the whole
		moveq	#-$10,d5			; area instead of merely a line of tiles
		move.w	d4,d1
		bsr.w	Calc_VRAM_Pos
		move.w	d1,d4
		moveq	#-$10,d5
		bsr.w	DrawTiles_LR
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,Draw_All
		rts	

Draw_FG:
		tst.b	(a2)
		beq.s	locret_6D08
		bclr	#0,(a2)
		beq.s	loc_6CBE
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	DrawTiles_LR

loc_6CBE:
		bclr	#1,(a2)
		beq.s	loc_6CD8
		move.w	#$E0,d4	; 'à'
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$E0,d4	; 'à'
		moveq	#-$10,d5
		bsr.w	DrawTiles_LR

loc_6CD8:
		bclr	#2,(a2)
		beq.s	loc_6CEE
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	DrawTiles_TB

loc_6CEE:
		bclr	#3,(a2)
		beq.s	locret_6D08
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	DrawTiles_TB

locret_6D08:
		rts	

; End of function LoadTilesAsYouMove


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6D0A:
		tst.b	(a2)
		beq.w	locret_6DA4
		bclr	#0,(a2)
		beq.s	loc_6D26
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	DrawTiles_LR

loc_6D26:
		bclr	#1,(a2)
		beq.s	loc_6D40
		move.w	#$E0,d4	; 'à'
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$E0,d4	; 'à'
		moveq	#-$10,d5
		bsr.w	DrawTiles_LR

loc_6D40:
		bclr	#2,(a2)
		beq.s	loc_6D56
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	DrawTiles_TB

loc_6D56:
		bclr	#3,(a2)
		beq.s	loc_6D70
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-$10,d4
		move.w	#$150,d5
		bsr.w	DrawTiles_TB

loc_6D70:
		bclr	#4,(a2)
		beq.s	loc_6D88
		moveq	#-$10,d4
		moveq	#0,d5
		bsr.w	loc_7176
		moveq	#-$10,d4
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	DrawTiles_LR3

loc_6D88:
		bclr	#5,(a2)
		beq.s	locret_6DA4
		move.w	#$E0,d4	; 'à'
		moveq	#0,d5
		bsr.w	loc_7176
		move.w	#$E0,d4	; 'à'
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	DrawTiles_LR3

locret_6DA4:
		rts	
; End of function sub_6D0A


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6DA6:
		tst.b	(a2)
		beq.w	locret_6DF2
		cmpi.b	#5,(lvl_id).w
		beq.w	loc_6E16
		bclr	#0,(a2)
		beq.s	loc_6DD2
		move.w	#$70,d4	; 'p'
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$70,d4	; 'p'
		moveq	#-$10,d5
		moveq	#2,d6
		bsr.w	DrawTiles_TB2

loc_6DD2:
		bclr	#1,(a2)
		beq.s	locret_6DF2
		move.w	#$70,d4	; 'p'
		move.w	#$150,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$70,d4	; 'p'
		move.w	#$150,d5
		moveq	#2,d6
		bsr.w	DrawTiles_TB2

locret_6DF2:
		rts	
; ===========================================================================
unk_6DF4:	dc.b   0 ;	 
unk_6DF5:	dc.b   0 ;	 
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   0 ;  
; ===========================================================================

loc_6E16:
		moveq	#-$10,d4
		bclr	#0,(a2)
		bne.s	loc_6E28
		bclr	#1,(a2)
		beq.s	loc_6E72
		move.w	#$E0,d4	; 'à'

loc_6E28:
		lea	(unk_6DF5).l,a0
		move.w	(lvl_bg1ypos).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		lea	(unk_6FE4).l,a3
		movea.w	(a3,d0.w),a3
		beq.s	loc_6E5E
		moveq	#-$10,d5
		movem.l	d4-d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4-d5
		bsr.w	DrawTiles_LR
		bra.s	loc_6E72
; ===========================================================================

loc_6E5E:
		moveq	#0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	loc_7176
		movem.l	(sp)+,d4-d5
		moveq	#$1F,d6
		bsr.w	DrawTiles_LR3

loc_6E72:
		tst.b	(a2)
		bne.s	loc_6E78
		rts	
; ===========================================================================

loc_6E78:
		moveq	#-$10,d4
		moveq	#-$10,d5
		move.b	(a2),d0
		andi.b	#-$58,d0
		beq.s	loc_6E8C
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#$150,d5

loc_6E8C:
		lea	(unk_6DF4).l,a0
		move.w	(lvl_bg1ypos).w,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	loc_6FEC
; End of function sub_6DA6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6EA4:
		tst.b	(a2)
		beq.w	locret_6EF0
		cmpi.b	#2,(lvl_id).w
		beq.w	loc_6F54
		bclr	#0,(a2)
		beq.s	loc_6ED0_2
		move.w	#$40,d4	; '@'
		moveq	#-$10,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4	; '@'
		moveq	#-$10,d5
		moveq	#2,d6
		bsr.w	DrawTiles_TB2

loc_6ED0_2:
		bclr	#1,(a2)
		beq.s	locret_6EF0
		move.w	#$40,d4	; '@'
		move.w	#$150,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4	; '@'
		move.w	#$150,d5
		moveq	#2,d6
		bsr.w	DrawTiles_TB2

locret_6EF0:
		rts	
; ===========================================================================
unk_6EF2:	dc.b   0 ;	 
unk_6EF3:	dc.b   0 ;	 
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   2 ;  
		dc.b   0 ;  
; ===========================================================================

loc_6F54:
		moveq	#-$10,d4
		bclr	#0,(a2)
		bne.s	loc_6F66
		bclr	#1,(a2)
		beq.s	loc_6FAE
		move.w	#$E0,d4	; 'à'

loc_6F66:
		lea	(unk_6EF3).l,a0
		move.w	(lvl_bg1ypos).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	unk_6FE4(pc,d0.w),a3
		beq.s	loc_6F9A
		moveq	#-$10,d5
		movem.l	d4-d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4-d5
		bsr.w	DrawTiles_LR
		bra.s	loc_6FAE
; ===========================================================================

loc_6F9A:
		moveq	#0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	loc_7176
		movem.l	(sp)+,d4-d5
		moveq	#$1F,d6
		bsr.w	DrawTiles_LR3

loc_6FAE:
		tst.b	(a2)
		bne.s	loc_6FB4
		rts	
; ===========================================================================

loc_6FB4:
		moveq	#-$10,d4
		moveq	#-$10,d5
		move.b	(a2),d0
		andi.b	#-$58,d0
		beq.s	loc_6FC8
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#$140,d5

loc_6FC8:
		lea	(unk_6EF2).l,a0
		move.w	(lvl_bg1ypos).w,d0
		subi.w	#$200,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	loc_6FEC
; ===========================================================================
unk_6FE4:	dc.b $FF ;  
		dc.b $18 ;  
		dc.b $FF ;  
		dc.b $18 ;  
		dc.b $FF ;  
		dc.b $20 ;  
		dc.b $FF ;  
		dc.b $28 ; (
; ===========================================================================

loc_6FEC:
		moveq	#$F,d6
		move.l	#$800000,d7

loc_6FF4:
		moveq	#0,d0
		move.b	(a0)+,d0
		btst	d0,(a2)
		beq.s	loc_701C
		movea.w	unk_6FE4(pc,d0.w),a3
		movem.l	d4-d5/a0,-(sp)
		movem.l	d4-d5,-(sp)
		bsr.w	sub_712A
		movem.l	(sp)+,d4-d5
		bsr.w	Calc_VRAM_Pos
		bsr.w	sub_70AC
		movem.l	(sp)+,d4-d5/a0

loc_701C:
		addi.w	#$10,d4
		dbf	d6,loc_6FF4
		clr.b	(a2)
		rts	
; End of function sub_6EA4


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DrawTiles_LR:
		moveq	#$16,d6
; End of function DrawTiles_LR


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DrawTiles_LR2:
		move.l	#$800000,d7
		move.l	d0,d1

loc_7032:
		movem.l	d4-d5,-(sp)
		bsr.w	sub_712A
		move.l	d1,d0
		bsr.w	sub_70AC
		addq.b	#4,d1
		andi.b	#$7F,d1	; '?'
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d5
		dbf	d6,loc_7032
		rts	
; End of function DrawTiles_LR2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DrawTiles_LR3:
		move.l	#$800000,d7
		move.l	d0,d1

loc_705C:
		movem.l	d4-d5,-(sp)
		bsr.w	loc_712C
		move.l	d1,d0
		bsr.w	sub_70AC
		addq.b	#4,d1
		andi.b	#$7F,d1	; '?'
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d5
		dbf	d6,loc_705C
		rts	
; End of function DrawTiles_LR3


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DrawTiles_TB:
		moveq	#$F,d6
; End of function DrawTiles_TB


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DrawTiles_TB2:
		move.l	#$800000,d7
		move.l	d0,d1

loc_7088:
		movem.l	d4-d5,-(sp)
		bsr.w	sub_712A
		move.l	d1,d0
		bsr.w	sub_70AC
		addi.w	#$100,d1
		andi.w	#$FFF,d1
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d4
		dbf	d6,loc_7088
		rts	
; End of function DrawTiles_TB2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_70AC:
		or.w	d2,d0
		swap	d0
		btst	#3,(a0)
		bne.s	loc_70E8
		btst	#2,(a0)
		bne.s	loc_70C8
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		rts	
; ===========================================================================

loc_70C8:
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)
		rts	
; ===========================================================================

loc_70E8:
		btst	#2,(a0)
		bne.s	loc_710A
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$10001000,d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		rts	
; ===========================================================================

loc_710A:
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$18001800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		rts	
; End of function sub_70AC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_712A:
		add.w	(a3),d5

loc_712C:
		add.w	4(a3),d4
		lea	(lvl_blocks).w,a1
		move.w	d4,d3
		andi.w	#$780,d3
		lsr.w	#3,d5
		move.w	d5,d0
		lsr.w	#4,d0
		andi.w	#$7F,d0	; '?'
		lsl.w	#1,d3 ; MJ: multiply by 2 (So it skips the BG)
		add.w	d3,d0
		moveq	#-1,d3
		move.b	(a4,d0.w),d3
		andi.w	#$FF,d3	; '?'
		ror.w	#7,d3
		ror.w	#2,d3   ; MJ: ..plus an extra 2 (so it's within 80 bytes, not 200)
		andi.w	#$70,d4    ; MJ: keep Y pos within 80 pixels
        andi.w	#$E,d5 ; MJ: keep X pos within 10
		add.w	d4,d3
		add.w	d5,d3
		movea.l	d3,a0
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1

locret_7172:
		rts	
; End of function sub_712A


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Calc_VRAM_Pos:
		add.w	(a3),d5

loc_7176:
		add.w	4(a3),d4
		andi.w	#$F0,d4	; 'ð'
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0
		swap	d0
		move.w	d4,d0
		rts	
; End of function Calc_VRAM_Pos

; ===========================================================================
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4	; 'ð'
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#2,d0
		swap	d0
		move.w	d4,d0
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesFromStart:
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	(lvl_fgxpos).w,a3
		movea.l	(lvl_fgaddr).w,a4    ; MJ: Load address of layout
		move.w	#$4000,d2
		bsr.s	LoadTilesFromStart2
		lea	(lvl_bg1xpos).w,a3
		movea.l	(lvl_bgaddr).w,a4    ; MJ: Load address of layout BG
		move.w	#$6000,d2
		tst.b	(lvl_id).w
		beq.w	loc_7220
		cmpi.b	#2,(lvl_id).w
		beq.w	loc_725A
		cmpi.w	#$500,(lvl_id).w
		beq.w	loc_7288
		cmpi.b	#6,(lvl_id).w
		beq.w	loc_7220
; End of function LoadTilesFromStart


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesFromStart2:
		moveq	#-$10,d4
		moveq	#$F,d6

loc_71FC:
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	Calc_VRAM_Pos
		move.w	d1,d4
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	DrawTiles_LR2
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_71FC
		rts	
; End of function LoadTilesFromStart2

; ===========================================================================

loc_7220:
		moveq	#0,d4
		moveq	#$F,d6

loc_7224:
		movem.l	d4-d6,-(sp)
		lea	(unk_724A).l,a0
		move.w	(lvl_bg1ypos).w,d0
		add.w	d4,d0
		andi.w	#$F0,d0	; 'ð'
		bsr.w	sub_72BA
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_7224
		rts	
; ===========================================================================
unk_724A:	dc.b   0 ;	 
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   6 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   4 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
		dc.b   0 ;  
; ===========================================================================

loc_725A:
		moveq	#-$10,d4
		moveq	#$F,d6

loc_725E:
		movem.l	d4-d6,-(sp)
		lea	(unk_6EF3).l,a0
		move.w	(lvl_bg1ypos).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		bsr.w	sub_72BA
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_725E
		rts	
; ===========================================================================

loc_7288:
		moveq	#-$10,d4
		moveq	#$F,d6

loc_728C:
		movem.l	d4-d6,-(sp)
		lea	(unk_6DF5).l,a0
		move.w	(lvl_bg1ypos).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		bsr.w	sub_72BA
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbf	d6,loc_728C
		rts	
; ===========================================================================
unk_72B2:	dc.b $F7 ; ÷
		dc.b   8 ;  
		dc.b $F7 ; ÷
		dc.b   8 ;  
		dc.b $F7 ; ÷
		dc.b $10 ;  
		dc.b $F7 ; ÷
		dc.b $18 ;  

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72BA:
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	unk_72B2(pc,d0.w),a3
		beq.s	loc_72DA
		moveq	#-$10,d5
		movem.l	d4-d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4-d5
		bsr.w	DrawTiles_LR
		bra.s	locret_72EE
; ===========================================================================

loc_72DA:
		moveq	#0,d5
		movem.l	d4-d5,-(sp)
		bsr.w	loc_7176
		movem.l	(sp)+,d4-d5
		moveq	#$1F,d6
		bsr.w	DrawTiles_LR3

locret_72EE:
		rts	
; End of function sub_72BA

; ---------------------------------------------------------------------------
; Main Load Block loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MainLoadBlockLoad:			; XREF: Level; EndingSequence
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		move.l	a2,-(sp)
		addq.l	#4,a2
		movea.l	(a2)+,a0
		lea	(lvl_blocks).w,a1 ; RAM address for 16x16 mappings
		move.w	#0,d0
		jsr	Decomp_Eni
		movea.l	(a2)+,a0
		lea	(lvl_chunks).l,a1	; RAM address for 256x256 mappings
		jsr	KosDec
		bsr.w	LevelLayoutLoad
		move.w	(a2)+,d0
		move.w	(a2),d0
		andi.w	#$FF,d0
		cmpi.w	#$103,(lvl_id).w ; is level SBZ3 (LZ4) ?
		bne.s	MLB_ChkSBZPal	; if not, branch
		moveq	#$C,d0		; use SB3 pallet

MLB_ChkSBZPal:
		cmpi.w	#$501,(lvl_id).w ; is level SBZ2?
		beq.s	MLB_UsePal0E	; if yes, branch
		cmpi.w	#$502,(lvl_id).w ; is level FZ?
		bne.s	MLB_NormalPal	; if not, branch

MLB_UsePal0E:
		moveq	#$E,d0		; use SBZ2/FZ pallet

MLB_NormalPal:
		bsr.w	Pal_LoadTarget	; load pallet (based on	d0)
		movea.l	(sp)+,a2
		addq.w	#4,a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	locret_6D10
		jsr	LoadPLC		; load pattern load cues

locret_6D10:
		rts	
; End of function MainLoadBlockLoad

; ---------------------------------------------------------------------------
; Level	layout loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; This method now releases free ram space from A408 - A7FF

LevelLayoutLoad:
		move.w	(lvl_id).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(Level_Index).l,a1
		movea.l	(a1,d0.w),a1				; MJ: moving the address strait to a1 rather than adding a word to an address
		move.l	a1,(lvl_fgaddr).w			; MJ: save location of layout to lvl_fgaddr
		adda.w	#$0080,a1				; MJ: add 80 (As the BG line is always after the FG line)
		move.l	a1,(lvl_bgaddr).w			; MJ: save location of layout to lvl_bgaddr
		rts						; MJ: Return

; End of function LevelLayoutLoad2

; ---------------------------------------------------------------------------
; Dynamic screen resize	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DynScrResizeLoad:			; XREF: DeformBgLayer
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		add.w	d0,d0
		move.w	Resize_Index(pc,d0.w),d0
		jsr	Resize_Index(pc,d0.w)
		moveq	#2,d1
		move.w	(bound_dtarget).w,d0
		sub.w	(bound_down).w,d0
		beq.s	locret_6DAA
		bcc.s	loc_6DAC
		neg.w	d1
		move.w	(lvl_fgypos).w,d0
		cmp.w	(bound_dtarget).w,d0
		bls.s	loc_6DA0
		move.w	d0,(bound_down).w
		andi.w	#-2,(bound_down).w

loc_6DA0:
		add.w	d1,(bound_down).w
		move.b	#1,(bound_ismoving).w

locret_6DAA:
		rts	
; ===========================================================================

loc_6DAC:				; XREF: DynScrResizeLoad
		move.w	(lvl_fgypos).w,d0
		addq.w	#8,d0
		cmp.w	(bound_down).w,d0
		bcs.s	loc_6DC4
		btst	#1,(ACTSLOT_PLAYER+act_status).w
		beq.s	loc_6DC4
		add.w	d1,d1
		add.w	d1,d1

loc_6DC4:
		add.w	d1,(bound_down).w
		move.b	#1,(bound_ismoving).w
		rts	
; End of function DynScrResizeLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for dynamic screen resizing
; ---------------------------------------------------------------------------
Resize_Index:	dc.w Resize_GHZ-Resize_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Green	Hill Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_GHZ:				; XREF: Resize_Index
		rts

; ---------------------------------------------------------------------------
; Platform subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PlatformObject:
		lea	(ACTSLOT_PLAYER).w,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_751E

Platform2:
		move.w	$C(a0),d0
		subq.w	#8,d0

Platform3:
		move.w	$C(a1),d2
		move.b	$16(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	locret_751E
		cmpi.w	#-$10,d0
		bcs.w	locret_751E
		tst.b	(plyr_ignore).w
		bmi.w	locret_751E
		cmpi.b	#6,$24(a1)
		bcc.w	locret_751E
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,$C(a1)
		addq.b	#2,$24(a0)

loc_74AE:
		btst	#3,$22(a1)
		beq.s	loc_74DC
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		bclr	#3,$22(a2)
		clr.b	$25(a2)
		cmpi.b	#4,$24(a2)
		bne.s	loc_74DC
		subq.b	#2,$24(a2)

loc_74DC:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,$3D(a1)
		move.b	#0,$26(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),$14(a1)
		btst	#1,$22(a1)
		beq.s	loc_7512
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	Sonic_ResetOnFloor
		movea.l	(sp)+,a0

loc_7512:
		bset	#3,$22(a1)
		bset	#3,$22(a0)

locret_751E:
		rts	
; End of function PlatformObject

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	SLZ seesaws)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject:				; XREF: Obj1A_Slope; Obj5E_Slope
		lea	(ACTSLOT_PLAYER).w,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.s	locret_751E
		btst	#0,1(a0)
		beq.s	loc_754A
		not.w	d0
		add.w	d1,d0

loc_754A:
		lsr.w	#1,d0
		moveq	#0,d3
		move.b	(a2,d0.w),d3
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function SlopeObject

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk or jump off	a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExitPlatform:
		move.w	d1,d2

ExitPlatform2:
		add.w	d2,d2
		lea	(ACTSLOT_PLAYER).w,a1
		btst	#1,$22(a1)
		bne.s	loc_75E0
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_75E0
		cmp.w	d2,d0
		bcs.s	locret_75F2

loc_75E0:
		bclr	#3,$22(a1)
		move.b	#2,$24(a0)
		bclr	#3,$22(a0)

locret_75F2:
		rts	
; End of function ExitPlatform

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm:
		lea	(ACTSLOT_PLAYER).w,a1
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.s	MvSonic2
; End of function MvSonicOnPtfm

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm2:
		lea	(ACTSLOT_PLAYER).w,a1
		move.w	$C(a0),d0
		subi.w	#9,d0

MvSonic2:
		tst.b	(plyr_ignore).w
		bmi.s	locret_7B62
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.s	locret_7B62
		tst.w	($FFFFFE08).w
		bne.s	locret_7B62
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_7B62:
		rts	
; End of function MvSonicOnPtfm2

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	MZ platforms)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject2:				; XREF: Obj1A_WalkOff; et al
		lea	(ACTSLOT_PLAYER).w,a1
		btst	#3,$22(a1)
		beq.s	locret_856E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,1(a0)
		beq.s	loc_854E
		not.w	d0
		add.w	d1,d0

loc_854E:
		moveq	#0,d1
		move.b	(a2,d0.w),d1
		move.w	$C(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_856E:
		rts	
; End of function SlopeObject2

; ===========================================================================

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj44_SolidWall:			; XREF: Obj44_Solid
		bsr.w	Obj44_SolidWall2
		beq.s	loc_8AA8
		bmi.w	loc_8AC4
		tst.w	d0
		beq.w	loc_8A92
		bmi.s	loc_8A7C
		tst.w	$10(a1)
		bmi.s	loc_8A92
		bra.s	loc_8A82
; ===========================================================================

loc_8A7C:
		tst.w	$10(a1)
		bpl.s	loc_8A92

loc_8A82:
		sub.w	d0,8(a1)
		move.w	#0,$14(a1)
		move.w	#0,$10(a1)

loc_8A92:
		btst	#1,$22(a1)
		bne.s	loc_8AB6
		bset	#5,$22(a1)
		bset	#5,$22(a0)
		rts	
; ===========================================================================

loc_8AA8:
		btst	#5,$22(a0)
		beq.s	locret_8AC2
		move.w	#1,$1C(a1)

loc_8AB6:
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)

locret_8AC2:
		rts	
; ===========================================================================

loc_8AC4:
		tst.w	$12(a1)
		bpl.s	locret_8AD8
		tst.w	d3
		bpl.s	locret_8AD8
		sub.w	d3,$C(a1)
		move.w	#0,$12(a1)

locret_8AD8:
		rts	
; End of function Obj44_SolidWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj44_SolidWall2:			; XREF: Obj44_SolidWall
		lea	(ACTSLOT_PLAYER).w,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_8B48
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_8B48
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		add.w	d2,d3
		bmi.s	loc_8B48
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.s	loc_8B48
		tst.b	(plyr_ignore).w
		bmi.s	loc_8B48
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.s	loc_8B48
		tst.w	($FFFFFE08).w
		bne.s	loc_8B48
		move.w	d0,d5
		cmp.w	d0,d1
		bcc.s	loc_8B30
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_8B30:
		move.w	d3,d1
		cmp.w	d3,d2
		bcc.s	loc_8B3C
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_8B3C:
		cmp.w	d1,d5
		bhi.s	loc_8B44
		moveq	#1,d4
		rts	
; ===========================================================================

loc_8B44:
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_8B48:
		moveq	#0,d4
		rts	
; End of function Obj44_SolidWall2
; ---------------------------------------------------------------------------
; Object 27 - explosion	from a destroyed enemy
; ---------------------------------------------------------------------------

Obj27:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj27_Index(pc,d0.w),d1
		jmp	Obj27_Index(pc,d1.w)
; ===========================================================================
Obj27_Index:	dc.w Obj27_LoadAnimal-Obj27_Index
		dc.w Obj27_Main-Obj27_Index
		dc.w Obj27_Animate-Obj27_Index
; ===========================================================================

Obj27_LoadAnimal:			; XREF: Obj27_Index
		addq.b	#2,$24(a0)
		bsr.w	SingleObjLoad
		bne.s	Obj27_Main
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),$3E(a1)

Obj27_Main:				; XREF: Obj27_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj27,4(a0)
		move.w	#$5A0,2(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,$20(a0)
		move.b	#$C,$19(a0)
		move.b	#7,$1E(a0)	; set frame duration to	7 frames
		move.b	#0,$1A(a0)
		move.w	#$C1,d0
		jsr	(Sound_CueSFX).l ;	play breaking enemy sound

Obj27_Animate:				; XREF: Obj27_Index
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	Obj27_Display
		move.b	#7,$1E(a0)	; set frame duration to	7 frames
		addq.b	#1,$1A(a0)	; next frame
		cmpi.b	#5,$1A(a0)	; is the final frame (05) displayed?
		beq.w	DeleteObject	; if yes, branch

Obj27_Display:
		bra.w	Actor_Display
; ===========================================================================

; ---------------------------------------------------------------------------
; Sprite mappings - explosion
; ---------------------------------------------------------------------------
Map_obj27:	dc.w byte_8ED0-Map_obj27, byte_8ED6-Map_obj27
		dc.w byte_8EDC-Map_obj27, byte_8EE2-Map_obj27
		dc.w byte_8EF7-Map_obj27
byte_8ED0:	dc.b 1
		dc.b $F8, 9, 0,	0, $F4
byte_8ED6:	dc.b 1
		dc.b $F0, $F, 0, 6, $F0
byte_8EDC:	dc.b 1
		dc.b $F0, $F, 0, $16, $F0
byte_8EE2:	dc.b 4
		dc.b $EC, $A, 0, $26, $EC
		dc.b $EC, 5, 0,	$2F, 4
		dc.b 4,	5, $18,	$2F, $EC
		dc.b $FC, $A, $18, $26,	$FC
byte_8EF7:	dc.b 4
		dc.b $EC, $A, 0, $33, $EC
		dc.b $EC, 5, 0,	$3C, 4
		dc.b 4,	5, $18,	$3C, $EC
		dc.b $FC, $A, $18, $33,	$FC
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 28 - animals
; ---------------------------------------------------------------------------

Obj28:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj28_Index(pc,d0.w),d1
		jmp	Obj28_Index(pc,d1.w)
; ===========================================================================
Obj28_Index:	dc.w Obj28_Ending-Obj28_Index, loc_912A-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_91C0-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_9184-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_91C0-Obj28_Index
		dc.w loc_9184-Obj28_Index, loc_9240-Obj28_Index
		dc.w loc_9260-Obj28_Index, loc_9260-Obj28_Index
		dc.w loc_9280-Obj28_Index, loc_92BA-Obj28_Index
		dc.w loc_9314-Obj28_Index, loc_9332-Obj28_Index
		dc.w loc_9314-Obj28_Index, loc_9332-Obj28_Index
		dc.w loc_9314-Obj28_Index, loc_9370-Obj28_Index
		dc.w loc_92D6-Obj28_Index

Obj28_VarIndex:	dc.b 0,	5, 2, 3, 6, 3, 4, 5, 4,	1, 0, 1

Obj28_Variables:dc.w $FE00, $FC00
		dc.l Map_obj28
		dc.w $FE00, $FD00	; horizontal speed, vertical speed
		dc.l Map_obj28a		; mappings address
		dc.w $FE80, $FD00
		dc.l Map_obj28
		dc.w $FEC0, $FE80
		dc.l Map_obj28a
		dc.w $FE40, $FD00
		dc.l Map_obj28b
		dc.w $FD00, $FC00
		dc.l Map_obj28a
		dc.w $FD80, $FC80
		dc.l Map_obj28b

Obj28_EndSpeed:	dc.w $FBC0, $FC00, $FBC0, $FC00, $FBC0,	$FC00, $FD00, $FC00
		dc.w $FD00, $FC00, $FE80, $FD00, $FE80,	$FD00, $FEC0, $FE80
		dc.w $FE40, $FD00, $FE00, $FD00, $FD80,	$FC80

Obj28_EndMap:	dc.l Map_obj28a, Map_obj28a, Map_obj28a, Map_obj28, Map_obj28
		dc.l Map_obj28,	Map_obj28, Map_obj28a, Map_obj28b, Map_obj28a
		dc.l Map_obj28b

Obj28_EndVram:	dc.w $5A5, $5A5, $5A5, $553, $553, $573, $573, $585, $593
		dc.w $565, $5B3
; ===========================================================================

Obj28_Ending:				; XREF: Obj28_Index
		tst.b	$28(a0)		; did animal come from a destroyed enemy?
		beq.w	Obj28_FromEnemy	; if yes, branch
		moveq	#0,d0
		move.b	$28(a0),d0	; move object type to d0
		add.w	d0,d0		; multiply d0 by 2
		move.b	d0,$24(a0)	; move d0 to routine counter
		subi.w	#$14,d0
		move.w	Obj28_EndVram(pc,d0.w),2(a0)
		add.w	d0,d0
		move.l	Obj28_EndMap(pc,d0.w),4(a0)
		lea	Obj28_EndSpeed(pc),a1
		move.w	(a1,d0.w),$32(a0) ; load horizontal speed
		move.w	(a1,d0.w),$10(a0)
		move.w	2(a1,d0.w),$34(a0) ; load vertical speed
		move.w	2(a1,d0.w),$12(a0)
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.b	#6,$18(a0)
		move.b	#8,$19(a0)
		move.b	#7,$1E(a0)
		bra.w	Actor_Display
; ===========================================================================

Obj28_FromEnemy:			; XREF: Obj28_Ending
		addq.b	#2,$24(a0)
		jsr	RandomNumber
		andi.w	#1,d0
		moveq	#0,d1
		move.b	(lvl_id).w,d1
		add.w	d1,d1
		add.w	d0,d1
		lea	Obj28_VarIndex(pc),a1
		move.b	(a1,d1.w),d0
		move.b	d0,$30(a0)
		lsl.w	#3,d0
		lea	Obj28_Variables(pc),a1
		adda.w	d0,a1
		move.w	(a1)+,$32(a0)	; load horizontal speed
		move.w	(a1)+,$34(a0)	; load vertical	speed
		move.l	(a1)+,4(a0)	; load mappings
		move.w	#$580,2(a0)	; VRAM setting for 1st animal
		btst	#0,$30(a0)	; is 1st animal	used?
		beq.s	loc_90C0	; if yes, branch
		move.w	#$592,2(a0)	; VRAM setting for 2nd animal

loc_90C0:
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.b	#6,$18(a0)
		move.b	#8,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#2,$1A(a0)
		move.w	#-$400,$12(a0)
		tst.b	($FFFFF7A7).w
		bne.s	loc_911C
		bsr.w	SingleObjLoad
		bne.s	Obj28_Display
		move.b	#$29,0(a1)	; load points object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),d0
		lsr.w	#1,d0
		move.b	d0,$1A(a1)

Obj28_Display:
		bra.w	Actor_Display
; ===========================================================================

loc_911C:
		move.b	#$12,$24(a0)
		clr.w	$10(a0)
		bra.w	Actor_Display
; ===========================================================================

loc_912A:				; XREF: Obj28_Index
		tst.b	1(a0)
		bpl.w	DeleteObject
		bsr.w	ObjectFall
		tst.w	$12(a0)
		bmi.s	loc_9180
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_9180
		add.w	d1,$C(a0)
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#1,$1A(a0)
		move.b	$30(a0),d0
		add.b	d0,d0
		addq.b	#4,d0
		move.b	d0,$24(a0)
		tst.b	($FFFFF7A7).w
		beq.s	loc_9180
		btst	#4,($FFFFFE0F).w
		beq.s	loc_9180
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9180:
		bra.w	Actor_Display
; ===========================================================================

loc_9184:				; XREF: Obj28_Index
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_91AE
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_91AE
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_91AE:
		tst.b	$28(a0)
		bne.s	loc_9224
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	Actor_Display
; ===========================================================================

loc_91C0:				; XREF: Obj28_Index
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.s	loc_91FC
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_91FC
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)
		tst.b	$28(a0)
		beq.s	loc_91FC
		cmpi.b	#$A,$28(a0)
		beq.s	loc_91FC
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_91FC:
		subq.b	#1,$1E(a0)
		bpl.s	loc_9212
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_9212:
		tst.b	$28(a0)
		bne.s	loc_9224
		tst.b	1(a0)
		bpl.w	DeleteObject
		bra.w	Actor_Display
; ===========================================================================

loc_9224:				; XREF: Obj28_Index
		move.w	8(a0),d0
		sub.w	(ACTSLOT_PLAYER+act_xpos).w,d0
		bcs.s	loc_923C
		subi.w	#$180,d0
		bpl.s	loc_923C
		tst.b	1(a0)
		bpl.w	DeleteObject

loc_923C:
		bra.w	Actor_Display
; ===========================================================================

loc_9240:				; XREF: Obj28_Index
		tst.b	1(a0)
		bpl.w	DeleteObject
		subq.w	#1,$36(a0)
		bne.w	loc_925C
		move.b	#2,$24(a0)
		move.b	#3,$18(a0)

loc_925C:
		bra.w	Actor_Display
; ===========================================================================

loc_9260:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bcc.s	loc_927C
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#$E,$24(a0)
		bra.w	loc_91C0
; ===========================================================================

loc_927C:
		bra.w	loc_9224
; ===========================================================================

loc_9280:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_92B6
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		bsr.w	loc_93C4
		bsr.w	loc_93EC
		subq.b	#1,$1E(a0)
		bpl.s	loc_92B6
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_92B6:
		bra.w	loc_9224
; ===========================================================================

loc_92BA:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_9310
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#4,$24(a0)
		bra.w	loc_9184
; ===========================================================================

loc_92D6:				; XREF: Obj28_Index
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_9310
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_9310
		not.b	$29(a0)
		bne.s	loc_9306
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9306:
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9310:
		bra.w	loc_9224
; ===========================================================================

loc_9314:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_932E
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	ObjectFall
		bsr.w	loc_93C4
		bsr.w	loc_93EC

loc_932E:
		bra.w	loc_9224
; ===========================================================================

loc_9332:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_936C
		bsr.w	ObjectFall
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	loc_936C
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_936C
		neg.w	$10(a0)
		bchg	#0,1(a0)
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_936C:
		bra.w	loc_9224
; ===========================================================================

loc_9370:				; XREF: Obj28_Index
		bsr.w	sub_9404
		bpl.s	loc_93C0
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.s	loc_93AA
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	loc_93AA
		not.b	$29(a0)
		bne.s	loc_93A0
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_93A0:
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_93AA:
		subq.b	#1,$1E(a0)
		bpl.s	loc_93C0
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_93C0:
		bra.w	loc_9224
; ===========================================================================

loc_93C4:
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.s	locret_93EA
		move.b	#0,$1A(a0)
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	locret_93EA
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

locret_93EA:
		rts	
; ===========================================================================

loc_93EC:
		bset	#0,1(a0)
		move.w	8(a0),d0
		sub.w	(ACTSLOT_PLAYER+act_xpos).w,d0
		bcc.s	locret_9402
		bclr	#0,1(a0)

locret_9402:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_9404:
		move.w	(ACTSLOT_PLAYER+act_xpos).w,d0
		sub.w	8(a0),d0
		subi.w	#$B8,d0
		rts	
; End of function sub_9404

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - animals
; ---------------------------------------------------------------------------
Map_obj28:
	include "_maps\obj28.asm"

Map_obj28a:
	include "_maps\obj28a.asm"

Map_obj28b:
	include "_maps\obj28b.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 25 - rings
; ---------------------------------------------------------------------------

Obj25:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj25_Index(pc,d0.w),d1
		jmp	Obj25_Index(pc,d1.w)
; ===========================================================================
Obj25_Index:	dc.w Obj25_Main-Obj25_Index
		dc.w Obj25_Animate-Obj25_Index
		dc.w Obj25_Collect-Obj25_Index
		dc.w Obj25_Sparkle-Obj25_Index
		dc.w Obj25_Delete-Obj25_Index
; ---------------------------------------------------------------------------
; Distances between rings (format: horizontal, vertical)
; ---------------------------------------------------------------------------
Obj25_PosData:	dc.b $10, 0		; horizontal tight
		dc.b $18, 0		; horizontal normal
		dc.b $20, 0		; horizontal wide
		dc.b 0,	$10		; vertical tight
		dc.b 0,	$18		; vertical normal
		dc.b 0,	$20		; vertical wide
		dc.b $10, $10		; diagonal
		dc.b $18, $18
		dc.b $20, $20
		dc.b $F0, $10
		dc.b $E8, $18
		dc.b $E0, $20
		dc.b $10, 8
		dc.b $18, $10
		dc.b $F0, 8
		dc.b $E8, $10
; ===========================================================================

Obj25_Main:				; XREF: Obj25_Index
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		lea	2(a2,d0.w),a2
		move.b	(a2),d4
		move.b	$28(a0),d1
		move.b	d1,d0
		andi.w	#7,d1
		cmpi.w	#7,d1
		bne.s	loc_9B80
		moveq	#6,d1

loc_9B80:
		swap	d1
		move.w	#0,d1
		lsr.b	#4,d0
		add.w	d0,d0
		move.b	Obj25_PosData(pc,d0.w),d5 ; load ring spacing data
		ext.w	d5
		move.b	Obj25_PosData+1(pc,d0.w),d6
		ext.w	d6
		movea.l	a0,a1
		move.w	8(a0),d2
		move.w	$C(a0),d3
		lsr.b	#1,d4
		bcs.s	loc_9C02
		bclr	#7,(a2)
		bra.s	loc_9BBA
; ===========================================================================

Obj25_MakeRings:
		swap	d1
		lsr.b	#1,d4
		bcs.s	loc_9C02
		bclr	#7,(a2)
		bsr.w	SingleObjLoad
		bne.s	loc_9C0E

loc_9BBA:				; XREF: Obj25_Main
		move.b	#$25,0(a1)	; load ring object
		addq.b	#2,$24(a1)
		move.w	d2,8(a1)	; set x-axis position based on d2
		move.w	8(a0),$32(a1)
		move.w	d3,$C(a1)	; set y-axis position based on d3
		move.l	#Map_obj25,4(a1)
		move.w	#$27B2,2(a1)
		move.b	#4,1(a1)
		move.b	#2,$18(a1)
		move.b	#$47,$20(a1)
		move.b	#8,$19(a1)
		move.b	$23(a0),$23(a1)
		move.b	d1,$34(a1)

loc_9C02:
		addq.w	#1,d1
		add.w	d5,d2		; add ring spacing value to d2
		add.w	d6,d3		; add ring spacing value to d3
		swap	d1
		dbf	d1,Obj25_MakeRings ; repeat for	number of rings

loc_9C0E:
		btst	#0,(a2)
		bne.w	DeleteObject

Obj25_Animate:				; XREF: Obj25_Index
		move.b	(ani_ringframe).w,$1A(a0) ;	set frame
		bsr.w	Actor_Display
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	Obj25_Delete
		rts	
; ===========================================================================

Obj25_Collect:				; XREF: Obj25_Index
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		move.b	#1,$18(a0)
		bsr.w	CollectRing
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		move.b	$34(a0),d1
		bset	d1,2(a2,d0.w)

Obj25_Sparkle:				; XREF: Obj25_Index
		lea	(Ani_obj25).l,a1
		bsr.w	Actor_Animate
		bra.w	Actor_Display
; ===========================================================================

Obj25_Delete:				; XREF: Obj25_Index
		bra.w	DeleteObject

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


CollectRing:				; XREF: Obj25_Collect
		addq.w	#1,(plyr_rings).w ; add 1 to rings
		ori.b	#1,($FFFFFE1D).w ; update the rings counter
		move.w	#$B5,d0		; play ring sound
		cmpi.w	#100,(plyr_rings).w ; do	you have < 100 rings?
		bcs.s	Obj25_PlaySnd	; if yes, branch
		bset	#1,($FFFFFE1B).w ; update lives	counter
		beq.s	loc_9CA4
		cmpi.w	#200,(plyr_rings).w ; do	you have < 200 rings?
		bcs.s	Obj25_PlaySnd	; if yes, branch
		bset	#2,($FFFFFE1B).w ; update lives	counter
		bne.s	Obj25_PlaySnd

loc_9CA4:
		addq.b	#1,($FFFFFE12).w ; add 1 to the	number of lives	you have
		addq.b	#1,($FFFFFE1C).w ; add 1 to the	lives counter
		move.w	#$88,d0		; play extra life music

Obj25_PlaySnd:
		jmp	(Sound_CueSFX).l
; End of function CollectRing

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 37 - rings flying out of Sonic	when he's hit
; ---------------------------------------------------------------------------

Obj37:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj37_Index(pc,d0.w),d1
		jmp	Obj37_Index(pc,d1.w)
; ===========================================================================
Obj37_Index:	dc.w Obj37_CountRings-Obj37_Index
		dc.w Obj37_Bounce-Obj37_Index
		dc.w Obj37_Collect-Obj37_Index
		dc.w Obj37_Sparkle-Obj37_Index
		dc.w Obj37_Delete-Obj37_Index
; ===========================================================================

Obj37_CountRings:			; XREF: Obj37_Index
		movea.l	a0,a1
		moveq	#0,d5
		move.w	(plyr_rings).w,d5 ; check number	of rings you have
		moveq	#32,d0
		cmp.w	d0,d5		; do you have 32 or more?
		bcs.s	loc_9CDE	; if not, branch
		move.w	d0,d5		; if yes, set d5 to 32

loc_9CDE:
		subq.w	#1,d5
		move.w	#$288,d4
		bra.s	Obj37_MakeRings
; ===========================================================================

Obj37_Loop:
		bsr.w	SingleObjLoad
		bne.w	Obj37_ResetCounter

Obj37_MakeRings:			; XREF: Obj37_CountRings
		move.b	#$37,0(a1)	; load bouncing	ring object
		addq.b	#2,$24(a1)
		move.b	#8,$16(a1)
		move.b	#8,$17(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_obj25,4(a1)
		move.w	#$27B2,2(a1)
		move.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#$47,$20(a1)
		move.b	#8,$19(a1)
		tst.w	d4
		bmi.s	loc_9D62
		move.w	d4,d0
		jsr	Math_GetSine
		move.w	d4,d2
		lsr.w	#8,d2
		asl.w	d2,d0
		asl.w	d2,d1
		move.w	d0,d2
		move.w	d1,d3
		addi.b	#$10,d4
		bcc.s	loc_9D62
		subi.w	#$80,d4
		bcc.s	loc_9D62
		move.w	#$288,d4

loc_9D62:
		move.w	d2,$10(a1)
		move.w	d3,$12(a1)
		neg.w	d2
		neg.w	d4
		dbf	d5,Obj37_Loop	; repeat for number of rings (max 31)

Obj37_ResetCounter:			; XREF: Obj37_Loop
		move.w	#0,(plyr_rings).w ; reset number	of rings to zero
		move.b	#$80,($FFFFFE1D).w ; update ring counter
		move.b	#0,($FFFFFE1B).w
		moveq	#-1,d0			; Move #-1 to d0
		move.b	d0,$1F(a0)	; Move d0 to new timer
		move.b	d0,(ani_drprngtime).w	; Move d0 to old timer (for animated purposes)
		move.w	#$C6,d0
		jsr	(Sound_CueSFX).l ;	play ring loss sound

Obj37_Bounce:				; XREF: Obj37_Index
		move.b	(ani_drprngframe).w,$1A(a0)
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)
		bmi.s	Obj37_ChkDel
		move.b	($FFFFFE0F).w,d0
		add.b	d7,d0
		andi.b	#3,d0
		bne.s	Obj37_ChkDel
		jsr	ObjHitFloor
		tst.w	d1
		bpl.s	Obj37_ChkDel
		add.w	d1,$C(a0)
		move.w	$12(a0),d0
		asr.w	#2,d0
		sub.w	d0,$12(a0)
		neg.w	$12(a0)

Obj37_ChkDel:
		subq.b  #1,$1F(a0)  ; Subtract 1   ; RHS Ring Timer fix
                beq.w   DeleteObject       ; If 0, delete ; RHS Ring Timer fix
		cmpi.w	#$FF00,(bound_up).w		; is vertical wrapping enabled?
		beq.s	@IgnoreYBound			; if so, branch
		move.w	(bound_down).w,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	   ; has object moved below level boundary?
		bcs.s	Obj37_Delete	   ; if yes, branch	
@IgnoreYBound:
		btst	#0, $1F(a0) ; Test the first bit of the timer, so rings flash every other frame.
		beq.w	Actor_Display      ; If the bit is 0, the ring will appear.
		cmpi.b	#80,$1F(a0) ; Rings will flash during last 80 steps of their life.
		bhi.w	Actor_Display      ; If the timer is higher than 80, obviously the rings will STAY visible.
		rts
; ===========================================================================

Obj37_Collect:				; XREF: Obj37_Index
		addq.b	#2,$24(a0)
		move.b	#0,$20(a0)
		move.b	#1,$18(a0)
		bsr.w	CollectRing

Obj37_Sparkle:				; XREF: Obj37_Index
		lea	(Ani_obj25).l,a1
		bsr.w	Actor_Animate
		bra.w	Actor_Display
; ===========================================================================

Obj37_Delete:				; XREF: Obj37_Index
		bra.w	DeleteObject
; ===========================================================================

Ani_obj25:
	include "_anim\obj25.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - rings
; ---------------------------------------------------------------------------
Map_obj25:
	include "_maps\obj25.asm"

; ===========================================================================
		include	"Action Stage/Global/Actors/Item Box/Script.asm"
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2E - contents of monitors
; ---------------------------------------------------------------------------

Obj2E:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj2E_Index(pc,d0.w),d1
		jsr	Obj2E_Index(pc,d1.w)
		bra.w	Actor_Display
; ===========================================================================
Obj2E_Index:	dc.w Obj2E_Main-Obj2E_Index
		dc.w Obj2E_Move-Obj2E_Index
		dc.w Obj2E_Delete-Obj2E_Index
; ===========================================================================

Obj2E_Main:				; XREF: Obj2E_Index
		addq.b	#2,$24(a0)
		move.w	#$680,2(a0)
		move.b	#$24,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		move.w	#-$300,$12(a0)
		moveq	#0,d0
		move.b	$1C(a0),d0
		addq.b	#2,d0
		move.b	d0,$1A(a0)
		movea.l	#ItemBox_Maps,a1
		add.b	d0,d0
		adda.w	(a1,d0.w),a1
		addq.w	#1,a1
		move.l	a1,4(a0)

Obj2E_Move:				; XREF: Obj2E_Index
		tst.w	$12(a0)		; is object moving?
		bpl.w	Obj2E_ChkEggman	; if not, branch
		bsr.w	SpeedToPos
		addi.w	#$18,$12(a0)	; reduce object	speed
		rts	
; ===========================================================================

Obj2E_ChkEggman:			; XREF: Obj2E_Move
		addq.b	#2,$24(a0)
		move.w	#29,$1E(a0)
		move.b	$1C(a0),d0
		cmpi.b	#1,d0		; does monitor contain Eggman?
		bne.s	Obj2E_ChkSonic
		rts			; Eggman monitor does nothing
; ===========================================================================

Obj2E_ChkSonic:
		cmpi.b	#2,d0		; does monitor contain Sonic?
		bne.s	Obj2E_ChkShoes

ExtraLife:
		addq.b	#1,($FFFFFE12).w ; add 1 to the	number of lives	you have
		addq.b	#1,($FFFFFE1C).w ; add 1 to the	lives counter
		move.w	#$88,d0
		jmp	(Sound_CueMusic).l	; play extra life music
; ===========================================================================

Obj2E_ChkShoes:
		cmpi.b	#3,d0		; does monitor contain speed shoes?
		bne.s	Obj2E_ChkShield
		move.b	#1,(plyr_speedflag).w ; speed up the	BG music
		move.w	#$4B0,($FFFFD034).w ; time limit for the power-up
		move.w	#$C00,($FFFFF760).w ; change Sonic's top speed
		move.w	#$18,($FFFFF762).w
		move.w	#$80,($FFFFF764).w
		move.w	#$E2,d0
		jmp	(Sound_CueMusic).l	; Speed	up the music
; ===========================================================================

Obj2E_ChkShield:
		cmpi.b	#4,d0		; does monitor contain a shield?
		bne.s	Obj2E_ChkInvinc
		move.b	#1,(plyr_shieldflag).w ; give	Sonic a	shield
		move.b	#$38,($FFFFD180).w ; load shield object	($38)
		move.w	#$AF,d0
		jmp	(Sound_CueMusic).l	; play shield sound
; ===========================================================================

Obj2E_ChkInvinc:
		cmpi.b	#5,d0		; does monitor contain invincibility?
		bne.s	Obj2E_ChkRings
		move.b	#1,(plyr_invincflag).w ; make	Sonic invincible
		move.w	#$4B0,($FFFFD032).w ; time limit for the power-up
		move.b	#$38,($FFFFD200).w ; load stars	object ($3801)
		move.b	#1,($FFFFD21C).w
		move.b	#$38,($FFFFD240).w ; load stars	object ($3802)
		move.b	#2,($FFFFD25C).w
		move.b	#$38,($FFFFD280).w ; load stars	object ($3803)
		move.b	#3,($FFFFD29C).w
		move.b	#$38,($FFFFD2C0).w ; load stars	object ($3804)
		move.b	#4,($FFFFD2DC).w
		tst.b	($FFFFF7AA).w	; is boss mode on?
		bne.s	Obj2E_NoMusic	; if yes, branch
		move.w	#$87,d0
		jmp	(Sound_CueMusic).l	; play invincibility music
; ===========================================================================

Obj2E_NoMusic:
		rts	
; ===========================================================================

Obj2E_ChkRings:
		cmpi.b	#6,d0		; does monitor contain 10 rings?
		bne.s	Obj2E_ChkS
		addi.w	#$A,(plyr_rings).w ; add	10 rings to the	number of rings	you have
		ori.b	#1,($FFFFFE1D).w ; update the ring counter
		cmpi.w	#100,(plyr_rings).w ; check if you have 100 rings
		bcs.s	Obj2E_RingSound
		bset	#1,($FFFFFE1B).w
		beq.w	ExtraLife
		cmpi.w	#200,(plyr_rings).w ; check if you have 200 rings
		bcs.s	Obj2E_RingSound
		bset	#2,($FFFFFE1B).w
		beq.w	ExtraLife

Obj2E_RingSound:
		move.w	#$B5,d0
		jmp	(Sound_CueMusic).l	; play ring sound
; ===========================================================================

Obj2E_ChkS:
		cmpi.b	#7,d0		; does monitor contain 'S'
		bne.s	Obj2E_ChkEnd
		nop	

Obj2E_ChkEnd:
		rts			; 'S' and goggles monitors do nothing
; ===========================================================================

Obj2E_Delete:				; XREF: Obj2E_Index
		subq.w	#1,$1E(a0)
		bmi.w	DeleteObject
		rts	

; ===========================================================================


; ---------------------------------------------------------------------------
; Subroutine to	animate	a sprite using an animation script
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Actor_Animate:
		moveq	#0,d0
		move.b	$1C(a0),d0	; move animation number	to d0
		cmp.b	$1D(a0),d0	; is animation set to restart?
		beq.s	Anim_Run	; if not, branch
		move.b	d0,$1D(a0)	; set to "no restart"
		move.b	#0,$1B(a0)	; reset	animation
		move.b	#0,$1E(a0)	; reset	frame duration

Anim_Run:
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	Anim_Wait	; if time remains, branch
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation	script
		move.b	(a1),$1E(a0)	; load frame duration
		moveq	#0,d1
		move.b	$1B(a0),d1	; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		cmp.b	#$FA,d0					; MJ: is it a flag from FA to FF?
		bhs	Anim_End_FF				; MJ: if so, branch to flag routines

Anim_Next:
		move.b	d0,d1
		andi.b	#$1F,d0
		move.b	d0,$1A(a0)	; load sprite number
		move.b	$22(a0),d0
		rol.b	#3,d1
		eor.b	d0,d1
		andi.b	#3,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		addq.b	#1,$1B(a0)	; next frame number

Anim_Wait:
		rts	
; ===========================================================================

Anim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF	?
		bne.s	Anim_End_FE	; if not, branch
		move.b	#0,$1B(a0)	; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.s	Anim_Next
; ===========================================================================

Anim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE	?
		bne.s	Anim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next	byte in	the script
		sub.b	d0,$1B(a0)	; jump back d0 bytes in	the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.s	Anim_Next
; ===========================================================================

Anim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD	?
		bne.s	Anim_End_FC	; if not, branch
		move.b	2(a1,d1.w),$1C(a0) ; read next byte, run that animation

Anim_End_FC:
		addq.b	#1,d0		; is the end flag = $FC	?
		bne.s	Anim_End_FB	; if not, branch
		addq.b	#2,$24(a0)	; jump to next routine

Anim_End_FB:
		addq.b	#1,d0		; is the end flag = $FB	?
		bne.s	Anim_End_FA	; if not, branch
		move.b	#0,$1B(a0)	; reset	animation
		clr.b	$25(a0)		; reset	2nd routine counter

Anim_End_FA:
		addq.b	#1,d0		; is the end flag = $FA	?
		bne.s	Anim_End	; if not, branch
		addq.b	#2,$25(a0)	; jump to next routine

Anim_End:
		rts	
; End of function Actor_Animate

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 34 - zone title cards
; ---------------------------------------------------------------------------

Obj34:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj34_Index(pc,d0.w),d1
		jmp	Obj34_Index(pc,d1.w)
; ===========================================================================
Obj34_Index:	dc.w Obj34_CheckSBZ3-Obj34_Index
		dc.w Obj34_ChkPos-Obj34_Index
		dc.w Obj34_Wait-Obj34_Index
		dc.w Obj34_Wait-Obj34_Index
; ===========================================================================

Obj34_CheckSBZ3:			; XREF: Obj34_Index
		movea.l	a0,a1
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		cmpi.w	#$103,(lvl_id).w ; check if level is	SBZ 3
		bne.s	Obj34_CheckFZ
		moveq	#5,d0		; load title card number 5 (SBZ)

Obj34_CheckFZ:
		move.w	d0,d2
		cmpi.w	#$502,(lvl_id).w ; check if level is	FZ
		bne.s	Obj34_LoadConfig
		moveq	#6,d0		; load title card number 6 (FZ)
		moveq	#$B,d2		; use "FINAL" mappings

Obj34_LoadConfig:
		lea	(Obj34_ConData).l,a3
		lsl.w	#4,d0
		adda.w	d0,a3
		lea	(Obj34_ItemData).l,a2
		moveq	#3,d1

Obj34_Loop:
		move.b	#$34,0(a1)
		move.w	(a3),8(a1)	; load start x-position
		move.w	(a3)+,$32(a1)	; load finish x-position (same as start)
		move.w	(a3)+,$30(a1)	; load main x-position
		move.w	(a2)+,$A(a1)
		move.b	(a2)+,$24(a1)
		move.b	(a2)+,d0
		bne.s	Obj34_ActNumber
		move.b	d2,d0

Obj34_ActNumber:
		cmpi.b	#7,d0
		bne.s	Obj34_MakeSprite
		add.b	($FFFFFE11).w,d0
		cmpi.b	#3,($FFFFFE11).w
		bne.s	Obj34_MakeSprite
		subq.b	#1,d0

Obj34_MakeSprite:
		move.b	d0,$1A(a1)	; display frame	number d0
		move.l	#Map_obj34,4(a1)
		move.w	#$8580,2(a1)
		move.b	#$78,$19(a1)
		move.b	#0,1(a1)
		move.b	#0,$18(a1)
		move.w	#60,$1E(a1)	; set time delay to 1 second
		lea	$40(a1),a1	; next object
		dbf	d1,Obj34_Loop	; repeat sequence another 3 times

Obj34_ChkPos:				; XREF: Obj34_Index
		moveq	#$10,d1		; set horizontal speed
		move.w	$30(a0),d0
		cmp.w	8(a0),d0	; has item reached the target position?
		beq.s	loc_C3C8	; if yes, branch
		bge.s	Obj34_Move
		neg.w	d1

Obj34_Move:
		add.w	d1,8(a0)	; change item's position

loc_C3C8:
		move.w	8(a0),d0
		bmi.s	locret_C3D8
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.s	locret_C3D8	; if yes, branch
		bra.w	Actor_Display
; ===========================================================================

locret_C3D8:
		rts	
; ===========================================================================

Obj34_Wait:				; XREF: Obj34_Index
		tst.w	$1E(a0)		; is time remaining zero?
		beq.s	Obj34_ChkPos2	; if yes, branch
		subq.w	#1,$1E(a0)	; subtract 1 from time
		bra.w	Actor_Display
; ===========================================================================

Obj34_ChkPos2:				; XREF: Obj34_Wait
		tst.b	1(a0)
		bpl.s	Obj34_ChangeArt
		moveq	#$20,d1
		move.w	$32(a0),d0
		cmp.w	8(a0),d0	; has item reached the finish position?
		beq.s	Obj34_ChangeArt	; if yes, branch
		bge.s	Obj34_Move2
		neg.w	d1

Obj34_Move2:
		add.w	d1,8(a0)	; change item's position
		move.w	8(a0),d0
		bmi.s	locret_C412
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.s	locret_C412	; if yes, branch
		bra.w	Actor_Display
; ===========================================================================

locret_C412:
		rts	
; ===========================================================================

Obj34_ChangeArt:			; XREF: Obj34_ChkPos2
		cmpi.b	#4,$24(a0)
		bne.s	Obj34_Delete
		moveq	#0,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#1,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#2,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		addi.w	#$15,d0
		jsr	(LoadPLC).l	; load animal patterns

Obj34_Delete:
		bra.w	DeleteObject
; ===========================================================================
Obj34_ItemData:	dc.w $D0	; y-axis position
		dc.b 2,	0	; routine number, frame	number (changes)
		dc.w $E4
		dc.b 2,	6
		dc.w $EA
		dc.b 2,	7
		dc.w $E0
		dc.b 2,	$A
; ---------------------------------------------------------------------------
; Title	card configuration data
; Format:
; 4 bytes per item (YYYY XXXX)
; 4 items per level (GREEN HILL, ZONE, ACT X, oval)
; ---------------------------------------------------------------------------
Obj34_ConData:	dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; GHZ
		dc.w 0,	$120, $FEF4, $134, $40C, $14C, $20C, $14C ; LZ
		dc.w 0,	$120, $FEE0, $120, $3F8, $138, $1F8, $138 ; MZ
		dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; SLZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SYZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SBZ
		dc.w 0,	$120, $FEE4, $124, $3EC, $3EC, $1EC, $12C ; FZ
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - zone title cards
; ---------------------------------------------------------------------------
Map_obj34:	dc.w byte_C9FE-Map_obj34
		dc.w byte_CA2C-Map_obj34
		dc.w byte_CA5A-Map_obj34
		dc.w byte_CA7A-Map_obj34
		dc.w byte_CAA8-Map_obj34
		dc.w byte_CADC-Map_obj34
		dc.w byte_CB10-Map_obj34
		dc.w byte_CB26-Map_obj34
		dc.w byte_CB31-Map_obj34
		dc.w byte_CB3C-Map_obj34
		dc.w byte_CB47-Map_obj34
		dc.w byte_CB8A-Map_obj34
byte_C9FE:	dc.b 9 			; GREEN HILL
		dc.b $F8, 5, 0,	$18, $B4
		dc.b $F8, 5, 0,	$3A, $C4
		dc.b $F8, 5, 0,	$10, $D4
		dc.b $F8, 5, 0,	$10, $E4
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	$1C, $14
		dc.b $F8, 1, 0,	$20, $24
		dc.b $F8, 5, 0,	$26, $2C
		dc.b $F8, 5, 0,	$26, $3C
byte_CA2C:	dc.b 9			; LABYRINTH
		dc.b $F8, 5, 0,	$26, $BC
		dc.b $F8, 5, 0,	0, $CC
		dc.b $F8, 5, 0,	4, $DC
		dc.b $F8, 5, 0,	$4A, $EC
		dc.b $F8, 5, 0,	$3A, $FC
		dc.b $F8, 1, 0,	$20, $C
		dc.b $F8, 5, 0,	$2E, $14
		dc.b $F8, 5, 0,	$42, $24
		dc.b $F8, 5, 0,	$1C, $34
byte_CA5A:	dc.b 6			; MARBLE
		dc.b $F8, 5, 0,	$2A, $CF
		dc.b $F8, 5, 0,	0, $E0
		dc.b $F8, 5, 0,	$3A, $F0
		dc.b $F8, 5, 0,	4, 0
		dc.b $F8, 5, 0,	$26, $10
		dc.b $F8, 5, 0,	$10, $20
		dc.b 0
byte_CA7A:	dc.b 9			; STAR	LIGHT
		dc.b $F8, 5, 0,	$3E, $B4
		dc.b $F8, 5, 0,	$42, $C4
		dc.b $F8, 5, 0,	0, $D4
		dc.b $F8, 5, 0,	$3A, $E4
		dc.b $F8, 5, 0,	$26, 4
		dc.b $F8, 1, 0,	$20, $14
		dc.b $F8, 5, 0,	$18, $1C
		dc.b $F8, 5, 0,	$1C, $2C
		dc.b $F8, 5, 0,	$42, $3C
byte_CAA8:	dc.b $A			; SPRING YARD
		dc.b $F8, 5, 0,	$3E, $AC
		dc.b $F8, 5, 0,	$36, $BC
		dc.b $F8, 5, 0,	$3A, $CC
		dc.b $F8, 1, 0,	$20, $DC
		dc.b $F8, 5, 0,	$2E, $E4
		dc.b $F8, 5, 0,	$18, $F4
		dc.b $F8, 5, 0,	$4A, $14
		dc.b $F8, 5, 0,	0, $24
		dc.b $F8, 5, 0,	$3A, $34
		dc.b $F8, 5, 0,	$C, $44
		dc.b 0
byte_CADC:	dc.b $A			; SCRAP BRAIN
		dc.b $F8, 5, 0,	$3E, $AC
		dc.b $F8, 5, 0,	8, $BC
		dc.b $F8, 5, 0,	$3A, $CC
		dc.b $F8, 5, 0,	0, $DC
		dc.b $F8, 5, 0,	$36, $EC
		dc.b $F8, 5, 0,	4, $C
		dc.b $F8, 5, 0,	$3A, $1C
		dc.b $F8, 5, 0,	0, $2C
		dc.b $F8, 1, 0,	$20, $3C
		dc.b $F8, 5, 0,	$2E, $44
		dc.b 0
byte_CB10:	dc.b 4			; ZONE
		dc.b $F8, 5, 0,	$4E, $E0
		dc.b $F8, 5, 0,	$32, $F0
		dc.b $F8, 5, 0,	$2E, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b 0
byte_CB26:	dc.b 2			; ACT 1
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 2, 0,	$57, $C
byte_CB31:	dc.b 2			; ACT 2
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$5A, 8
byte_CB3C:	dc.b 2			; ACT 3
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$60, 8
byte_CB47:	dc.b $D			; Oval
		dc.b $E4, $C, 0, $70, $F4
		dc.b $E4, 2, 0,	$74, $14
		dc.b $EC, 4, 0,	$77, $EC
		dc.b $F4, 5, 0,	$79, $E4
		dc.b $14, $C, $18, $70,	$EC
		dc.b 4,	2, $18,	$74, $E4
		dc.b $C, 4, $18, $77, 4
		dc.b $FC, 5, $18, $79, $C
		dc.b $EC, 8, 0,	$7D, $FC
		dc.b $F4, $C, 0, $7C, $F4
		dc.b $FC, 8, 0,	$7C, $F4
		dc.b 4,	$C, 0, $7C, $EC
		dc.b $C, 8, 0, $7C, $EC
		dc.b 0
byte_CB8A:	dc.b 5			; FINAL
		dc.b $F8, 5, 0,	$14, $DC
		dc.b $F8, 1, 0,	$20, $EC
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	0, 4
		dc.b $F8, 5, 0,	$26, $14
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 36 - spikes
; ---------------------------------------------------------------------------

Obj36:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj36_Index(pc,d0.w),d1
		jmp	Obj36_Index(pc,d1.w)
; ===========================================================================
Obj36_Index:	dc.w Obj36_Main-Obj36_Index
		dc.w Obj36_Solid-Obj36_Index

Obj36_Var:	dc.b 0,	$14		; frame	number,	object width
		dc.b 1,	$10
		dc.b 2,	4
		dc.b 3,	$1C
		dc.b 4,	$40
		dc.b 5,	$10
; ===========================================================================

Obj36_Main:				; XREF: Obj36_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj36,4(a0)
		move.w	#$51B,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	$28(a0),d0
		andi.b	#$F,$28(a0)
		andi.w	#$F0,d0
		lea	(Obj36_Var).l,a1
		lsr.w	#3,d0
		adda.w	d0,a1
		move.b	(a1)+,$1A(a0)
		move.b	(a1)+,$19(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)

Obj36_Solid:				; XREF: Obj36_Index
		bsr.w	Obj36_Type0x	; make the object move
		move.w	#4,d2
		cmpi.b	#5,$1A(a0)	; is object type $5x ?
		beq.s	Obj36_SideWays	; if yes, branch
		cmpi.b	#1,$1A(a0)	; is object type $1x ?
		bne.s	Obj36_Upright	; if not, branch
		move.w	#$14,d2

; Spikes types $1x and $5x face	sideways

Obj36_SideWays:				; XREF: Obj36_Solid
		move.w	#$1B,d1
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#3,$22(a0)
		bne.s	Obj36_Display
		cmpi.w	#1,d4
		beq.s	Obj36_Hurt
		bra.s	Obj36_Display
; ===========================================================================

; Spikes types $0x, $2x, $3x and $4x face up or	down

Obj36_Upright:				; XREF: Obj36_Solid
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		btst	#3,$22(a0)
		bne.s	Obj36_Hurt
		tst.w	d4
		bpl.s	Obj36_Display

Obj36_Hurt:				; XREF: Obj36_SideWays; Obj36_Upright
		tst.b	(plyr_invincflag).w	; is Sonic invincible?
		bne.s	Obj36_Display	; if yes, branch
		tst.w	($FFFFD030).w	; +++ is Sonic invulnerable?
		bne.s	Obj36_Display	; +++ if yes, branch
		move.l	a0,-(sp)
		movea.l	a0,a2
		lea	(ACTSLOT_PLAYER).w,a0
		cmpi.b	#4,$24(a0)
		bcc.s	loc_CF20
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		jsr	HurtSonic

loc_CF20:
		movea.l	(sp)+,a0

Obj36_Display:
		bsr.w	Actor_Display
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		rts	
; ===========================================================================

Obj36_Type0x:				; XREF: Obj36_Solid
		moveq	#0,d0
		move.b	$28(a0),d0
		add.w	d0,d0
		move.w	Obj36_TypeIndex(pc,d0.w),d1
		jmp	Obj36_TypeIndex(pc,d1.w)
; ===========================================================================
Obj36_TypeIndex:dc.w Obj36_Type00-Obj36_TypeIndex
		dc.w Obj36_Type01-Obj36_TypeIndex
		dc.w Obj36_Type02-Obj36_TypeIndex
; ===========================================================================

Obj36_Type00:				; XREF: Obj36_TypeIndex
		rts			; don't move the object
; ===========================================================================

Obj36_Type01:				; XREF: Obj36_TypeIndex
		bsr.w	Obj36_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)	; move the object vertically
		rts	
; ===========================================================================

Obj36_Type02:				; XREF: Obj36_TypeIndex
		bsr.w	Obj36_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)	; move the object horizontally
		rts	
; ===========================================================================

Obj36_Wait:
		tst.w	$38(a0)		; is time delay	= zero?
		beq.s	loc_CFA4	; if yes, branch
		subq.w	#1,$38(a0)	; subtract 1 from time delay
		bne.s	locret_CFE6
		tst.b	1(a0)
		bpl.s	locret_CFE6
		move.w	#$B6,d0
		jsr	(Sound_CueSFX).l ;	play "spikes moving" sound
		bra.s	locret_CFE6
; ===========================================================================

loc_CFA4:
		tst.w	$36(a0)
		beq.s	loc_CFC6
		subi.w	#$800,$34(a0)
		bcc.s	locret_CFE6
		move.w	#0,$34(a0)
		move.w	#0,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second
		bra.s	locret_CFE6
; ===========================================================================

loc_CFC6:
		addi.w	#$800,$34(a0)
		cmpi.w	#$2000,$34(a0)
		bcs.s	locret_CFE6
		move.w	#$2000,$34(a0)
		move.w	#1,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second

locret_CFE6:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - spikes
; ---------------------------------------------------------------------------
Map_obj36:
	include "_maps\obj36.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	smash a	block (GHZ walls and MZ	blocks)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SmashObject:				; XREF: Obj3C_Smash
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		bra.s	Smash_LoadFrag
; ===========================================================================

Smash_Loop:
		bsr.w	SingleObjLoad
		bne.s	Smash_PlaySnd
		addq.w	#5,a3

Smash_LoadFrag:				; XREF: SmashObject
		move.b	#4,$24(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.b	$18(a0),$18(a1)
		move.b	$19(a0),$19(a1)
		move.w	(a4)+,$10(a1)
		move.w	(a4)+,$12(a1)
		cmpa.l	a0,a1
		bcc.s	loc_D268
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	SpeedToPos
		add.w	d2,$12(a0)
		movea.l	(sp)+,a0
		bsr.w	Actor_Display2

loc_D268:
		dbf	d1,Smash_Loop

Smash_PlaySnd:
		move.w	#$CB,d0
		jmp	(Sound_CueSFX).l ;	play smashing sound
; End of function SmashObject

; ---------------------------------------------------------------------------
; Object code loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Actor_Execute:				; XREF: TitleScreen; et al
		lea	(act_buffer).w,a0 ; set address for object RAM
		moveq	#$7F,d7
		moveq	#0,d0
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.s	loc_D362

loc_D348:
		move.b	(a0),d0		; load object number from RAM
		beq.s	loc_D358
		add.w	d0,d0
		add.w	d0,d0
		movea.l	Obj_Index-4(pc,d0.w),a1
		jsr	(a1)		; run the object's code
		moveq	#0,d0

loc_D358:
		lea	$40(a0),a0	; next object
		dbf	d7,loc_D348
		rts	
; ===========================================================================

loc_D362:
		cmpi.b	#$A,(ACTSLOT_PLAYER+act_routine).w	; Has Sonic drowned?
		beq.s	loc_D348				; If so, run objects a little longer
		moveq	#$1F,d7
		bsr.s	loc_D348
		moveq	#$5F,d7

loc_D368:
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_D378
		tst.b	1(a0)
		bpl.s	loc_D378
		bsr.w	Actor_Display

loc_D378:
		lea	$40(a0),a0

loc_D37C:
		dbf	d7,loc_D368
		rts	
; End of function Actor_Execute

; ===========================================================================
; ---------------------------------------------------------------------------
; Object pointers
; ---------------------------------------------------------------------------
Obj_Index:
	dc.l Obj01, DeleteObject,	Obj03, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, Obj08
	dc.l DeleteObject, Obj0A, DeleteObject, DeleteObject
	dc.l DeleteObject, Act_Title, Act_TitleMenu, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, Obj1B, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l Obj21, DeleteObject, DeleteObject, DeleteObject
	dc.l Obj25, Act_ItemBox, Obj27, Obj28
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, Act_PowerUp, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, Obj34
	dc.l DeleteObject, Obj36, Obj37, Obj38
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, Obj3E, DeleteObject, DeleteObject
	dc.l Obj41, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, Obj64
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l Obj71, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l Obj79, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject
	dc.l DeleteObject, DeleteObject, DeleteObject, DeleteObject

; ---------------------------------------------------------------------------
; Subroutine to	make an	object fall downwards, increasingly fast
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjectFall:
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	$12(a0),d0
		addi.w	#$38,$12(a0)	; increase vertical speed
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts	
; End of function ObjectFall

; ---------------------------------------------------------------------------
; Subroutine translating object	speed to update	object position
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SpeedToPos:
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0	; load horizontal speed
		ext.l	d0
		asl.l	#8,d0		; multiply speed by $100
		add.l	d0,d2		; add to x-axis	position
		move.w	$12(a0),d0	; load vertical	speed
		ext.l	d0
		asl.l	#8,d0		; multiply by $100
		add.l	d0,d3		; add to y-axis	position
		move.l	d2,8(a0)	; update x-axis	position
		move.l	d3,$C(a0)	; update y-axis	position
		rts	
; End of function SpeedToPos

; ---------------------------------------------------------------------------
; Subroutine to	display	a sprite/object, when a0 is the	object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Actor_Display:
		lea	(spr_pritbl).w,a1
		move.w	$18(a0),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a1
		cmpi.w	#$7E,(a1)
		bcc.s	locret_D620
		addq.w	#2,(a1)
		adda.w	(a1),a1
		move.w	a0,(a1)

locret_D620:
		rts	
; End of function Actor_Display

; ---------------------------------------------------------------------------
; Subroutine to	display	a 2nd sprite/object, when a1 is	the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Actor_Display2:
		lea	(spr_pritbl).w,a2
		move.w	$18(a1),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a2
		cmpi.w	#$7E,(a2)
		bcc.s	locret_D63E
		addq.w	#2,(a2)
		adda.w	(a2),a2
		move.w	a1,(a2)

locret_D63E:
		rts	
; End of function Actor_Display2

; ---------------------------------------------------------------------------
; Subroutine to	delete an object
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DeleteObject:
		movea.l	a0,a1

DeleteObject2:
		moveq	#0,d1
		moveq	#$F,d0

loc_D646:
		move.l	d1,(a1)+	; clear	the object RAM
		dbf	d0,loc_D646	; repeat $F times (length of object RAM)
		rts	
; End of function DeleteObject

; ===========================================================================
BldSpr_ScrPos:	dc.l 0			; blank
		dc.l $FFF700		; main screen x-position
		dc.l $FFF708		; background x-position	1
		dc.l $FFF718		; background x-position	2
; ---------------------------------------------------------------------------
; Subroutine to	convert	mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sprites_Render:				; XREF: TitleScreen; et al
		lea	(spr_buffer).w,a2 ; set address for sprite table
		moveq	#0,d5
		lea	(spr_pritbl).w,a4
		moveq	#7,d7

loc_D66A:
		tst.w	(a4)
		beq.w	loc_D72E
		moveq	#2,d6

loc_D672:
		movea.w	(a4,d6.w),a0
		tst.b	(a0)
		beq.w	loc_D726
		bclr	#7,1(a0)
		move.b	1(a0),d0
		move.b	d0,d4
		andi.w	#$C,d0
		beq.s	loc_D6DE
		movea.l	BldSpr_ScrPos(pc,d0.w),a1
		moveq	#0,d0
		move.b	$19(a0),d0
		move.w	8(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D726
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.s	loc_D726
		addi.w	#$80,d3
		btst	#4,d4
		beq.s	loc_D6E8
		moveq	#0,d0
		move.b	$16(a0),d0
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	loc_D726
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#$E0,d1
		bge.s	loc_D726
		addi.w	#$80,d2
		bra.s	loc_D700
; ===========================================================================

loc_D6DE:
		move.w	$A(a0),d2
		move.w	8(a0),d3
		bra.s	loc_D700
; ===========================================================================

loc_D6E8:
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		bcs.s	loc_D726
		cmpi.w	#$180,d2
		bcc.s	loc_D726

loc_D700:
		movea.l	4(a0),a1
		moveq	#0,d1
		btst	#5,d4
		bne.s	loc_D71C
		move.b	$1A(a0),d1
		add.w	d1,d1					; MJ: changed from byte to word (we want more than 7F sprites)
		adda.w	(a1,d1.w),a1
		moveq	#$00,d1					; MJ: clear d1 (because of our byte to word change)
		move.b	(a1)+,d1
		subq.b	#1,d1
		bmi.s	loc_D720

loc_D71C:
		bsr.w	sub_D750

loc_D720:
		bset	#7,1(a0)

loc_D726:
		addq.w	#2,d6
		subq.w	#2,(a4)
		bne.w	loc_D672

loc_D72E:
		lea	$80(a4),a4
		dbf	d7,loc_D66A
		move.b	d5,(spr_count).w
		cmpi.b	#$50,d5
		beq.s	loc_D748
		move.l	#0,(a2)
		rts	
; ===========================================================================

loc_D748:
		move.b	#0,-5(a2)
		rts	
; End of function Sprites_Render


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_D750:				; XREF: Sprites_Render
		movea.w	2(a0),a3
		btst	#0,d4
		bne.s	loc_D796
		btst	#1,d4
		bne.w	loc_D7E4
; End of function sub_D750


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_D762:				; XREF: sub_D762; SS_ShowLayout
		cmpi.b	#$50,d5
		beq.s	locret_D794
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D78E
		addq.w	#1,d0

loc_D78E:
		move.w	d0,(a2)+
		dbf	d1,sub_D762

locret_D794:
		rts	
; End of function sub_D762

; ===========================================================================

loc_D796:
		btst	#1,d4
		bne.w	loc_D82A

loc_D79E:
		cmpi.b	#$50,d5
		beq.s	locret_D7E2
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$800,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D7DC
		addq.w	#1,d0

loc_D7DC:
		move.w	d0,(a2)+
		dbf	d1,loc_D79E

locret_D7E2:
		rts	
; ===========================================================================

loc_D7E4:				; XREF: sub_D750
		cmpi.b	#$50,d5
		beq.s	locret_D828
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D822
		addq.w	#1,d0

loc_D822:
		move.w	d0,(a2)+
		dbf	d1,loc_D7E4

locret_D828:
		rts	
; ===========================================================================

loc_D82A:
		cmpi.b	#$50,d5
		beq.s	locret_D87C
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	loc_D876
		addq.w	#1,d0

loc_D876:
		move.w	d0,(a2)+
		dbf	d1,loc_D82A

locret_D87C:
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	check if an object is on the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChkObjOnScreen:
		move.w	8(a0),d0	; get object x-position
		sub.w	(lvl_fgxpos).w,d0 ; subtract screen x-position
		bmi.s	NotOnScreen
		cmpi.w	#320,d0		; is object on the screen?
		bge.s	NotOnScreen	; if not, branch

		move.w	$C(a0),d1	; get object y-position
		sub.w	(lvl_fgypos).w,d1 ; subtract screen y-position
		bmi.s	NotOnScreen
		cmpi.w	#224,d1		; is object on the screen?
		bge.s	NotOnScreen	; if not, branch

		moveq	#0,d0		; set flag to 0
		rts	
; ===========================================================================

NotOnScreen:				; XREF: ChkObjOnScreen
		moveq	#1,d0		; set flag to 1
		rts	
; End of function ChkObjOnScreen


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChkObjOnScreen2:
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	8(a0),d0
		sub.w	(lvl_fgxpos).w,d0
		add.w	d1,d0
		bmi.s	NotOnScreen2
		add.w	d1,d1
		sub.w	d1,d0
		cmpi.w	#320,d0
		bge.s	NotOnScreen2

		move.w	$C(a0),d1
		sub.w	(lvl_fgypos).w,d1
		bmi.s	NotOnScreen2
		cmpi.w	#224,d1
		bge.s	NotOnScreen2

		moveq	#0,d0
		rts	
; ===========================================================================

NotOnScreen2:				; XREF: ChkObjOnScreen2
		moveq	#1,d0
		rts	
; End of function ChkObjOnScreen2

; ---------------------------------------------------------------------------
; Subroutine to	load a level's objects
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjPosLoad:				; XREF: Level; et al
		moveq	#0,d0
		move.b	($FFFFF76C).w,d0
		move.w	OPL_Index(pc,d0.w),d0
		jmp	OPL_Index(pc,d0.w)
; End of function ObjPosLoad

; ===========================================================================
OPL_Index:	dc.w OPL_Main-OPL_Index
		dc.w OPL_Next-OPL_Index
; ===========================================================================

OPL_Main:				; XREF: OPL_Index
		addq.b	#2,($FFFFF76C).w
		move.w	(lvl_id).w,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		lea	(ObjPos_Index).l,a0
		movea.l	a0,a1
		adda.w	(a0,d0.w),a0
		move.l	a0,($FFFFF770).w
		move.l	a0,($FFFFF774).w
		adda.w	2(a1,d0.w),a1
		move.l	a1,($FFFFF778).w
		move.l	a1,($FFFFF77C).w
		lea	($FFFFFC00).w,a2
		move.w	#$101,(a2)+
		move.w	#$5E,d0

OPL_ClrList:
		clr.l	(a2)+
		dbf	d0,OPL_ClrList	; clear	pre-destroyed object list

		lea	($FFFFFC00).w,a2
		moveq	#0,d2
		move.w	(lvl_fgxpos).w,d6
		subi.w	#$80,d6
		bcc.s	loc_D93C
		moveq	#0,d6

loc_D93C:
		andi.w	#$FF80,d6
		movea.l	($FFFFF770).w,a0

loc_D944:
		cmp.w	(a0),d6
		bls.s	loc_D956
		tst.b	4(a0)
		bpl.s	loc_D952
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_D952:
		addq.w	#6,a0
		bra.s	loc_D944
; ===========================================================================

loc_D956:
		move.l	a0,($FFFFF770).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$80,d6
		bcs.s	loc_D976

loc_D964:
		cmp.w	(a0),d6
		bls.s	loc_D976
		tst.b	4(a0)
		bpl.s	loc_D972
		addq.b	#1,1(a2)

loc_D972:
		addq.w	#6,a0
		bra.s	loc_D964
; ===========================================================================

loc_D976:
		move.l	a0,($FFFFF774).w
		move.w	#-1,(act_fgxpos).w

OPL_Next:				; XREF: OPL_Index
		lea	($FFFFFC00).w,a2
		moveq	#0,d2
		move.w	(lvl_fgxpos).w,d6
		andi.w	#$FF80,d6
		cmp.w	(act_fgxpos).w,d6
		beq.w	locret_DA3A
		bge.s	loc_D9F6
		move.w	d6,(act_fgxpos).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$80,d6
		bcs.s	loc_D9D2

loc_D9A6:
		cmp.w	-6(a0),d6
		bge.s	loc_D9D2
		subq.w	#6,a0
		tst.b	4(a0)
		bpl.s	loc_D9BC
		subq.b	#1,1(a2)
		move.b	1(a2),d2

loc_D9BC:
		bsr.w	loc_DA3C
		bne.s	loc_D9C6
		subq.w	#6,a0
		bra.s	loc_D9A6
; ===========================================================================

loc_D9C6:
		tst.b	4(a0)
		bpl.s	loc_D9D0
		addq.b	#1,1(a2)

loc_D9D0:
		addq.w	#6,a0

loc_D9D2:
		move.l	a0,($FFFFF774).w
		movea.l	($FFFFF770).w,a0
		addi.w	#$300,d6

loc_D9DE:
		cmp.w	-6(a0),d6
		bgt.s	loc_D9F0
		tst.b	-2(a0)
		bpl.s	loc_D9EC
		subq.b	#1,(a2)

loc_D9EC:
		subq.w	#6,a0
		bra.s	loc_D9DE
; ===========================================================================

loc_D9F0:
		move.l	a0,($FFFFF770).w
		rts	
; ===========================================================================

loc_D9F6:
		move.w	d6,(act_fgxpos).w
		movea.l	($FFFFF770).w,a0
		addi.w	#$280,d6

loc_DA02:
		cmp.w	(a0),d6
		bls.s	loc_DA16
		tst.b	4(a0)
		bpl.s	loc_DA10
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_DA10:
		bsr.w	loc_DA3C
		beq.s	loc_DA02
		tst.b	$04(a0)		; was this object a remember state?
		bpl.s	loc_DA16	; if not, branch
		subq.b	#$01,(a2)	; move right counter back

loc_DA16:
		move.l	a0,($FFFFF770).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$300,d6
		bcs.s	loc_DA36

loc_DA24:
		cmp.w	(a0),d6
		bls.s	loc_DA36
		tst.b	4(a0)
		bpl.s	loc_DA32
		addq.b	#1,1(a2)

loc_DA32:
		addq.w	#6,a0
		bra.s	loc_DA24
; ===========================================================================

loc_DA36:
		move.l	a0,($FFFFF774).w

locret_DA3A:
		rts	
; ===========================================================================

loc_DA3C:
		tst.b	4(a0)
		bpl.s	OPL_MakeItem
		btst	#7,2(a2,d2.w)
		beq.s	OPL_MakeItem
		addq.w	#6,a0
		moveq	#0,d0
		rts	
; ===========================================================================

OPL_MakeItem:
		bsr.w	SingleObjLoad
		bne.s	locret_DA8A
		move.w	(a0)+,8(a1)
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$FFF,d0
		move.w	d0,$C(a1)
		rol.w	#2,d1
		andi.b	#3,d1
		move.b	d1,1(a1)
		move.b	d1,$22(a1)
		move.b	(a0)+,d0
		bpl.s	loc_DA80
		bset	#7,2(a2,d2.w)	; set as removed
		andi.b	#$7F,d0
		move.b	d2,$23(a1)

loc_DA80:
		move.b	d0,0(a1)
		move.b	(a0)+,$28(a1)
		moveq	#0,d0

locret_DA8A:
		rts	
; ---------------------------------------------------------------------------
; Single object	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SingleObjLoad:
		lea	(act_dynamic).w,a1 ; start address for object RAM
		move.w	#$5F,d0

loc_DA94:
		tst.b	(a1)		; is object RAM	slot empty?
		beq.s	locret_DAA0	; if yes, branch
		lea	$40(a1),a1	; goto next object RAM slot
		dbf	d0,loc_DA94	; repeat $5F times

locret_DAA0:
		rts	
; End of function SingleObjLoad


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SingleObjLoad2:
		movea.l	a0,a1
		move.w	#-$1000,d0
		sub.w	a0,d0
		lsr.w	#6,d0
		subq.w	#1,d0
		bcs.s	locret_DABC

loc_DAB0:
		tst.b	(a1)
		beq.s	locret_DABC
		lea	$40(a1),a1
		dbf	d0,loc_DAB0

locret_DABC:
		rts	
; End of function SingleObjLoad2

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 41 - springs
; ---------------------------------------------------------------------------

Obj41:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj41_Index(pc,d0.w),d1
		jsr	Obj41_Index(pc,d1.w)
		bsr.w	Actor_Display
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		rts	
; ===========================================================================
Obj41_Index:	dc.w Obj41_Main-Obj41_Index
		dc.w Obj41_Up-Obj41_Index
		dc.w Obj41_AniUp-Obj41_Index
		dc.w Obj41_ResetUp-Obj41_Index
		dc.w Obj41_LR-Obj41_Index
		dc.w Obj41_AniLR-Obj41_Index
		dc.w Obj41_ResetLR-Obj41_Index
		dc.w Obj41_Dwn-Obj41_Index
		dc.w Obj41_AniDwn-Obj41_Index
		dc.w Obj41_ResetDwn-Obj41_Index

Obj41_Powers:	dc.w -$1000		; power	of red spring
		dc.w -$A00		; power	of yellow spring
; ===========================================================================

Obj41_Main:				; XREF: Obj41_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj41,4(a0)
		move.w	#$523,2(a0)
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.b	$28(a0),d0
		btst	#4,d0		; does the spring face left/right?
		beq.s	loc_DB54	; if not, branch
		move.b	#8,$24(a0)	; use "Obj41_LR" routine
		move.b	#1,$1C(a0)
		move.b	#3,$1A(a0)
		move.w	#$533,2(a0)
		move.b	#8,$19(a0)

loc_DB54:
		btst	#5,d0		; does the spring face downwards?
		beq.s	loc_DB66	; if not, branch
		move.b	#$E,$24(a0)	; use "Obj41_Dwn" routine
		bset	#1,$22(a0)

loc_DB66:
		btst	#1,d0
		beq.s	loc_DB72
		bset	#5,2(a0)

loc_DB72:
		andi.w	#$F,d0
		move.w	Obj41_Powers(pc,d0.w),$30(a0)
		rts	
; ===========================================================================

Obj41_Up:				; XREF: Obj41_Index
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		tst.b	$25(a0)		; is Sonic on top of the spring?
		bne.s	Obj41_BounceUp	; if yes, branch
		rts	
; ===========================================================================

Obj41_BounceUp:				; XREF: Obj41_Up
		addq.b	#2,$24(a0)
		addq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)	; move Sonic upwards
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#$10,$1C(a1)	; use "bouncing" animation
		move.b	#2,$24(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		move.w	#$CC,d0
		jsr	(Sound_CueSFX).l ;	play spring sound

Obj41_AniUp:				; XREF: Obj41_Index
		lea	(Ani_obj41).l,a1
		bra.w	Actor_Animate
; ===========================================================================

Obj41_ResetUp:				; XREF: Obj41_Index
		move.b	#1,$1D(a0)	; reset	animation
		subq.b	#4,$24(a0)	; goto "Obj41_Up" routine
		rts	
; ===========================================================================

Obj41_LR:				; XREF: Obj41_Index
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,$24(a0)
		bne.s	loc_DC0C
		move.b	#8,$24(a0)

loc_DC0C:
		btst	#5,$22(a0)
		bne.s	Obj41_BounceLR
		rts	
; ===========================================================================

Obj41_BounceLR:				; XREF: Obj41_LR
		addq.b	#2,$24(a0)
		move.w	$30(a0),$10(a1)	; move Sonic to	the left
		addq.w	#8,8(a1)
		btst	#0,$22(a0)	; is object flipped?
		bne.s	loc_DC36	; if yes, branch
		subi.w	#$10,8(a1)
		neg.w	$10(a1)		; move Sonic to	the right

loc_DC36:
		move.w	#$F,$3E(a1)
		move.w	$10(a1),$14(a1)
		bchg	#0,$22(a1)
		btst	#2,$22(a1)
		bne.s	loc_DC56
		move.b	#0,$1C(a1)	; use running animation

loc_DC56:
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)
		move.w	#$CC,d0
		jsr	(Sound_CueSFX).l ;	play spring sound

Obj41_AniLR:				; XREF: Obj41_Index
		lea	(Ani_obj41).l,a1
		bra.w	Actor_Animate
; ===========================================================================

Obj41_ResetLR:				; XREF: Obj41_Index
		move.b	#2,$1D(a0)	; reset	animation
		subq.b	#4,$24(a0)	; goto "Obj41_LR" routine
		rts	
; ===========================================================================

Obj41_Dwn:				; XREF: Obj41_Index
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	SolidObject
		cmpi.b	#2,$24(a0)
		bne.s	loc_DCA4
		move.b	#$E,$24(a0)

loc_DCA4:
		tst.b	$25(a0)
		bne.s	locret_DCAE
		tst.w	d4
		bmi.s	Obj41_BounceDwn

locret_DCAE:
		rts	
; ===========================================================================

Obj41_BounceDwn:			; XREF: Obj41_Dwn
		addq.b	#2,$24(a0)
		subq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)
		neg.w	$12(a1)		; move Sonic downwards
		bset	#1,$22(a1)
		bclr	#3,$22(a1)
		move.b	#2,$24(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		move.w	#$CC,d0
		jsr	(Sound_CueSFX).l ;	play spring sound

Obj41_AniDwn:				; XREF: Obj41_Index
		lea	(Ani_obj41).l,a1
		bra.w	Actor_Animate
; ===========================================================================

Obj41_ResetDwn:				; XREF: Obj41_Index
		move.b	#1,$1D(a0)	; reset	animation
		subq.b	#4,$24(a0)	; goto "Obj41_Dwn" routine
		rts	
; ===========================================================================
Ani_obj41:
	include "_anim\obj41.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - springs
; ---------------------------------------------------------------------------
Map_obj41:
	include "_maps\obj41.asm"

; ===========================================================================

; ---------------------------------------------------------------------------
; Routine to mark an enemy/monitor/ring	as destroyed
; ---------------------------------------------------------------------------

MarkObjGone:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	Mark_ChkGone
		bra.w	Actor_Display
; ===========================================================================

Mark_ChkGone:
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		beq.s	Mark_Delete
		bclr	#7,2(a2,d0.w)

Mark_Delete:
		bra.w	DeleteObject

; ---------------------------------------------------------------------------
; Solid	object subroutine (includes spikes, blocks, rocks etc)
;
; variables:
; d1 = width
; d2 = height /	2 (when	jumping)
; d3 = height /	2 (when	walking)
; d4 = x-axis position
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SolidObject:
		tst.b	$25(a0)
		beq.w	loc_FAC8
		move.w	d1,d2
		add.w	d2,d2
		lea	(ACTSLOT_PLAYER).w,a1
		btst	#1,$22(a1)
		bne.s	loc_F9FE
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_F9FE
		cmp.w	d2,d0
		bcs.s	loc_FA12

loc_F9FE:
		bclr	#3,$22(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FA12:
		move.w	d4,d2
		bsr.w	MvSonicOnPtfm
		moveq	#0,d4
		rts	
; ===========================================================================

SolidObject71:				; XREF: Obj71_Solid
		tst.b	$25(a0)
		beq.w	loc_FAD0
		move.w	d1,d2
		add.w	d2,d2
		lea	(ACTSLOT_PLAYER).w,a1
		btst	#1,$22(a1)
		bne.s	loc_FA44
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.s	loc_FA44
		cmp.w	d2,d0
		bcs.s	loc_FA58

loc_FA44:
		bclr	#3,$22(a1)
		bclr	#3,$22(a0)
		clr.b	$25(a0)
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FA58:
		move.w	d4,d2
		bsr.w	MvSonicOnPtfm
		moveq	#0,d4
		rts	
; ===========================================================================

SolidObject2F:				; XREF: Obj2F_Solid
		lea	(ACTSLOT_PLAYER).w,a1
		tst.b	1(a0)
		bpl.w	loc_FB92
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_FB92
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_FB92
		move.w	d0,d5
		btst	#0,1(a0)
		beq.s	loc_FA94
		not.w	d5
		add.w	d3,d5

loc_FA94:
		lsr.w	#1,d5
		moveq	#0,d3
		move.b	(a2,d5.w),d3
		sub.b	(a2),d3
		move.w	$C(a0),d5
		sub.w	d3,d5
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	d5,d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_FB92
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_FB92
		bra.w	loc_FB0E
; ===========================================================================

loc_FAC8:
		tst.b	1(a0)
		bpl.w	loc_FB92

loc_FAD0:
		lea	(ACTSLOT_PLAYER).w,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_FB92
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_FB92
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_FB92
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_FB92

loc_FB0E:
		tst.b	(plyr_ignore).w
		bmi.w	loc_FB92
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.w	loc_FB92
		tst.w	($FFFFFE08).w
		bne.w	loc_FBAC
		move.w	d0,d5
		cmp.w	d0,d1
		bcc.s	loc_FB36
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_FB36:
		move.w	d3,d1
		cmp.w	d3,d2
		bcc.s	loc_FB44
		subq.w	#4,d3
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_FB44:
		cmp.w	d1,d5
		bhi.w	loc_FBB0
		cmpi.w	#4,d1
		bls.s	loc_FB8C
		tst.w	d0
		beq.s	loc_FB70
		bmi.s	loc_FB5E
		tst.w	$10(a1)
		bmi.s	loc_FB70
		bra.s	loc_FB64
; ===========================================================================

loc_FB5E:
		tst.w	$10(a1)
		bpl.s	loc_FB70

loc_FB64:
		move.w	#0,$14(a1)	; stop Sonic moving
		move.w	#0,$10(a1)

loc_FB70:
		sub.w	d0,8(a1)
		btst	#1,$22(a1)
		bne.s	loc_FB8C
		bset	#5,$22(a1)
		bset	#5,$22(a0)
		moveq	#1,d4
		rts	
; ===========================================================================

loc_FB8C:
		bsr.s	loc_FBA0
		moveq	#1,d4
		rts	
; ===========================================================================

loc_FB92:
		btst	#5,$22(a0)
		beq.s	loc_FBAC
		move.w	#1,$1C(a1)	; use walking animation

loc_FBA0:
		bclr	#5,$22(a0)
		bclr	#5,$22(a1)

loc_FBAC:
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FBB0:
		tst.w	d3
		bmi.s	loc_FBBC
		cmpi.w	#$10,d3
		bcs.s	loc_FBEE
		bra.s	loc_FB92
; ===========================================================================

loc_FBBC:
		tst.w	$12(a1)
		beq.s	loc_FBD6
		bpl.s	loc_FBD2
		tst.w	d3
		bpl.s	loc_FBD2
		sub.w	d3,$C(a1)
		move.w	#0,$12(a1)	; stop Sonic moving

loc_FBD2:
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FBD6:
		btst	#1,$22(a1)
		bne.s	loc_FBD2
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	KillSonic
		movea.l	(sp)+,a0
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FBEE:
		subq.w	#4,d3
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.s	loc_FC28
		cmp.w	d2,d1
		bcc.s	loc_FC28
		tst.w	$12(a1)
		bmi.s	loc_FC28
		sub.w	d3,$C(a1)
		subq.w	#1,$C(a1)
		bsr.s	sub_FC2C
		move.b	#2,$25(a0)
		bset	#3,$22(a0)
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FC28:
		moveq	#0,d4
		rts	
; End of function SolidObject


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_FC2C:				; XREF: SolidObject
		btst	#3,$22(a1)
		beq.s	loc_FC4E
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		bclr	#3,$22(a2)
		clr.b	$25(a2)

loc_FC4E:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,$3D(a1)
		move.b	#0,$26(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),$14(a1)
		btst	#1,$22(a1)
		beq.s	loc_FC84
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	Sonic_ResetOnFloor
		movea.l	(sp)+,a0

loc_FC84:
		bset	#3,$22(a1)
		bset	#3,$22(a0)
		rts	
; End of function sub_FC2C

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1B - water surface (LZ)
; ---------------------------------------------------------------------------

Obj1B:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj1B_Index(pc,d0.w),d1
		jmp	Obj1B_Index(pc,d1.w)
; ===========================================================================
Obj1B_Index:	dc.w Obj1B_Main-Obj1B_Index
		dc.w Obj1B_Action-Obj1B_Index
; ===========================================================================

Obj1B_Main:				; XREF: Obj1B_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj1B,4(a0)
		move.w	#$C300,2(a0)
		move.b	#4,1(a0)
		move.b	#$80,$19(a0)
		move.w	8(a0),$30(a0)

Obj1B_Action:				; XREF: Obj1B_Index
		move.w	(lvl_fgxpos).w,d1
		andi.w	#$FFE0,d1
		add.w	$30(a0),d1
		btst	#0,($FFFFFE05).w
		beq.s	loc_11114
		addi.w	#$20,d1

loc_11114:
		move.w	d1,8(a0)	; match	obj x-position to screen position
		move.w	($FFFFF646).w,d1
		move.w	d1,$C(a0)	; match	obj y-position to water	height
		tst.b	$32(a0)
		bne.s	Obj1B_Animate
		btst	#7,(jpad_pressed).w ; is Start button pressed?
		beq.s	loc_1114A	; if not, branch
		addq.b	#3,$1A(a0)	; use different	frames
		move.b	#1,$32(a0)	; stop animation
		bra.s	Obj1B_Display
; ===========================================================================

Obj1B_Animate:				; XREF: loc_11114
		tst.w	(gm_paused).w	; is the game paused?
		bne.s	Obj1B_Display	; if yes, branch
		move.b	#0,$32(a0)	; resume animation
		subq.b	#3,$1A(a0)	; use normal frames

loc_1114A:				; XREF: loc_11114
		subq.b	#1,$1E(a0)
		bpl.s	Obj1B_Display
		move.b	#7,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#3,$1A(a0)
		bcs.s	Obj1B_Display
		move.b	#0,$1A(a0)

Obj1B_Display:
		bra.w	Actor_Display
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - water surface (LZ)
; ---------------------------------------------------------------------------
Map_obj1B:
	include "_maps\obj1B.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 71 - invisible	solid blocks
; ---------------------------------------------------------------------------

Obj71:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj71_Index(pc,d0.w),d1
		jmp	Obj71_Index(pc,d1.w)
; ===========================================================================
Obj71_Index:	dc.w Obj71_Main-Obj71_Index
		dc.w Obj71_Solid-Obj71_Index
; ===========================================================================

Obj71_Main:				; XREF: Obj71_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj71,4(a0)
		move.w	#$8680,2(a0)
		ori.b	#4,1(a0)
		move.b	$28(a0),d0	; get object type
		move.b	d0,d1
		andi.w	#$F0,d0		; read only the	1st byte
		addi.w	#$10,d0
		lsr.w	#1,d0
		move.b	d0,$19(a0)	; set object width
		andi.w	#$F,d1		; read only the	2nd byte
		addq.w	#1,d1
		lsl.w	#3,d1
		move.b	d1,$16(a0)	; set object height

Obj71_Solid:				; XREF: Obj71_Index
		bsr.w	ChkObjOnScreen
		bne.s	Obj71_ChkDel
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	SolidObject71

Obj71_ChkDel:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	Obj71_Delete
		tst.w	($FFFFFE08).w	; are you using	debug mode?
		beq.s	Obj71_NoDisplay	; if not, branch
		jmp	Actor_Display	; if yes, display the object
; ===========================================================================

Obj71_NoDisplay:
		rts	
; ===========================================================================

Obj71_Delete:
		jmp	DeleteObject
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - invisible solid blocks
; ---------------------------------------------------------------------------
Map_obj71:
	include "_maps\obj71.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 64 - bubbles (LZ)
; ---------------------------------------------------------------------------

Obj64:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj64_Index(pc,d0.w),d1
		jmp	Obj64_Index(pc,d1.w)
; ===========================================================================
Obj64_Index:	dc.w Obj64_Main-Obj64_Index
		dc.w Obj64_Animate-Obj64_Index
		dc.w Obj64_ChkWater-Obj64_Index
		dc.w Obj64_Display2-Obj64_Index
		dc.w Obj64_Delete3-Obj64_Index
		dc.w Obj64_BblMaker-Obj64_Index
; ===========================================================================

Obj64_Main:				; XREF: Obj64_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj64,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	$28(a0),d0	; get object type
		bpl.s	Obj64_Bubble	; if type is $0-$7F, branch
		addq.b	#8,$24(a0)
		andi.w	#$7F,d0		; read only last 7 bits	(deduct	$80)
		move.b	d0,$32(a0)
		move.b	d0,$33(a0)
		move.b	#6,$1C(a0)
		bra.w	Obj64_BblMaker
; ===========================================================================

Obj64_Bubble:				; XREF: Obj64_Main
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#-$88,$12(a0)	; float	bubble upwards
		jsr	(RandomNumber).l
		move.b	d0,$26(a0)

Obj64_Animate:				; XREF: Obj64_Index
		lea	(Ani_obj64).l,a1
		jsr	Actor_Animate
		cmpi.b	#6,$1A(a0)
		bne.s	Obj64_ChkWater
		move.b	#1,$2E(a0)

Obj64_ChkWater:				; XREF: Obj64_Index
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; is bubble underwater?
		bcs.s	Obj64_Wobble	; if yes, branch

Obj64_Burst:				; XREF: Obj64_Wobble
		move.b	#6,$24(a0)
		addq.b	#3,$1C(a0)	; run "bursting" animation
		bra.w	Obj64_Display2
; ===========================================================================

Obj64_Wobble:				; XREF: Obj64_ChkWater
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0
		lea	(Obj0A_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)	; change bubble's horizontal position
		tst.b	$2E(a0)
		beq.s	Obj64_Display
		bsr.w	Obj64_ChkSonic	; has Sonic touched the	bubble?
		beq.s	Obj64_Display	; if not, branch

		bsr.w	ResumeMusic	; cancel countdown music
		move.w	#$AD,d0
		jsr	(Sound_CueSFX).l ;	play collecting	bubble sound
		lea	($FFFFD000).w,a1
		clr.w	$10(a1)
		clr.w	$12(a1)
		clr.w	$14(a1)
		move.b	#$15,$1C(a1)
		move.w	#$23,$3E(a1)
		move.b	#0,$3C(a1)
		bclr	#5,$22(a1)
		bclr	#4,$22(a1)
		btst	#2,$22(a1)
		beq.w	Obj64_Burst
		bclr	#2,$22(a1)
		move.b	#$13,$16(a1)
		move.b	#9,$17(a1)
		subq.w	#5,$C(a1)
		bra.w	Obj64_Burst
; ===========================================================================

Obj64_Display:				; XREF: Obj64_Wobble
		bsr.w	SpeedToPos
		tst.b	1(a0)
		bpl.s	Obj64_Delete
		jmp	Actor_Display
; ===========================================================================

Obj64_Delete:
		jmp	DeleteObject
; ===========================================================================

Obj64_Display2:				; XREF: Obj64_Index
		lea	(Ani_obj64).l,a1
		jsr	Actor_Animate
		tst.b	1(a0)
		bpl.s	Obj64_Delete2
		jmp	Actor_Display
; ===========================================================================

Obj64_Delete2:
		jmp	DeleteObject
; ===========================================================================

Obj64_Delete3:				; XREF: Obj64_Index
		bra.w	DeleteObject
; ===========================================================================

Obj64_BblMaker:				; XREF: Obj64_Index
		tst.w	$36(a0)
		bne.s	loc_12874
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; is bubble maker underwater?
		bcc.w	Obj64_ChkDel	; if not, branch
		tst.b	1(a0)
		bpl.w	Obj64_ChkDel
		subq.w	#1,$38(a0)
		bpl.w	loc_12914
		move.w	#1,$36(a0)

loc_1283A:
		jsr	(RandomNumber).l
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0
		bcc.s	loc_1283A

		move.b	d0,$34(a0)
		andi.w	#$C,d1
		lea	(Obj64_BblTypes).l,a1
		adda.w	d1,a1
		move.l	a1,$3C(a0)
		subq.b	#1,$32(a0)
		bpl.s	loc_12872
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)

loc_12872:
		bra.s	loc_1287C
; ===========================================================================

loc_12874:				; XREF: Obj64_BblMaker
		subq.w	#1,$38(a0)
		bpl.w	loc_12914

loc_1287C:
		jsr	(RandomNumber).l
		andi.w	#$1F,d0
		move.w	d0,$38(a0)
		bsr.w	SingleObjLoad
		bne.s	loc_128F8
		move.b	#$64,0(a1)	; load bubble object
		move.w	8(a0),8(a1)
		jsr	(RandomNumber).l
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,8(a1)
		move.w	$C(a0),$C(a1)
		moveq	#0,d0
		move.b	$34(a0),d0
		movea.l	$3C(a0),a2
		move.b	(a2,d0.w),$28(a1)
		btst	#7,$36(a0)
		beq.s	loc_128F8
		jsr	(RandomNumber).l
		andi.w	#3,d0
		bne.s	loc_128E4
		bset	#6,$36(a0)
		bne.s	loc_128F8
		move.b	#2,$28(a1)

loc_128E4:
		tst.b	$34(a0)
		bne.s	loc_128F8
		bset	#6,$36(a0)
		bne.s	loc_128F8
		move.b	#2,$28(a1)

loc_128F8:
		subq.b	#1,$34(a0)
		bpl.s	loc_12914
		jsr	(RandomNumber).l
		andi.w	#$7F,d0
		addi.w	#$80,d0
		add.w	d0,$38(a0)
		clr.w	$36(a0)

loc_12914:
		lea	(Ani_obj64).l,a1
		jsr	Actor_Animate

Obj64_ChkDel:				; XREF: Obj64_BblMaker
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	DeleteObject
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0
		bcs.w	Actor_Display
		rts	
; ===========================================================================
; bubble production sequence

; 0 = small bubble, 1 =	large bubble

Obj64_BblTypes:	dc.b 0,	1, 0, 0, 0, 0, 1, 0, 0,	0, 0, 1, 0, 1, 0, 0, 1,	0

; ===========================================================================

Obj64_ChkSonic:				; XREF: Obj64_Wobble
		tst.b	(plyr_ignore).w
		bmi.s	loc_12998
		lea	($FFFFD000).w,a1
		move.w	8(a1),d0
		move.w	8(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bcc.s	loc_12998
		addi.w	#$20,d1
		cmp.w	d0,d1
		bcs.s	loc_12998
		move.w	$C(a1),d0
		move.w	$C(a0),d1
		cmp.w	d0,d1
		bcc.s	loc_12998
		addi.w	#$10,d1
		cmp.w	d0,d1
		bcs.s	loc_12998
		moveq	#1,d0
		rts	
; ===========================================================================

loc_12998:
		moveq	#0,d0
		rts	
; ===========================================================================
Ani_obj64:
	include "_anim\obj64.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - bubbles (LZ)
; ---------------------------------------------------------------------------
Map_obj64:
	include "_maps\obj64.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 01 - Sonic
; ---------------------------------------------------------------------------

Obj01:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj01_Index(pc,d0.w),d1
		jmp	Obj01_Index(pc,d1.w)
; ===========================================================================
Obj01_Index:	dc.w Obj01_Main-Obj01_Index
		dc.w Obj01_Control-Obj01_Index
		dc.w Obj01_Hurt-Obj01_Index
		dc.w Obj01_Death-Obj01_Index
		dc.w Obj01_ResetLevel-Obj01_Index
		dc.w Sonic_Drowned-Obj01_Index
; ===========================================================================

Obj01_Main:				; XREF: Obj01_Index
		move.b	#$00,($FFFFFFF7).w			; MJ: set collision to 1st
		addq.b	#2,$24(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.l	#Map_Sonic,4(a0)
		move.w	#$780,2(a0)
		move.b	#2,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#4,1(a0)
		move.w	#$600,($FFFFF760).w ; Sonic's top speed
		move.w	#$C,($FFFFF762).w ; Sonic's acceleration
		move.w	#$80,($FFFFF764).w ; Sonic's deceleration

Obj01_Control:				; XREF: Obj01_Index
		tst.b	(jpad_ignore).w	; are controls locked?
		bne.s	loc_12C64	; if yes, branch
		move.w	(jpad_held).w,(plyr_btnheld).w ; enable joypad control

loc_12C64:
		btst	#0,(plyr_ignore).w ; are controls	locked?
		bne.s	loc_12C7E	; if yes, branch
		moveq	#0,d0
		move.b	$22(a0),d0
		andi.w	#6,d0
		move.w	Obj01_Modes(pc,d0.w),d1
		jsr	Obj01_Modes(pc,d1.w)

loc_12C7E:
		bsr.s	Sonic_Display
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Water
		move.b	(plyr_angle).w,$36(a0)
		move.b	(plyr_angle+2).w,$37(a0)
		bsr.w	Sonic_Animate
		tst.b	(plyr_ignore).w
		bmi.s	loc_12CB6
		jsr	TouchResponse

loc_12CB6:
		bsr.w	LoadSonicDynPLC
		rts	
; ===========================================================================
Obj01_Modes:	dc.w Obj01_MdNormal-Obj01_Modes
		dc.w Obj01_MdJump-Obj01_Modes
		dc.w Obj01_MdRoll-Obj01_Modes
		dc.w Obj01_MdJump2-Obj01_Modes
; ===========================================================================

Sonic_Display:				; XREF: loc_12C7E
		move.w	$30(a0),d0
		beq.s	Obj01_Display
		subq.w	#1,$30(a0)
		lsr.w	#3,d0
		bcc.s	Obj01_ChkInvin

Obj01_Display:
		jsr	Actor_Display

Obj01_ChkInvin:
		tst.b	(plyr_invincflag).w	; does Sonic have invincibility?
		beq.s	Obj01_ChkShoes	; if not, branch
		tst.w	$32(a0)		; check	time remaining for invinciblity
		beq.s	Obj01_ChkShoes	; if no	time remains, branch
		subq.w	#1,$32(a0)	; subtract 1 from time
		bne.s	Obj01_ChkShoes
		tst.b	($FFFFF7AA).w
		bne.s	Obj01_RmvInvin
		cmpi.w	#$C,($FFFFFE14).w
		bcs.s	Obj01_RmvInvin
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		cmpi.w	#$103,(lvl_id).w ; check if level is	SBZ3
		bne.s	Obj01_PlayMusic
		moveq	#5,d0		; play SBZ music

Obj01_PlayMusic:
		lea	(MusicList).l,a1
		move.b	(a1,d0.w),d0
		jsr	(Sound_CueMusic).l	; play normal music

Obj01_RmvInvin:
		move.b	#0,(plyr_invincflag).w ; cancel invincibility

Obj01_ChkShoes:
		tst.b	(plyr_speedflag).w	; does Sonic have speed	shoes?
		beq.s	Obj01_ExitChk	; if not, branch
		tst.w	$34(a0)		; check	time remaining
		beq.s	Obj01_ExitChk
		subq.w	#1,$34(a0)	; subtract 1 from time
		bne.s	Obj01_ExitChk
		move.w	#$600,($FFFFF760).w ; restore Sonic's speed
		move.w	#$C,($FFFFF762).w ; restore Sonic's acceleration
		move.w	#$80,($FFFFF764).w ; restore Sonic's deceleration
		move.b	#0,(plyr_speedflag).w ; cancel speed	shoes
		move.w	#$E3,d0
		jmp	(Sound_CueMusic).l	; run music at normal speed
; ===========================================================================

Obj01_ExitChk:
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	record Sonic's previous positions for invincibility stars
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RecordPos:			; XREF: loc_12C7E; Obj01_Hurt; Obj01_Death
		move.w	($FFFFF7A8).w,d0
		lea	(plyr_prevposarr).w,a1
		lea	(a1,d0.w),a1
		move.w	8(a0),(a1)+
		move.w	$C(a0),(a1)+
		addq.b	#4,($FFFFF7A9).w
		rts	
; End of function Sonic_RecordPos

; ---------------------------------------------------------------------------
; Subroutine for Sonic when he's underwater
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Water:				; XREF: loc_12C7E
		cmpi.b	#1,(lvl_id).w ; is level LZ?
		beq.s	Obj01_InWater	; if yes, branch

locret_12D80:
		rts	
; ===========================================================================

Obj01_InWater:
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; is Sonic above the water?
		bge.s	Obj01_OutWater	; if yes, branch
		bset	#6,$22(a0)
		bne.s	locret_12D80
		bsr.w	ResumeMusic
		move.b	#$A,($FFFFD340).w ; load bubbles object	from Sonic's mouth
		move.b	#$81,($FFFFD368).w
		move.w	#$300,($FFFFF760).w ; change Sonic's top speed
		move.w	#6,($FFFFF762).w ; change Sonic's acceleration
		move.w	#$40,($FFFFF764).w ; change Sonic's deceleration
		asr	$10(a0)
		asr	$12(a0)
		asr	$12(a0)
		beq.s	locret_12D80
		move.b	#8,($FFFFD300).w ; load	splash object
		move.w	#$AA,d0
		jmp	(Sound_CueSFX).l ;	play splash sound
; ===========================================================================

Obj01_OutWater:
		bclr	#6,$22(a0)
		beq.s	locret_12D80
		bsr.w	ResumeMusic
		move.w	#$600,($FFFFF760).w ; restore Sonic's speed
		move.w	#$C,($FFFFF762).w ; restore Sonic's acceleration
		move.w	#$80,($FFFFF764).w ; restore Sonic's deceleration
		asl	$12(a0)
		beq.w	locret_12D80
		move.b	#8,($FFFFD300).w ; load	splash object
		cmpi.w	#-$1000,$12(a0)
		bgt.s	loc_12E0E
		move.w	#-$1000,$12(a0)	; set maximum speed on leaving water

loc_12E0E:
		move.w	#$AA,d0
		jmp	(Sound_CueSFX).l ;	play splash sound
; End of function Sonic_Water

; ===========================================================================
; ---------------------------------------------------------------------------
; Modes	for controlling	Sonic
; ---------------------------------------------------------------------------

Obj01_MdNormal:				; XREF: Obj01_Modes
		bsr.w	Sonic_Jump
		bsr.w	Sonic_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	Sonic_Roll
		bsr.w	Sonic_LevelBound
		jsr	SpeedToPos
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts	
; ===========================================================================

Obj01_MdJump:				; XREF: Obj01_Modes
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Sonic_LevelBound
		jsr	ObjectFall
		btst	#6,$22(a0)
		beq.s	loc_12E5C
		subi.w	#$28,$12(a0)

loc_12E5C:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts	
; ===========================================================================

Obj01_MdRoll:				; XREF: Obj01_Modes
		bsr.w	Sonic_Jump
		bsr.w	Sonic_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Sonic_LevelBound
		jsr	SpeedToPos
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts	
; ===========================================================================

Obj01_MdJump2:				; XREF: Obj01_Modes
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_ChgJumpDir
		bsr.w	Sonic_LevelBound
		jsr	ObjectFall
		btst	#6,$22(a0)
		beq.s	loc_12EA6
		subi.w	#$28,$12(a0)

loc_12EA6:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	make Sonic walk/run
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Move:				; XREF: Obj01_MdNormal
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		move.w	($FFFFF764).w,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_12FEE
		tst.w	$3E(a0)
		bne.w	Obj01_ResetScr
		btst	#2,(plyr_btnheld).w ; is left being pressed?
		beq.s	Obj01_NotLeft	; if not, branch
		bsr.w	Sonic_MoveLeft

Obj01_NotLeft:
		btst	#3,(plyr_btnheld).w ; is right being pressed?
		beq.s	Obj01_NotRight	; if not, branch
		bsr.w	Sonic_MoveRight

Obj01_NotRight:
		move.b	$26(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0		; is Sonic on a	slope?
		bne.w	Obj01_ResetScr	; if yes, branch
		tst.w	$14(a0)		; is Sonic moving?
		bne.w	Obj01_ResetScr	; if yes, branch
		bclr	#5,$22(a0)
		move.b	#5,$1C(a0)	; use "standing" animation
		btst	#3,$22(a0)
		beq.s	Sonic_Balance
		moveq	#0,d0
		move.b	$3D(a0),d0
		lsl.w	#6,d0
		lea	($FFFFD000).w,a1
		lea	(a1,d0.w),a1
		tst.b	$22(a1)
		bmi.s	Sonic_LookUp
		moveq	#0,d1
		move.b	$19(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	8(a0),d1
		sub.w	8(a1),d1
		cmpi.w	#4,d1
		blt.s	loc_12F6A
		cmp.w	d2,d1
		bge.s	loc_12F5A
		bra.s	Sonic_LookUp
; ===========================================================================

Sonic_Balance:
		jsr	ObjHitFloor
		cmpi.w	#$C,d1
		blt.s	Sonic_LookUp
		cmpi.b	#3,$36(a0)
		bne.s	loc_12F62

loc_12F5A:
		bclr	#0,$22(a0)
		bra.s	loc_12F70
; ===========================================================================

loc_12F62:
		cmpi.b	#3,$37(a0)
		bne.s	Sonic_LookUp

loc_12F6A:
		bset	#0,$22(a0)

loc_12F70:
		move.b	#6,$1C(a0)	; use "balancing" animation
		bra.s	Obj01_ResetScr
; ===========================================================================

Sonic_LookUp:
		btst	#0,(plyr_btnheld).w ; is up being pressed?
		beq.s	Sonic_Duck	; if not, branch
		move.b	#7,$1C(a0)	; use "looking up" animation
		cmpi.w	#$C8,(cam_ypos).w
		beq.s	loc_12FC2
		addq.w	#2,(cam_ypos).w
		bra.s	loc_12FC2
; ===========================================================================

Sonic_Duck:
		btst	#1,(plyr_btnheld).w ; is down being pressed?
		beq.s	Obj01_ResetScr	; if not, branch
		move.b	#8,$1C(a0)	; use "ducking"	animation
		cmpi.w	#8,(cam_ypos).w
		beq.s	loc_12FC2
		subq.w	#2,(cam_ypos).w
		bra.s	loc_12FC2
; ===========================================================================

Obj01_ResetScr:
		cmpi.w	#$60,(cam_ypos).w ; is	screen in its default position?
		beq.s	loc_12FC2	; if yes, branch
		bcc.s	loc_12FBE
		addq.w	#4,(cam_ypos).w ; move	screen back to default

loc_12FBE:
		subq.w	#2,(cam_ypos).w ; move	screen back to default

loc_12FC2:
		move.b	(plyr_btnheld).w,d0
		andi.b	#$C,d0		; is left/right	pressed?
		bne.s	loc_12FEE	; if yes, branch
		move.w	$14(a0),d0
		beq.s	loc_12FEE
		bmi.s	loc_12FE2
		sub.w	d5,d0
		bcc.s	loc_12FDC
		move.w	#0,d0

loc_12FDC:
		move.w	d0,$14(a0)
		bra.s	loc_12FEE
; ===========================================================================

loc_12FE2:
		add.w	d5,d0
		bcc.s	loc_12FEA
		move.w	#0,d0

loc_12FEA:
		move.w	d0,$14(a0)

loc_12FEE:
		move.b	$26(a0),d0
		jsr	(Math_GetSine).l
		muls.w	$14(a0),d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)

loc_1300C:
		move.b	$26(a0),d0
		addi.b	#$40,d0
		bmi.s	locret_1307C
		move.b	#$40,d1
		tst.w	$14(a0)
		beq.s	locret_1307C
		bmi.s	loc_13024
		neg.w	d1

loc_13024:
		move.b	$26(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	Sonic_WalkSpeed
		move.w	(sp)+,d0
		tst.w	d1
		bpl.s	locret_1307C
		asl.w	#8,d1
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	loc_13078
		cmpi.b	#$40,d0
		beq.s	loc_13066
		cmpi.b	#$80,d0
		beq.s	loc_13060
		add.w	d1,$10(a0)
		bset	#5,$22(a0)
		move.w	#0,$14(a0)
		rts	
; ===========================================================================

loc_13060:
		sub.w	d1,$12(a0)
		rts	
; ===========================================================================

loc_13066:
		sub.w	d1,$10(a0)
		bset	#5,$22(a0)
		move.w	#0,$14(a0)
		rts	
; ===========================================================================

loc_13078:
		add.w	d1,$12(a0)

locret_1307C:
		rts	
; End of function Sonic_Move


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_MoveLeft:		   ; XREF: Sonic_Move
		move.w	$14(a0),d0
		beq.s	loc_13086
		bpl.s	loc_130B2

loc_13086:
		bset	#0,$22(a0)
		bne.s	loc_1309A
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)

loc_1309A:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.s	loc_130A6
		add.w	d5,d0
		cmp.w	d1,d0
		ble.s	loc_130A6
		move.w	d1,d0

loc_130A6:
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0); use walking animation
		rts
; ===========================================================================

loc_130B2:				; XREF: Sonic_MoveLeft
		sub.w	d4,d0
		bcc.s	loc_130BA
		move.w	#-$80,d0

loc_130BA:
		move.w	d0,$14(a0)
		move.b	$26(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.s	locret_130E8
		cmpi.w	#$400,d0
		blt.s	locret_130E8
		move.b	#$D,$1C(a0)	; use "stopping" animation
		bclr	#0,$22(a0)
		move.w	#$A4,d0
		jsr	(Sound_CueSFX).l ;	play stopping sound

locret_130E8:
		rts	
; End of function Sonic_MoveLeft


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_MoveRight:	   ; XREF: Sonic_Move
		move.w	$14(a0),d0
		bmi.s	loc_13118
		bclr	#0,$22(a0)
		beq.s	loc_13104
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)

loc_13104:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.s	loc_1310C
		sub.w	d5,d0
		cmp.w	d6,d0
		bge.s	loc_1310C
		move.w	d6,d0

loc_1310C:
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0); use walking animation
		rts
; ===========================================================================

loc_13118:				; XREF: Sonic_MoveRight
		add.w	d4,d0
		bcc.s	loc_13120
		move.w	#$80,d0

loc_13120:
		move.w	d0,$14(a0)
		move.b	$26(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.s	locret_1314E
		cmpi.w	#-$400,d0
		bgt.s	locret_1314E
		move.b	#$D,$1C(a0)	; use "stopping" animation
		bset	#0,$22(a0)
		move.w	#$A4,d0
		jsr	(Sound_CueSFX).l ;	play stopping sound

locret_1314E:
		rts	
; End of function Sonic_MoveRight

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's speed as he rolls
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollSpeed:			; XREF: Obj01_MdRoll
		move.w	($FFFFF760).w,d6
		asl.w	#1,d6
		move.w	($FFFFF762).w,d5
		asr.w	#1,d5
		move.w	($FFFFF764).w,d4
		asr.w	#2,d4
		tst.b	($FFFFF7CA).w
		bne.w	loc_131CC
		tst.w	$3E(a0)
		bne.s	loc_13188
		btst	#2,(plyr_btnheld).w ; is left being pressed?
		beq.s	loc_1317C	; if not, branch
		bsr.w	Sonic_RollLeft

loc_1317C:
		btst	#3,(plyr_btnheld).w ; is right being pressed?
		beq.s	loc_13188	; if not, branch
		bsr.w	Sonic_RollRight

loc_13188:
		move.w	$14(a0),d0
		beq.s	loc_131AA
		bmi.s	loc_1319E
		sub.w	d5,d0
		bcc.s	loc_13198
		move.w	#0,d0

loc_13198:
		move.w	d0,$14(a0)
		bra.s	loc_131AA
; ===========================================================================

loc_1319E:				; XREF: Sonic_RollSpeed
		add.w	d5,d0
		bcc.s	loc_131A6
		move.w	#0,d0

loc_131A6:
		move.w	d0,$14(a0)

loc_131AA:
		tst.w	$14(a0)		; is Sonic moving?
		bne.s	loc_131CC	; if yes, branch
		bclr	#2,$22(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.b	#5,$1C(a0)	; use "standing" animation
		subq.w	#5,$C(a0)

loc_131CC:
		move.b	$26(a0),d0
		jsr	(Math_GetSine).l
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		muls.w	$14(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.s	loc_131F0
		move.w	#$1000,d1

loc_131F0:
		cmpi.w	#-$1000,d1
		bge.s	loc_131FA
		move.w	#-$1000,d1

loc_131FA:
		move.w	d1,$10(a0)
		bra.w	loc_1300C
; End of function Sonic_RollSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollLeft:				; XREF: Sonic_RollSpeed
		move.w	$14(a0),d0
		beq.s	loc_1320A
		bpl.s	loc_13218

loc_1320A:
		bset	#0,$22(a0)
		move.b	#2,$1C(a0)	; use "rolling"	animation
		rts	
; ===========================================================================

loc_13218:
		sub.w	d4,d0
		bcc.s	loc_13220
		move.w	#-$80,d0

loc_13220:
		move.w	d0,$14(a0)
		rts	
; End of function Sonic_RollLeft


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollRight:			; XREF: Sonic_RollSpeed
		move.w	$14(a0),d0
		bmi.s	loc_1323A
		bclr	#0,$22(a0)
		move.b	#2,$1C(a0)	; use "rolling"	animation
		rts	
; ===========================================================================

loc_1323A:
		add.w	d4,d0
		bcc.s	loc_13242
		move.w	#$80,d0

loc_13242:
		move.w	d0,$14(a0)
		rts	
; End of function Sonic_RollRight

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's direction while jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_ChgJumpDir:		; XREF: Obj01_MdJump; Obj01_MdJump2
		move.w	($FFFFF760).w,d6
		move.w	($FFFFF762).w,d5
		asl.w	#1,d5
		btst	#4,$22(a0)	
		bne.s	Obj01_ResetScr2	
		move.w	$10(a0),d0	
		btst	#2,(plyr_btnheld).w; is left being pressed?	
		beq.s	loc_13278; if not, branch	
		bset	#0,$22(a0)	
		sub.w	d5,d0	
		move.w	d6,d1	
		neg.w	d1	
		cmp.w	d1,d0	
		bgt.s	loc_13278	
		add.w	d5,d0		; +++ remove this frame's acceleration change
		cmp.w	d1,d0		; +++ compare speed with top speed
		ble.s	loc_13278	; +++ if speed was already greater than the maximum, branch	
		move.w	d1,d0

loc_13278:
		btst	#3,(plyr_btnheld).w; is right being pressed?	
		beq.s	Obj01_JumpMove; if not, branch	
		bclr	#0,$22(a0)	
		add.w	d5,d0	
		cmp.w	d6,d0	
		blt.s	Obj01_JumpMove
		sub.w	d5,d0		; +++ remove this frame's acceleration change
		cmp.w	d6,d0		; +++ compare speed with top speed
		bge.s	Obj01_JumpMove	; +++ if speed was already greater than the maximum, branch
		move.w	d6,d0

Obj01_JumpMove:
		move.w	d0,$10(a0)	; change Sonic's horizontal speed

Obj01_ResetScr2:
		cmpi.w	#$60,(cam_ypos).w ; is	the screen in its default position?
		beq.s	loc_132A4	; if yes, branch
		bcc.s	loc_132A0
		addq.w	#4,(cam_ypos).w

loc_132A0:
		subq.w	#2,(cam_ypos).w

loc_132A4:
		cmpi.w	#-$400,$12(a0)	; is Sonic moving faster than -$400 upwards?
		bcs.s	locret_132D2	; if yes, branch
		move.w	$10(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.s	locret_132D2
		bmi.s	loc_132C6
		sub.w	d1,d0
		bcc.s	loc_132C0
		move.w	#0,d0

loc_132C0:
		move.w	d0,$10(a0)
		rts	
; ===========================================================================

loc_132C6:
		sub.w	d1,d0
		bcs.s	loc_132CE
		move.w	#0,d0

loc_132CE:
		move.w	d0,$10(a0)

locret_132D2:
		rts	
; End of function Sonic_ChgJumpDir

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	prevent	Sonic leaving the boundaries of	a level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_LevelBound:			; XREF: Obj01_MdNormal; et al
		move.l	8(a0),d1
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	(bound_left).w,d0
		addi.w	#$10,d0
		cmp.w	d1,d0		; has Sonic touched the	side boundary?
		bhi.s	Boundary_Sides	; if yes, branch
		move.w	(bound_right).w,d0
		addi.w	#$128,d0
		tst.b	($FFFFF7AA).w
		bne.s	loc_13332
		addi.w	#$40,d0

loc_13332:
		cmp.w	d1,d0		; has Sonic touched the	side boundary?
		bls.s	Boundary_Sides	; if yes, branch

loc_13336:
		move.w	(bound_down).w,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	; has Sonic touched the	bottom boundary?
		blt.s	Boundary_Bottom	; if yes, branch
		rts	
; ===========================================================================

Boundary_Bottom:
		cmpi.w	#$501,(lvl_id).w ; is level SBZ2 ?
		bne.w	KillSonic	; if not, kill Sonic
		cmpi.w	#$2000,(ACTSLOT_PLAYER+act_xpos).w
		bcs.w	KillSonic
		clr.b	(cp_idx).w	; clear	lamppost counter
		move.w	#1,($FFFFFE02).w ; restart the level
		move.w	#$103,(lvl_id).w ; set level	to SBZ3	(LZ4)
		rts	
; ===========================================================================

Boundary_Sides:
		move.w	d0,8(a0)
		move.w	#0,$A(a0)
		move.w	#0,$10(a0)	; stop Sonic moving
		move.w	#0,$14(a0)
		bra.s	loc_13336
; End of function Sonic_LevelBound

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to roll when he's moving
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Roll:				; XREF: Obj01_MdNormal
		tst.b	($FFFFF7CA).w
		bne.s	Obj01_NoRoll
		move.w	$14(a0),d0
		bpl.s	loc_13392
		neg.w	d0

loc_13392:
		cmpi.w	#$80,d0		; is Sonic moving at $80 speed or faster?
		bcs.s	Obj01_NoRoll	; if not, branch
		move.b	(plyr_btnheld).w,d0
		andi.b	#$C,d0		; is left/right	being pressed?
		bne.s	Obj01_NoRoll	; if yes, branch
		btst	#1,(plyr_btnheld).w ; is down being pressed?
		bne.s	Obj01_ChkRoll	; if yes, branch

Obj01_NoRoll:
		rts	
; ===========================================================================

Obj01_ChkRoll:
		btst	#2,$22(a0)	; is Sonic already rolling?
		beq.s	Obj01_DoRoll	; if not, branch
		rts	
; ===========================================================================

Obj01_DoRoll:
		bset	#2,$22(a0)
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)	; use "rolling"	animation
		addq.w	#5,$C(a0)
		move.w	#$BE,d0
		jsr	(Sound_CueSFX).l ;	play rolling sound
		tst.w	$14(a0)
		bne.s	locret_133E8
		move.w	#$200,$14(a0)

locret_133E8:
		rts	
; End of function Sonic_Roll

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to jump
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Jump:				; XREF: Obj01_MdNormal; Obj01_MdRoll
		move.b	(plyr_btnpress).w,d0
		andi.b	#$70,d0		; is A,	B or C pressed?
		beq.w	locret_1348E	; if not, branch
		moveq	#0,d0
		move.b	$26(a0),d0
		addi.b	#$80,d0
		bsr.w	sub_14D48
		cmpi.w	#6,d1
		blt.w	locret_1348E
		move.w	#$680,d2
		btst	#6,$22(a0)
		beq.s	loc_1341C
		move.w	#$380,d2

loc_1341C:
		moveq	#0,d0
		move.b	$26(a0),d0
		subi.b	#$40,d0
		jsr	(Math_GetSine).l
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,$10(a0)	; make Sonic jump
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,$12(a0)	; make Sonic jump
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		addq.l	#4,sp
		move.b	#1,$3C(a0)
		clr.b	$38(a0)
		move.w	#$A0,d0
		jsr	(Sound_CueSFX).l ;	play jumping sound
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		btst	#2,$22(a0)
		bne.s	loc_13490
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.b	#2,$1C(a0)	; use "jumping"	animation
		bset	#2,$22(a0)
		addq.w	#5,$C(a0)

locret_1348E:
		rts	
; ===========================================================================

loc_13490:
		bset	#4,$22(a0)
		rts	
; End of function Sonic_Jump


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_JumpHeight:			; XREF: Obj01_MdJump; Obj01_MdJump2
		tst.b	$3C(a0)
		beq.s	loc_134C4
		move.w	#-$400,d1
		btst	#6,$22(a0)
		beq.s	loc_134AE
		move.w	#-$200,d1

loc_134AE:
		cmp.w	$12(a0),d1
		ble.s	locret_134C2
		move.b	(plyr_btnheld).w,d0
		andi.b	#$70,d0		; is A,	B or C pressed?
		bne.s	locret_134C2	; if yes, branch
		move.w	d1,$12(a0)

locret_134C2:
		rts	
; ===========================================================================

loc_134C4:
		cmpi.w	#-$FC0,$12(a0)
		bge.s	locret_134D2
		move.w	#-$FC0,$12(a0)

locret_134D2:
		rts	
; End of function Sonic_JumpHeight

; ---------------------------------------------------------------------------
; Subroutine to	slow Sonic walking up a	slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_SlopeResist:			; XREF: Obj01_MdNormal
		move.b	$26(a0),d0
		addi.b	#$60,d0
		cmpi.b	#$C0,d0
		bcc.s	locret_13508
		move.b	$26(a0),d0
		jsr	(Math_GetSine).l
		muls.w	#$20,d0
		asr.l	#8,d0
		tst.w	$14(a0)
		beq.s	locret_13508
		bmi.s	loc_13504
		tst.w	d0
		beq.s	locret_13502
		add.w	d0,$14(a0)	; change Sonic's inertia

locret_13502:
		rts	
; ===========================================================================

loc_13504:
		add.w	d0,$14(a0)

locret_13508:
		rts	
; End of function Sonic_SlopeResist

; ---------------------------------------------------------------------------
; Subroutine to	push Sonic down	a slope	while he's rolling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_RollRepel:			; XREF: Obj01_MdRoll
		move.b	$26(a0),d0
		addi.b	#$60,d0
		cmpi.b	#-$40,d0
		bcc.s	locret_13544
		move.b	$26(a0),d0
		jsr	(Math_GetSine).l
		muls.w	#$50,d0
		asr.l	#8,d0
		tst.w	$14(a0)
		bmi.s	loc_1353A
		tst.w	d0
		bpl.s	loc_13534
		asr.l	#2,d0

loc_13534:
		add.w	d0,$14(a0)
		rts	
; ===========================================================================

loc_1353A:
		tst.w	d0
		bmi.s	loc_13540
		asr.l	#2,d0

loc_13540:
		add.w	d0,$14(a0)

locret_13544:
		rts	
; End of function Sonic_RollRepel

; ---------------------------------------------------------------------------
; Subroutine to	push Sonic down	a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_SlopeRepel:			; XREF: Obj01_MdNormal; Obj01_MdRoll
		nop	
		tst.b	$38(a0)
		bne.s	locret_13580
		tst.w	$3E(a0)
		bne.s	loc_13582
		move.b	$26(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.s	locret_13580
		move.w	$14(a0),d0
		bpl.s	loc_1356A
		neg.w	d0

loc_1356A:
		cmpi.w	#$280,d0
		bcc.s	locret_13580
		clr.w	$14(a0)
		bset	#1,$22(a0)
		move.w	#$1E,$3E(a0)

locret_13580:
		rts	
; ===========================================================================

loc_13582:
		subq.w	#1,$3E(a0)
		rts	
; End of function Sonic_SlopeRepel

; ---------------------------------------------------------------------------
; Subroutine to	return Sonic's angle to 0 as he jumps
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_JumpAngle:			; XREF: Obj01_MdJump; Obj01_MdJump2
		move.b	$26(a0),d0	; get Sonic's angle
		beq.s	locret_135A2	; if already 0,	branch
		bpl.s	loc_13598	; if higher than 0, branch

		addq.b	#2,d0		; increase angle
		bcc.s	loc_13596
		moveq	#0,d0

loc_13596:
		bra.s	loc_1359E
; ===========================================================================

loc_13598:
		subq.b	#2,d0		; decrease angle
		bcc.s	loc_1359E
		moveq	#0,d0

loc_1359E:
		move.b	d0,$26(a0)

locret_135A2:
		rts	
; End of function Sonic_JumpAngle

; ---------------------------------------------------------------------------
; Subroutine for Sonic to interact with	the floor after	jumping/falling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Floor:				; XREF: Obj01_MdJump; Obj01_MdJump2
		move.w	$10(a0),d1
		move.w	$12(a0),d2
		jsr	(CalcAngle).l
		move.b	d0,($FFFFFFEC).w
		subi.b	#$20,d0
		move.b	d0,($FFFFFFED).w
		andi.b	#$C0,d0
		move.b	d0,($FFFFFFEE).w
		cmpi.b	#$40,d0
		beq.w	loc_13680
		cmpi.b	#$80,d0
		beq.w	loc_136E2
		cmpi.b	#-$40,d0
		beq.w	loc_1373E
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_135F0
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_135F0:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13602
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_13602:
		bsr.w	Sonic_HitFloor
		move.b	d1,($FFFFFFEF).w
		tst.w	d1
		bpl.s	locret_1367E
		move.b	$12(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.s	loc_1361E
		cmp.b	d2,d0
		blt.s	locret_1367E

loc_1361E:
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,$1C(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_1365C
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0
		beq.s	loc_1364E
		asr	$12(a0)
		bra.s	loc_13670
; ===========================================================================

loc_1364E:
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)
		rts	
; ===========================================================================

loc_1365C:
		move.w	#0,$10(a0)
		cmpi.w	#$FC0,$12(a0)
		ble.s	loc_13670
		move.w	#$FC0,$12(a0)

loc_13670:
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.s	locret_1367E
		neg.w	$14(a0)

locret_1367E:
		rts	
; ===========================================================================

loc_13680:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_1369A
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts	
; ===========================================================================

loc_1369A:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_136B4
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.s	locret_136B2
		move.w	#0,$12(a0)

locret_136B2:
		rts	
; ===========================================================================

loc_136B4:
		tst.w	$12(a0)
		bmi.s	locret_136E0
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.s	locret_136E0
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_136E0:
		rts	
; ===========================================================================

loc_136E2:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.s	loc_136F4
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_136F4:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13706
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_13706:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	locret_1373C
		sub.w	d1,$C(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.s	loc_13726
		move.w	#0,$12(a0)
		rts	
; ===========================================================================

loc_13726:
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.s	locret_1373C
		neg.w	$14(a0)

locret_1373C:
		rts	
; ===========================================================================

loc_1373E:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.s	loc_13758
		add.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts	
; ===========================================================================

loc_13758:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.s	loc_13772
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.s	locret_13770
		move.w	#0,$12(a0)

locret_13770:
		rts	
; ===========================================================================

loc_13772:
		tst.w	$12(a0)
		bmi.s	locret_1379E
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.s	locret_1379E
		add.w	d1,$C(a0)
		move.b	d3,$26(a0)
		bsr.w	Sonic_ResetOnFloor
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_1379E:
		rts	
; End of function Sonic_Floor

; ---------------------------------------------------------------------------
; Subroutine to	reset Sonic's mode when he lands on the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_ResetOnFloor:			; XREF: PlatformObject; et al
		btst	#4,$22(a0)
		beq.s	loc_137AE
		nop	
		nop	
		nop	

loc_137AE:
		bclr	#5,$22(a0)
		bclr	#1,$22(a0)
		bclr	#4,$22(a0)
		btst	#2,$22(a0)
		beq.s	loc_137E4
		bclr	#2,$22(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.b	#0,$1C(a0)	; use running/walking animation
		subq.w	#5,$C(a0)

loc_137E4:
		move.b	#0,$3C(a0)
		move.w	#0,($FFFFF7D0).w
		rts	
; End of function Sonic_ResetOnFloor

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when he	gets hurt
; ---------------------------------------------------------------------------

Obj01_Hurt:				; XREF: Obj01_Index
		jsr	SpeedToPos
		addi.w	#$30,$12(a0)
		btst	#6,$22(a0)
		beq.s	loc_1380C
		subi.w	#$20,$12(a0)

loc_1380C:
		bsr.w	Sonic_HurtStop
		bsr.w	Sonic_LevelBound
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Water
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	Actor_Display

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic falling after he's been hurt
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HurtStop:				; XREF: Obj01_Hurt
		move.w	(bound_down).w,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0
		bcs.w	KillSonic
		bsr.w	Sonic_Floor
		btst	#1,$22(a0)
		bne.s	locret_13860
		moveq	#0,d0
		move.w	d0,$12(a0)
		move.w	d0,$10(a0)
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)
		subq.b	#2,$24(a0)
		move.w	#$78,$30(a0)

locret_13860:
		rts	
; End of function Sonic_HurtStop

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when he	dies
; ---------------------------------------------------------------------------

Obj01_Death:				; XREF: Obj01_Index
		bsr.w	GameOver
		jsr	ObjectFall
		bsr.w	Sonic_RecordPos
		bsr.w	Sonic_Animate
		bsr.w	LoadSonicDynPLC
		jmp	Actor_Display

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


GameOver:				; XREF: Obj01_Death
		move.w	(lvl_fgypos).w,d0
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bge.w	locret_13900
		move.w	#-$38,$12(a0)
		addq.b	#2,$24(a0)
		clr.b	($FFFFFE1E).w	; stop time counter
		addq.b	#1,($FFFFFE1C).w ; update lives	counter
		subq.b	#1,($FFFFFE12).w ; subtract 1 from number of lives
		bne.s	loc_138D4
		move.w	#0,$3A(a0)
		move.b	#$39,($FFFFD080).w ; load GAME object
		move.b	#$39,($FFFFD0C0).w ; load OVER object
		move.b	#1,($FFFFD0DA).w ; set OVER object to correct frame
		clr.b	(plyr_air).w

loc_138C2:
		move.w	#$8F,d0
		jsr	(Sound_CueMusic).l	; play game over music
		moveq	#3,d0
		jmp	(LoadPLC).l	; load game over patterns
; ===========================================================================

loc_138D4:
		move.w	#60,$3A(a0)	; set time delay to 1 second
		tst.b	(plyr_air).w	; is TIME OVER tag set?
		beq.s	locret_13900	; if not, branch
		move.w	#0,$3A(a0)
		move.b	#$39,($FFFFD080).w ; load TIME object
		move.b	#$39,($FFFFD0C0).w ; load OVER object
		move.b	#2,($FFFFD09A).w
		move.b	#3,($FFFFD0DA).w
		bra.s	loc_138C2
; ===========================================================================

locret_13900:
		rts	
; End of function GameOver

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when the level is restarted
; ---------------------------------------------------------------------------

Obj01_ResetLevel:			; XREF: Obj01_Index
		tst.w	$3A(a0)
		beq.s	locret_13914
		subq.w	#1,$3A(a0)	; subtract 1 from time delay
		bne.s	locret_13914
		move.w	#1,($FFFFFE02).w ; restart the level

locret_13914:
		rts	

; ---------------------------------------------------------------------------
; Sonic when he's drowning
; ---------------------------------------------------------------------------
 
; ||||||||||||||| S	U B	R O	U T	I N	E |||||||||||||||||||||||||||||||||||||||
 
 
Sonic_Drowned:
		bsr.w   SpeedToPos		; Make Sonic able to move
		addi.w  #$10,$12(a0)	; Apply gravity
		bsr.w   Sonic_RecordPos	; Record position
		bsr.s   Sonic_Animate	; Animate Sonic
		bsr.w   LoadSonicDynPLC	; Load Sonic's DPLCs
		bra.w   Actor_Display	; And finally, display Sonic

; ---------------------------------------------------------------------------
; Subroutine to	animate	Sonic's sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Animate:				; XREF: Obj01_Control; et al
		lea	(SonicAniData).l,a1
		moveq	#0,d0
		move.b	$1C(a0),d0
		cmp.b	$1D(a0),d0	; is animation set to restart?
		beq.s	SAnim_Do	; if not, branch
		move.b	d0,$1D(a0)	; set to "no restart"
		move.b	#0,$1B(a0)	; reset	animation
		move.b	#0,$1E(a0)	; reset	frame duration

SAnim_Do:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation	script
		move.b	(a1),d0
		bmi.s	SAnim_WalkRun	; if animation is walk/run/roll/jump, branch
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	SAnim_Delay	; if time remains, branch
		move.b	d0,$1E(a0)	; load frame duration

SAnim_Do2:
		moveq	#0,d1
		move.b	$1B(a0),d1	; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		cmp.b	#$FD,d0					; MJ: is it a flag from FD to FF?
		bhs	SAnim_End_FF				; MJ: if so, branch to flag routines

SAnim_Next:
		move.b	d0,$1A(a0)	; load sprite number
		addq.b	#1,$1B(a0)	; next frame number

SAnim_Delay:
		rts	
; ===========================================================================

SAnim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF	?
		bne.s	SAnim_End_FE	; if not, branch
		move.b	#0,$1B(a0)	; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.s	SAnim_Next
; ===========================================================================

SAnim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE	?
		bne.s	SAnim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next	byte in	the script
		sub.b	d0,$1B(a0)	; jump back d0 bytes in	the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.s	SAnim_Next
; ===========================================================================

SAnim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD	?
		bne.s	SAnim_End	; if not, branch
		move.b	2(a1,d1.w),$1C(a0) ; read next byte, run that animation

SAnim_End:
		rts	
; ===========================================================================

SAnim_WalkRun:				; XREF: SAnim_Do
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.s	SAnim_Delay	; if time remains, branch
		addq.b	#1,d0		; is animation walking/running?
		bne.w	SAnim_RollJump	; if not, branch
		moveq	#0,d1
		move.b	$26(a0),d0	; get Sonic's angle
		move.b	$22(a0),d2
		andi.b	#1,d2		; is Sonic mirrored horizontally?
		bne.s	loc_13A70	; if yes, branch
		not.b	d0		; reverse angle

loc_13A70:
		addi.b	#$10,d0		; add $10 to angle
		bpl.s	loc_13A78	; if angle is $0-$7F, branch
		moveq	#3,d1

loc_13A78:
		andi.b	#$FC,1(a0)
		eor.b	d1,d2
		or.b	d2,1(a0)
		btst	#5,$22(a0)
		bne.w	SAnim_Push
		lsr.b	#4,d0		; divide angle by $10
		andi.b	#6,d0		; angle	must be	0, 2, 4	or 6
		move.w	$14(a0),d2	; get Sonic's speed
		bpl.s	loc_13A9C
		neg.w	d2

loc_13A9C:
		lea	(SonAni_Run).l,a1 ; use	running	animation
		cmpi.w	#$600,d2	; is Sonic at running speed?
		bcc.s	loc_13AB4	; if yes, branch
		lea	(SonAni_Walk).l,a1 ; use walking animation
		move.b	d0,d1
		lsr.b	#1,d1
		add.b	d1,d0

loc_13AB4:
		add.b	d0,d0
		move.b	d0,d3
		neg.w	d2
		addi.w	#$800,d2
		bpl.s	loc_13AC2
		moveq	#0,d2

loc_13AC2:
		lsr.w	#8,d2
		move.b	d2,$1E(a0)	; modify frame duration
		bsr.w	SAnim_Do2
		add.b	d3,$1A(a0)	; modify frame number
		rts	
; ===========================================================================

SAnim_RollJump:				; XREF: SAnim_WalkRun
		addq.b	#1,d0		; is animation rolling/jumping?
		bne.s	SAnim_Push	; if not, branch
		move.w	$14(a0),d2	; get Sonic's speed
		bpl.s	loc_13ADE
		neg.w	d2

loc_13ADE:
		lea	(SonAni_Roll2).l,a1 ; use fast animation
		cmpi.w	#$600,d2	; is Sonic moving fast?
		bcc.s	loc_13AF0	; if yes, branch
		lea	(SonAni_Roll).l,a1 ; use slower	animation

loc_13AF0:
		neg.w	d2
		addi.w	#$400,d2
		bpl.s	loc_13AFA
		moveq	#0,d2

loc_13AFA:
		lsr.w	#8,d2
		move.b	d2,$1E(a0)	; modify frame duration
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	SAnim_Do2
; ===========================================================================

SAnim_Push:				; XREF: SAnim_RollJump
		move.w	$14(a0),d2	; get Sonic's speed
		bmi.s	loc_13B1E
		neg.w	d2

loc_13B1E:
		addi.w	#$800,d2
		bpl.s	loc_13B26
		moveq	#0,d2

loc_13B26:
		lsr.w	#6,d2
		move.b	d2,$1E(a0)	; modify frame duration
		lea	(SonAni_Push).l,a1
		move.b	$22(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	SAnim_Do2
; End of function Sonic_Animate

; ===========================================================================
SonicAniData:
	include "Action Stage/Global/Actors/Players/Sonic Animations.asm"

; ---------------------------------------------------------------------------
; Sonic	pattern	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadSonicDynPLC:			; XREF: Obj01_Control; et al
		moveq	#0,d0
		move.b	$1A(a0),d0	; load frame number
		cmp.b	($FFFFF766).w,d0
		beq.s	locret_13C96
		move.b	d0,($FFFFF766).w
		lea	(SonicDynPLC).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1	; read "number of entries" value
		subq.b	#1,d1
		bmi.s	locret_13C96
		lea	($FFFFC800).w,a3
		move.b	#1,($FFFFF767).w

SPLC_ReadEntry:
		moveq	#0,d2
		move.b	(a2)+,d2
		move.w	d2,d0
		lsr.b	#4,d0
		lsl.w	#8,d2
		move.b	(a2)+,d2
		andi.w	#$0FFF,d2				; MJ: clear the counter
		lsl.l	#5,d2					; MJ: shifting long-word instead of word (more than FFFF bytes)
		lea	(Art_Sonic).l,a1
		adda.l	d2,a1

SPLC_LoadTile:
		movem.l	(a1)+,d2-d6/a4-a6
		movem.l	d2-d6/a4-a6,(a3)
		lea	$20(a3),a3	; next tile
		dbf	d0,SPLC_LoadTile ; repeat for number of	tiles

		dbf	d1,SPLC_ReadEntry ; repeat for number of entries

locret_13C96:
		rts	
; End of function LoadSonicDynPLC

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0A - drowning countdown numbers and small bubbles (LZ)
; ---------------------------------------------------------------------------

Obj0A:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj0A_Index(pc,d0.w),d1
		jmp	Obj0A_Index(pc,d1.w)
; ===========================================================================
Obj0A_Index:	dc.w Obj0A_Main-Obj0A_Index, Obj0A_Animate-Obj0A_Index
		dc.w Obj0A_ChkWater-Obj0A_Index, Obj0A_Display-Obj0A_Index
		dc.w Obj0A_Delete2-Obj0A_Index,	Obj0A_Countdown-Obj0A_Index
		dc.w Obj0A_AirLeft-Obj0A_Index,	Obj0A_Display-Obj0A_Index
		dc.w Obj0A_Delete2-Obj0A_Index
; ===========================================================================

Obj0A_Main:				; XREF: Obj0A_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj64,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	$28(a0),d0
		bpl.s	loc_13D00
		addq.b	#8,$24(a0)
		move.l	#Map_obj0A,4(a0)
		move.w	#$440,2(a0)
		andi.w	#$7F,d0
		move.b	d0,$33(a0)
		bra.w	Obj0A_Countdown
; ===========================================================================

loc_13D00:
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#-$88,$12(a0)

Obj0A_Animate:				; XREF: Obj0A_Index
		lea	(Ani_obj0A).l,a1
		jsr	Actor_Animate

Obj0A_ChkWater:				; XREF: Obj0A_Index
		move.w	($FFFFF646).w,d0
		cmp.w	$C(a0),d0	; has bubble reached the water surface?
		bcs.s	Obj0A_Wobble	; if not, branch
		move.b	#6,$24(a0)
		addq.b	#7,$1C(a0)
		cmpi.b	#$D,$1C(a0)
		beq.s	Obj0A_Display
		bra.s	Obj0A_Display
; ===========================================================================

Obj0A_Wobble:
		tst.b	($FFFFF7C7).w
		beq.s	loc_13D44
		addq.w	#4,$30(a0)

loc_13D44:
		move.b	$26(a0),d0
		addq.b	#1,$26(a0)
		andi.w	#$7F,d0
		lea	(Obj0A_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		bsr.s	Obj0A_ShowNumber
		jsr	SpeedToPos
		tst.b	1(a0)
		bpl.s	Obj0A_Delete
		jmp	Actor_Display
; ===========================================================================

Obj0A_Delete:
		jmp	DeleteObject
; ===========================================================================

Obj0A_Display:				; XREF: Obj0A_Index
		bsr.s	Obj0A_ShowNumber
		lea	(Ani_obj0A).l,a1
		jsr	Actor_Animate
		jmp	Actor_Display
; ===========================================================================

Obj0A_Delete2:				; XREF: Obj0A_Index
		jmp	DeleteObject
; ===========================================================================

Obj0A_AirLeft:				; XREF: Obj0A_Index
		cmpi.w	#$C,($FFFFFE14).w ; check air remaining
		bhi.s	Obj0A_Delete3	; if higher than $C, branch
		subq.w	#1,$38(a0)
		bne.s	Obj0A_Display2
		move.b	#$E,$24(a0)
		addq.b	#7,$1C(a0)
		bra.s	Obj0A_Display
; ===========================================================================

Obj0A_Display2:
		lea	(Ani_obj0A).l,a1
		jsr	Actor_Animate
		tst.b	1(a0)
		bpl.s	Obj0A_Delete3
		jmp	Actor_Display
; ===========================================================================

Obj0A_Delete3:
		jmp	DeleteObject
; ===========================================================================

Obj0A_ShowNumber:			; XREF: Obj0A_Wobble; Obj0A_Display
		tst.w	$38(a0)
		beq.s	locret_13E1A
		subq.w	#1,$38(a0)
		bne.s	locret_13E1A
		cmpi.b	#7,$1C(a0)
		bcc.s	locret_13E1A
		move.w	#$F,$38(a0)
		clr.w	$12(a0)
		move.b	#$80,1(a0)
		move.w	8(a0),d0
		sub.w	(lvl_fgxpos).w,d0
		addi.w	#$80,d0
		move.w	d0,8(a0)
		move.w	$C(a0),d0
		sub.w	(lvl_fgypos).w,d0
		addi.w	#$80,d0
		move.w	d0,$A(a0)
		move.b	#$C,$24(a0)

locret_13E1A:
		rts	
; ===========================================================================
Obj0A_WobbleData:
		dc.b 0, 0, 0, 0, 0, 0,	1, 1, 1, 1, 1, 2, 2, 2,	2, 2, 2
		dc.b 2,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 3, 3, 4, 3
		dc.b 3,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 2, 2, 2, 2
		dc.b 2,	2, 2, 1, 1, 1, 1, 1, 0,	0, 0, 0, 0, 0, -1, -1
		dc.b -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -3, -3, -3, -3, -3, -3, -3, -2
		dc.b -2, -2, -2, -2, -1, -1, -1, -1, -1
		dc.b 0, 0, 0, 0, 0, 0,	1, 1, 1, 1, 1, 2, 2, 2,	2, 2, 2
		dc.b 2,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 3, 3, 4, 3
		dc.b 3,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 2, 2, 2, 2
		dc.b 2,	2, 2, 1, 1, 1, 1, 1, 0,	0, 0, 0, 0, 0, -1, -1
		dc.b -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -3, -3, -3, -3, -3, -3, -3, -2
		dc.b -2, -2, -2, -2, -1, -1, -1, -1, -1
; ===========================================================================

Obj0A_Countdown:			; XREF: Obj0A_Index
		tst.w	$2C(a0)
		bne.w	loc_13F86
		cmpi.b	#6,(ACTSLOT_PLAYER+act_routine).w
		bcc.w	locret_1408C
		btst	#6,(ACTSLOT_PLAYER+act_status).w
		beq.w	locret_1408C
		subq.w	#1,$38(a0)
		bpl.w	loc_13FAC
		move.w	#59,$38(a0)
		move.w	#1,$36(a0)
		jsr	(RandomNumber).l
		andi.w	#1,d0
		move.b	d0,$34(a0)
		move.w	($FFFFFE14).w,d0 ; check air remaining
		cmpi.w	#$19,d0
		beq.s	Obj0A_WarnSound	; play sound if	air is $19
		cmpi.w	#$14,d0
		beq.s	Obj0A_WarnSound
		cmpi.w	#$F,d0
		beq.s	Obj0A_WarnSound
		cmpi.w	#$C,d0
		bhi.s	Obj0A_ReduceAir	; if air is above $C, branch
		bne.s	loc_13F02
		move.w	#$92,d0
		jsr	(Sound_CueMusic).l	; play countdown music

loc_13F02:
		subq.b	#1,$32(a0)
		bpl.s	Obj0A_ReduceAir
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)
		bra.s	Obj0A_ReduceAir
; ===========================================================================

Obj0A_WarnSound:			; XREF: Obj0A_Countdown
		move.w	#$C2,d0
		jsr	(Sound_CueSFX).l ;	play "ding-ding" warning sound

Obj0A_ReduceAir:
		subq.w	#1,($FFFFFE14).w ; subtract 1 from air remaining
		bcc.w	Obj0A_GoMakeItem ; if air is above 0, branch
		bsr.w	ResumeMusic
		move.b	#$81,(plyr_ignore).w ; lock controls
		move.w	#$B2,d0
		jsr	(Sound_CueSFX).l ;	play drowning sound
		move.b	#$A,$34(a0)
		move.w	#1,$36(a0)
		move.w	#$78,$2C(a0)
		move.l	a0,-(sp)
		lea	($FFFFD000).w,a0
		bsr.w	Sonic_ResetOnFloor
		move.b	#$17,$1C(a0)	; use Sonic's drowning animation
		bset	#1,$22(a0)
		bset	#7,2(a0)
		move.w	#0,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		move.b	#$A,$24(a0)		; Force the character to drown
		move.b	#1,(scr_disable).w
		move.b	#0,($FFFFFE1E).w	; Stop the timer immediately
		movea.l	(sp)+,a0
		rts
; ===========================================================================

loc_13F86:
		subq.w	#1,$2C(a0)
		bne.s	loc_13FAC	; Make it jump straight to this location
		move.b	#6,($FFFFD000+$24).w
		rts
; ===========================================================================

Obj0A_GoMakeItem:			; XREF: Obj0A_ReduceAir
		bra.s	Obj0A_MakeItem
; ===========================================================================

loc_13FAC:
		tst.w	$36(a0)
		beq.w	locret_1408C
		subq.w	#1,$3A(a0)
		bpl.w	locret_1408C

Obj0A_MakeItem:
		jsr	(RandomNumber).l
		andi.w	#$F,d0
		move.w	d0,$3A(a0)
		jsr	SingleObjLoad
		bne.w	locret_1408C
		move.b	#$A,0(a1)	; load object
		move.w	(ACTSLOT_PLAYER+act_xpos).w,8(a1) ; match X position to Sonic
		moveq	#6,d0
		btst	#0,(ACTSLOT_PLAYER+act_status).w
		beq.s	loc_13FF2
		neg.w	d0
		move.b	#$40,$26(a1)

loc_13FF2:
		add.w	d0,8(a1)
		move.w	(ACTSLOT_PLAYER+act_ypos).w,$C(a1)
		move.b	#6,$28(a1)
		tst.w	$2C(a0)
		beq.w	loc_1403E
		andi.w	#7,$3A(a0)
		addi.w	#0,$3A(a0)
		move.w	(ACTSLOT_PLAYER+act_ypos).w,d0
		subi.w	#$C,d0
		move.w	d0,$C(a1)
		jsr	(RandomNumber).l
		move.b	d0,$26(a1)
		move.w	($FFFFFE04).w,d0
		andi.b	#3,d0
		bne.s	loc_14082
		move.b	#$E,$28(a1)
		bra.s	loc_14082
; ===========================================================================

loc_1403E:
		btst	#7,$36(a0)
		beq.s	loc_14082
		move.w	($FFFFFE14).w,d2
		lsr.w	#1,d2
		jsr	(RandomNumber).l
		andi.w	#3,d0
		bne.s	loc_1406A
		bset	#6,$36(a0)
		bne.s	loc_14082
		move.b	d2,$28(a1)
		move.w	#$1C,$38(a1)

loc_1406A:
		tst.b	$34(a0)
		bne.s	loc_14082
		bset	#6,$36(a0)
		bne.s	loc_14082
		move.b	d2,$28(a1)
		move.w	#$1C,$38(a1)

loc_14082:
		subq.b	#1,$34(a0)
		bpl.s	locret_1408C
		clr.w	$36(a0)

locret_1408C:
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	play music for LZ/SBZ3 after a countdown
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ResumeMusic:				; XREF: Obj64_Wobble; Sonic_Water; Obj0A_ReduceAir
		cmpi.w	#$C,($FFFFFE14).w
		bhi.s	loc_140AC
		move.w	#$82,d0		; play LZ music
		cmpi.w	#$103,(lvl_id).w ; check if level is	0103 (SBZ3)
		bne.s	loc_140A6
		move.w	#$86,d0		; play SBZ music

loc_140A6:
		jsr	(Sound_CueMusic).l

loc_140AC:
		move.w	#$1E,($FFFFFE14).w
		clr.b	($FFFFD372).w
		rts	
; End of function ResumeMusic

; ===========================================================================
Ani_obj0A:
	include "_anim\obj0A.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - drowning countdown numbers (LZ)
; ---------------------------------------------------------------------------
Map_obj0A:
	include "_maps\obj0A.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 38 - shield and invincibility stars
; ---------------------------------------------------------------------------

Obj38:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj38_Index(pc,d0.w),d1
		jmp	Obj38_Index(pc,d1.w)
; ===========================================================================
Obj38_Index:	dc.w Obj38_Main-Obj38_Index
		dc.w Obj38_Shield-Obj38_Index
		dc.w Obj38_Stars-Obj38_Index
; ===========================================================================

Obj38_Main:				; XREF: Obj38_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj38,4(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$10,$19(a0)
		tst.b	$1C(a0)		; is object a shield?
		bne.s	Obj38_DoStars	; if not, branch
		move.w	#$541,2(a0)	; shield specific code
		rts	
; ===========================================================================

Obj38_DoStars:
		addq.b	#2,$24(a0)	; stars	specific code
		move.w	#$55C,2(a0)
		rts	
; ===========================================================================

Obj38_Shield:				; XREF: Obj38_Index
		tst.b	(plyr_invincflag).w	; does Sonic have invincibility?
		bne.s	Obj38_RmvShield	; if yes, branch
		tst.b	(plyr_shieldflag).w	; does Sonic have shield?
		beq.s	Obj38_Delete	; if not, branch
		move.w	(ACTSLOT_PLAYER+act_xpos).w,8(a0)
		move.w	(ACTSLOT_PLAYER+act_ypos).w,$C(a0)
		move.b	(ACTSLOT_PLAYER+act_status).w,$22(a0)
		lea	(Ani_obj38).l,a1
		jsr	Actor_Animate
		jmp	Actor_Display
; ===========================================================================

Obj38_RmvShield:
		rts	
; ===========================================================================

Obj38_Delete:
		jmp	DeleteObject
; ===========================================================================

Obj38_Stars:				; XREF: Obj38_Index
		tst.b	(plyr_invincflag).w	; does Sonic have invincibility?
		beq.s	Obj38_Delete2	; if not, branch
		move.w	($FFFFF7A8).w,d0
		move.b	$1C(a0),d1
		subq.b	#1,d1
		bra.s	Obj38_StarTrail
; ===========================================================================
		lsl.b	#4,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		andi.b	#$F,d1
		move.b	d1,$30(a0)
		bra.s	Obj38_StarTrail2a
; ===========================================================================

Obj38_StarTrail:			; XREF: Obj38_Stars
		lsl.b	#3,d1
		move.b	d1,d2
		add.b	d1,d1
		add.b	d2,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		cmpi.b	#$18,d1
		bcs.s	Obj38_StarTrail2
		moveq	#0,d1

Obj38_StarTrail2:
		move.b	d1,$30(a0)

Obj38_StarTrail2a:
		lea	(plyr_prevposarr).w,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,8(a0)
		move.w	(a1)+,$C(a0)
		move.b	(ACTSLOT_PLAYER+act_status).w,$22(a0)
		lea	(Ani_obj38).l,a1
		jsr	Actor_Animate
		jmp	Actor_Display
; ===========================================================================

Obj38_Delete2:				; XREF: Obj38_Stars
		jmp	DeleteObject
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 08 - water splash (LZ)
; ---------------------------------------------------------------------------

Obj08:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj08_Index(pc,d0.w),d1
		jmp	Obj08_Index(pc,d1.w)
; ===========================================================================
Obj08_Index:	dc.w Obj08_Main-Obj08_Index
		dc.w Obj08_Display-Obj08_Index
		dc.w Obj08_Delete-Obj08_Index
; ===========================================================================

Obj08_Main:				; XREF: Obj08_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj08,4(a0)
		ori.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$10,$19(a0)
		move.w	#$4259,2(a0)
		move.w	(ACTSLOT_PLAYER+act_xpos).w,8(a0) ; copy x-position from Sonic

Obj08_Display:				; XREF: Obj08_Index
		move.w	($FFFFF646).w,$C(a0) ; copy y-position from water height
		lea	(Ani_obj08).l,a1
		jsr	Actor_Animate
		jmp	Actor_Display
; ===========================================================================

Obj08_Delete:				; XREF: Obj08_Index
		jmp	DeleteObject	; delete when animation	is complete
; ===========================================================================
Ani_obj38:
	include "_anim\obj38.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - shield and invincibility stars
; ---------------------------------------------------------------------------
Map_obj38:
	include "_maps\obj38.asm"

Ani_obj08:
	include "_anim\obj08.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - water splash (LZ)
; ---------------------------------------------------------------------------
Map_obj08:
	include "_maps\obj08.asm"






; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's angle & position as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

Sonic_AnglePos:				; XREF: Obj01_MdNormal; Obj01_MdRoll
		move.l	($FFFFFFD0).w,($FFFFF796).w		; MJ: load first collision data location
		tst.b	($FFFFFFF7).w				; MJ: is second sollision set to be used?
		beq.s	SAP_First				; MJ: if not, branch
		move.l	($FFFFFFD4).w,($FFFFF796).w		; MJ: load second collision data location

SAP_First:
		btst	#3,$22(a0)
		beq.s	loc_14602
		moveq	#0,d0
		move.b	d0,(plyr_angle).w
		move.b	d0,(plyr_angle+2).w
		rts	
; ===========================================================================

loc_14602:
		moveq	#3,d0
		move.b	d0,(plyr_angle).w
		move.b	d0,(plyr_angle+2).w
		move.b	$26(a0),d0
		addi.b	#$20,d0
		bpl.s	loc_14624
		move.b	$26(a0),d0
		bpl.s	loc_1461E
		subq.b	#1,d0

loc_1461E:
		addi.b	#$20,d0
		bra.s	loc_14630
; ===========================================================================

loc_14624:
		move.b	$26(a0),d0
		bpl.s	loc_1462C
		addq.b	#1,d0

loc_1462C:
		addi.b	#$1F,d0

loc_14630:
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	Sonic_WalkVertL
		cmpi.b	#$80,d0
		beq.w	Sonic_WalkCeiling
		cmpi.b	#$C0,d0
		beq.w	Sonic_WalkVertR
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_146BE
		bpl.s	loc_146C0
		cmpi.w	#-$E,d1
		blt.s	locret_146E6
		add.w	d1,$C(a0)

locret_146BE:
		rts	
; ===========================================================================

loc_146C0:
		cmpi.w	#$E,d1
		bgt.s	loc_146CC

loc_146C6:
		add.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_146CC:
		tst.b	$38(a0)
		bne.s	loc_146C6
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; ===========================================================================

locret_146E6:
		rts	
; End of function Sonic_AnglePos

; ===========================================================================

locret_1470A:
		rts	
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's angle as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Angle:				; XREF: Sonic_AnglePos; et al
		move.b	(plyr_angle+2).w,d2
		cmp.w	d0,d1
		ble.s	loc_1475E
		move.b	(plyr_angle).w,d2
		move.w	d0,d1

loc_1475E:
		btst	#0,d2
		bne.s	loc_1476A
		move.b	d2,$26(a0)
		rts	
; ===========================================================================

loc_1476A:
		move.b	$26(a0),d2
		addi.b	#$20,d2
		andi.b	#$C0,d2
		move.b	d2,$26(a0)
		rts	
; End of function Sonic_Angle

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to	his right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkVertR:			; XREF: Sonic_AnglePos
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_147F0
		bpl.s	loc_147F2
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		add.w	d1,8(a0)

locret_147F0:
		rts	
; ===========================================================================

loc_147F2:
		cmpi.w	#$E,d1
		bgt.s	loc_147FE

loc_147F8:
		add.w	d1,8(a0)
		rts	
; ===========================================================================

loc_147FE:
		tst.b	$38(a0)
		bne.s	loc_147F8
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkVertR

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk upside-down
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkCeiling:			; XREF: Sonic_AnglePos
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_14892
		bpl.s	loc_14894
		cmpi.w	#-$E,d1
		blt.w	locret_146E6
		sub.w	d1,$C(a0)

locret_14892:
		rts	
; ===========================================================================

loc_14894:
		cmpi.w	#$E,d1
		bgt.s	loc_148A0

loc_1489A:
		sub.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_148A0:
		tst.b	$38(a0)
		bne.s	loc_1489A
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkCeiling

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to	his left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkVertL:
		move.w	$C(a0),d2				; MJ: Load Y position
		move.w	8(a0),d3				; MJ: Load X position
		moveq	#0,d0					; MJ: clear d0
		move.b	$17(a0),d0				; MJ: load height
		ext.w	d0					; MJ: set left byte pos or neg
		sub.w	d0,d2					; MJ: subtract from Y position
		move.b	$16(a0),d0				; MJ: load width
		ext.w	d0					; MJ: set left byte pos or neg
		sub.w	d0,d3					; MJ: subtract from X position
		eori.w	#$F,d3
		lea	(plyr_angle).w,a4			; MJ: load address of the angle value set
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.s	locret_14934
		bpl.s	loc_14936
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		sub.w	d1,8(a0)

locret_14934:
		rts

; ===========================================================================

loc_14936:
		cmpi.w	#$E,d1
		bgt.s	loc_14942

loc_1493C:
		sub.w	d1,8(a0)
		rts	

; ===========================================================================

loc_14942:
		tst.b	$38(a0)
		bne.s	loc_1493C
		bset	#1,$22(a0)
		bclr	#5,$22(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkVertL

; ---------------------------------------------------------------------------
; Subroutine to	find which tile	the object is standing on
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

Floor_ChkTile:				; XREF: FindFloor; et al
		move.w	d2,d0					; MJ: load Y position
		andi.w	#$0780,d0				; MJ: get within 780 (E00 pixels) in multiples of 80
		add.w	d0,d0					; MJ: multiply by 2
		move.w	d3,d1					; MJ: load X position
		lsr.w	#7,d1					; MJ: shift to right side
		andi.w	#$007F,d1				; MJ: get within 7F
		add.w	d1,d0					; MJ: add calc'd Y to calc'd X
		moveq	#-1,d1					; MJ: prepare FFFF in d3
		movea.l	(lvl_fgaddr).w,a1			; MJ: load address of Layout to a1
		move.b	(a1,d0.w),d1				; MJ: collect correct chunk ID based on the X and Y position
		andi.w	#$FF,d1					; MJ: keep within FF
		lsl.w	#$07,d1					; MJ: multiply by 80
		move.w	d2,d0					; MJ: load Y position
		andi.w	#$0070,d0				; MJ: keep Y within 80 pixels
		add.w	d0,d1					; MJ: add to ror'd chunk ID
		move.w	d3,d0					; MJ: load X position
		lsr.w	#3,d0					; MJ: divide by 8
		andi.w	#$000E,d0				; MJ: keep X within 10 pixels
		add.w	d0,d1					; MJ: add to ror'd chunk ID

loc_14996:
		movea.l	d1,a1					; MJ: set address (Chunk to read)
		rts						; MJ: return
; ===========================================================================

loc_1499A:
		andi.w	#$7F,d1
		btst	#6,1(a0)
		beq.s	loc_149B2
		addq.w	#1,d1
		cmpi.w	#$29,d1
		bne.s	loc_149B2
		move.w	#$51,d1

loc_149B2:
		ror.w	#7,d1
		ror.w	#2,d1
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$070,d0
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$0E,d0
		add.w	d0,d1
		movea.l	d1,a1
		rts
; End of function Floor_ChkTile


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ColisionChkLayer:
		tst.b	($FFFFFFF7).w				; MJ: is collision set to first?
		beq.s	CCL_NoChange				; MJ: if so, branch
		move.w	d0,d4					; MJ: load block ID to d4
		and.w	#$0FFF,d0				; MJ: clear solid settings of d0
		and.w	#$C000,d4				; MJ: get only second solid settings of d4
		lsr.w	#$02,d4					; MJ: shift them to first solid settings location
		add.w	d4,d0					; MJ: add to rest of block ID

CCL_NoChange:
		rts						; MJ: return


FindFloor:
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		bsr.s	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_149DE
		btst	d5,d4
		bne.s	loc_149EC

loc_149DE:
		add.w	a3,d2
		bsr.w	FindFloor2
		sub.w	a3,d2
		addi.w	#$10,d1
		rts	
; ===========================================================================

loc_149EC:
		movea.l	($FFFFF796).w,a2			; MJ: load collision index address
		move.b	(a2,d0.w),d0				; MJ: load correct Collision ID based on the Block ID
		andi.w	#$FF,d0					; MJ: clear the left byte
		beq.s	loc_149DE				; MJ: if collision ID is 00, branch
		lea	(AngleMap).l,a2				; MJ: load angle map data to a2
		move.b	(a2,d0.w),(a4)				; MJ: collect correct angle based on the collision ID
		lsl.w	#4,d0					; MJ: multiply collision ID by 10
		move.w	d3,d1					; MJ: load X position
		btst	#$A,d4					; MJ: is the block mirrored?
		beq.s	loc_14A12				; MJ: if not, branch
		not.w	d1					; MJ: reverse bits of the X position
		neg.b	(a4)					; MJ: reverse the angle ID

loc_14A12:
		btst	#$B,d4					; MJ: is the block flipped?
		beq.s	loc_14A22				; MJ: if not, branch
		addi.b	#$40,(a4)				; MJ: increase angle ID by 40..
		neg.b	(a4)					; MJ: ..reverse the angle ID..
		subi.b	#$40,(a4)				; MJ: ..and subtract 40 again 

loc_14A22:
		andi.w	#$F,d1					; MJ: get only within 10 (d1 is pixel based on the collision block)
		add.w	d0,d1					; MJ: add collision ID (x10) (d0 is the collision block being read)
		lea	(CollArray1).l,a2			; MJ: load collision array
		move.b	(a2,d1.w),d0				; MJ: load solid value
		ext.w	d0					; MJ: clear left byte
		eor.w	d6,d4					; MJ: set ceiling/wall bits
		btst	#$B,d4					; MJ: is sonic walking on the left wall?
		beq.s	loc_14A3E				; MJ: if not, branch
		neg.w	d0					; MJ: reverse solid value

loc_14A3E:
		tst.w	d0					; MJ: is the solid data null?
		beq.s	loc_149DE				; MJ: if so, branch
		bmi.s	loc_14A5A				; MJ: if it's negative, branch
		cmpi.b	#$10,d0					; MJ: is it 10?
		beq.s	loc_14A66				; MJ: if so, branch
		move.w	d2,d1					; MJ: load Y position
		andi.w	#$F,d1					; MJ: get only within 10 pixels
		add.w	d1,d0					; MJ: add to solid value
		move.w	#$F,d1					; MJ: set F
		sub.w	d0,d1					; MJ: minus solid value from F
		rts			; d1 = position?	; MJ: return

; ===========================================================================

loc_14A5A:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_149DE

loc_14A66:
		sub.w	a3,d2
		bsr.w	FindFloor2
		add.w	a3,d2
		subi.w	#$10,d1
		rts	
; End of function FindFloor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindFloor2:				; XREF: FindFloor
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		bsr.w	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_14A86
		btst	d5,d4
		bne.s	loc_14A94

loc_14A86:
		move.w	#$F,d1
		move.w	d2,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14A94:
		movea.l	($FFFFF796).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	loc_14A86
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14ABA
		not.w	d1
		neg.b	(a4)

loc_14ABA:
		btst	#$B,d4					; MJ: C to B (because S2 format has two solids)
		beq.s	loc_14ACA
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14ACA:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4					; MJ: C to B (because S2 format has two solids)
		beq.s	loc_14AE6
		neg.w	d0

loc_14AE6:
		tst.w	d0
		beq.s	loc_14A86
		bmi.s	loc_14AFC
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14AFC:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14A86
		not.w	d1
		rts	
; End of function FindFloor2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindWall:
		bsr.w	Floor_ChkTile				; MJ: get chunk/block location
		move.w	(a1),d0					; MJ: load block ID from chunk
		bsr.w	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4					; MJ: copy to d4
		andi.w	#$3FF,d0				; MJ: clear flip/mirror/etc data
		beq.s	loc_14B1E				; MJ: if it was null, branch
		btst	d5,d4					; MJ: check solid set (C top solid | D Left/right solid)
		bne.s	loc_14B2C				; MJ: if the specific solid is set, branch

loc_14B1E:
		add.w	a3,d3					; MJ: add 10 to X position
		bsr.w	FindWall2
		sub.w	a3,d3					; MJ: minus 10 from X position
		addi.w	#$10,d1
		rts	
; ===========================================================================

loc_14B2C:
		movea.l	($FFFFF796).w,a2			; MJ: load address of collision for level
		move.b	(a2,d0.w),d0				; MJ: load correct colision ID based on the block ID
		andi.w	#$FF,d0					; MJ: keep within FF
		beq.s	loc_14B1E				; MJ: if it's null, branch
		lea	(AngleMap).l,a2				; MJ: load angle map data to a2
		move.b	(a2,d0.w),(a4)				; MJ: load angle set location based on collision ID
		lsl.w	#4,d0					; MJ: multiply by 10
		move.w	d2,d1					; MJ: load Y position
		btst	#$B,d4					; MJ: is the block ID flipped?
		beq.s	loc_14B5A				; MJ: if not, branch
		not.w	d1
		addi.b	#$40,(a4)				; MJ: increase angle set by 40
		neg.b	(a4)					; MJ: negate to opposite
		subi.b	#$40,(a4)				; MJ: decrease angle set by 40

loc_14B5A:
		btst	#$A,d4					; MJ: is the block ID mirrored?
		beq.s	loc_14B62				; MJ: if not, branch
		neg.b	(a4)					; MJ: negate to opposite

loc_14B62:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14B7E
		neg.w	d0

loc_14B7E:
		tst.w	d0
		beq.s	loc_14B1E
		bmi.s	loc_14B9A
		cmpi.b	#$10,d0
		beq.s	loc_14BA6
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14B9A:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14B1E

loc_14BA6:
		sub.w	a3,d3
		bsr.w	FindWall2
		add.w	a3,d3
		subi.w	#$10,d1
		rts	
; End of function FindWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindWall2:				; XREF: FindWall
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		bsr.w	ColisionChkLayer			; MJ: check solid settings to use
		move.w	d0,d4
		andi.w	#$3FF,d0
		beq.s	loc_14BC6
		btst	d5,d4
		bne.s	loc_14BD4

loc_14BC6:
		move.w	#$F,d1
		move.w	d3,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14BD4:
		movea.l	($FFFFF796).w,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.s	loc_14BC6
		lea	(AngleMap).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$B,d4					; MJ: C to B (because S2 format has two solids)
		beq.s	loc_14C02
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14C02:
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14C0A
		neg.b	(a4)

loc_14C0A:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(CollArray2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$A,d4					; MJ: B to A (because S2 format has two solids)
		beq.s	loc_14C26
		neg.w	d0

loc_14C26:
		tst.w	d0
		beq.s	loc_14BC6
		bmi.s	loc_14C3C
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14C3C:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14BC6
		not.w	d1
		rts	
; End of function FindWall2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkSpeed:			; XREF: Sonic_Move
		move.l	8(a0),d3
		move.l	$C(a0),d2
		move.w	$10(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	$12(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,(plyr_angle).w
		move.b	d0,(plyr_angle+2).w
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.s	loc_14D1A
		move.b	d1,d0
		bpl.s	loc_14D14
		subq.b	#1,d0

loc_14D14:
		addi.b	#$20,d0
		bra.s	loc_14D24
; ===========================================================================

loc_14D1A:
		move.b	d1,d0
		bpl.s	loc_14D20
		addq.b	#1,d0

loc_14D20:
		addi.b	#$1F,d0

loc_14D24:
		andi.b	#$C0,d0
		beq.w	loc_14DF0
		cmpi.b	#$80,d0
		beq.w	loc_14F7C
		andi.b	#$38,d1
		bne.s	loc_14D3C
		addq.w	#8,d2

loc_14D3C:
		cmpi.b	#$40,d0
		beq.w	loc_1504A
		bra.w	loc_14EBC

; End of function Sonic_WalkSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14D48:				; XREF: Sonic_Jump
		move.b	d0,(plyr_angle).w
		move.b	d0,(plyr_angle+2).w
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_14FD6
		cmpi.b	#$80,d0
		beq.w	Sonic_DontRunOnWalls
		cmpi.b	#$C0,d0
		beq.w	sub_14E50

; End of function sub_14D48

; ---------------------------------------------------------------------------
; Subroutine to	make Sonic land	on the floor after jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitFloor:				; XREF: Sonic_Floor
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#0,d2

loc_14DD0:
		move.b	(plyr_angle+2).w,d3
		cmp.w	d0,d1
		ble.s	loc_14DDE
		move.b	(plyr_angle).w,d3
		exg	d0,d1

loc_14DDE:
		btst	#0,d3
		beq.s	locret_14DE6
		move.b	d2,d3

locret_14DE6:
		rts	

; End of function Sonic_HitFloor

; ===========================================================================
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14DF0:				; XREF: Sonic_WalkSpeed
		addi.w	#$A,d2
		lea	(plyr_angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	#0,d2

loc_14E0A:				; XREF: sub_14EB4
		move.b	(plyr_angle).w,d3
		btst	#0,d3
		beq.s	locret_14E16
		move.b	d2,d3

locret_14E16:
		rts	

; ---------------------------------------------------------------------------
; Subroutine allowing objects to interact with the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitFloor:
		move.w	8(a0),d3

; End of function ObjHitFloor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitFloor2:
		move.w	$C(a0),d2
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	(plyr_angle).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$C,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	(plyr_angle).w,d3
		btst	#0,d3
		beq.s	locret_14E4E
		move.b	#0,d3

locret_14E4E:
		rts	
; End of function ObjHitFloor2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14E50:				; XREF: sub_14D48
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_14DD0

; End of function sub_14E50


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14EB4:				; XREF: Sonic_Floor
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14EBC:
		addi.w	#$A,d3
		lea	(plyr_angle).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	#-$40,d2
		bra.w	loc_14E0A

; End of function sub_14EB4

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallRight:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	(plyr_angle).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	(plyr_angle).w,d3
		btst	#0,d3
		beq.s	locret_14F06
		move.b	#-$40,d3

locret_14F06:
		rts	

; End of function ObjHitWallRight

; ---------------------------------------------------------------------------
; Subroutine preventing	Sonic from running on walls and	ceilings when he
; touches them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_DontRunOnWalls:			; XREF: Sonic_Floor; et al
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(plyr_angle).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#-$80,d2
		bra.w	loc_14DD0
; End of function Sonic_DontRunOnWalls

; ===========================================================================
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14F7C:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	(plyr_angle).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	#-$80,d2
		bra.w	loc_14E0A

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitCeiling:
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	(plyr_angle).w,a4
		movea.w	#-$10,a3
		move.w	#$0800,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindFloor				; MJ: check solidity
		move.b	(plyr_angle).w,d3
		btst	#0,d3
		beq.s	locret_14FD4
		move.b	#-$80,d3

locret_14FD4:
		rts	
; End of function ObjHitCeiling

; ===========================================================================

loc_14FD6:				; XREF: sub_14D48
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(plyr_angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(plyr_angle+2).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_14DD0

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic when	he jumps at a wall
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitWall:				; XREF: Sonic_Floor
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_1504A:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	(plyr_angle).w,a4
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	#$40,d2
		bra.w	loc_14E0A
; End of function Sonic_HitWall

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallLeft:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	(plyr_angle).w,a4
		move.b	#0,(a4)
		movea.w	#-$10,a3
		move.w	#$400,d6
		moveq	#$D,d5					; MJ: set solid type to check
		bsr.w	FindWall				; MJ: check solidity
		move.b	(plyr_angle).w,d3
		btst	#0,d3
		beq.s	locret_15098
		move.b	#$40,d3

locret_15098:
		rts	
; End of function ObjHitWallLeft

; ===========================================================================


; ===========================================================================
; ---------------------------------------------------------------------------
; Object 79 - lamppost
; ---------------------------------------------------------------------------

Obj79:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj79_Index(pc,d0.w),d1
		jsr	Obj79_Index(pc,d1.w)
		jmp	MarkObjGone
; ===========================================================================
Obj79_Index:	dc.w Obj79_Main-Obj79_Index
		dc.w Obj79_BlueLamp-Obj79_Index
		dc.w Obj79_AfterHit-Obj79_Index
		dc.w Obj79_Twirl-Obj79_Index
; ===========================================================================

Obj79_Main:				; XREF: Obj79_Index
		addq.b	#2,$24(a0)
		move.l	#Map_obj79,4(a0)
		move.w	#$7A0,2(a0)
		move.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#5,$18(a0)
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		bne.s	Obj79_RedLamp
		move.b	(cp_idx).w,d1
		andi.b	#$7F,d1
		move.b	$28(a0),d2	; get lamppost number
		andi.b	#$7F,d2
		cmp.b	d2,d1		; is lamppost number higher than the number hit?
		bcs.s	Obj79_BlueLamp	; if yes, branch

Obj79_RedLamp:
		bset	#0,2(a2,d0.w)
		move.b	#4,$24(a0)	; run "Obj79_AfterHit" routine
		move.b	#3,$1A(a0)	; use red lamppost frame
		rts	
; ===========================================================================

Obj79_BlueLamp:				; XREF: Obj79_Index
		tst.w	($FFFFFE08).w	; is debug mode	being used?
		bne.w	locret_16F90	; if yes, branch
		tst.b	(plyr_ignore).w
		bmi.w	locret_16F90
		move.b	(cp_idx).w,d1
		andi.b	#$7F,d1
		move.b	$28(a0),d2
		andi.b	#$7F,d2
		cmp.b	d2,d1
		bcs.s	Obj79_HitLamp
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#4,$24(a0)
		move.b	#3,$1A(a0)
		bra.w	locret_16F90
; ===========================================================================

Obj79_HitLamp:
		move.w	(ACTSLOT_PLAYER+act_xpos).w,d0
		sub.w	8(a0),d0
		addq.w	#8,d0
		cmpi.w	#$10,d0
		bcc.w	locret_16F90
		move.w	(ACTSLOT_PLAYER+act_ypos).w,d0
		sub.w	$C(a0),d0
		addi.w	#$40,d0
		cmpi.w	#$68,d0
		bcc.s	locret_16F90
		move.w	#$A1,d0
		jsr	(Sound_CueSFX).l ;	play lamppost sound
		addq.b	#2,$24(a0)
		jsr	SingleObjLoad
		bne.s	loc_16F76
		move.b	#$79,0(a1)	; load twirling	lamp object
		move.b	#6,$24(a1)	; use "Obj79_Twirl" routine
		move.w	8(a0),$30(a1)
		move.w	$C(a0),$32(a1)
		subi.w	#$18,$32(a1)
		move.l	#Map_obj79,4(a1)
		move.w	#$7A0,2(a1)
		move.b	#4,1(a1)
		move.b	#8,$19(a1)
		move.b	#4,$18(a1)
		move.b	#2,$1A(a1)
		move.w	#$20,$36(a1)

loc_16F76:
		move.b	#1,$1A(a0)	; use "post only" frame, with no lamp
		bsr.w	Obj79_StoreInfo
		lea	($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	$23(a0),d0
		bset	#0,2(a2,d0.w)

locret_16F90:
		rts	
; ===========================================================================

Obj79_AfterHit:				; XREF: Obj79_Index
		rts	
; ===========================================================================

Obj79_Twirl:				; XREF: Obj79_Index
		subq.w	#1,$36(a0)
		bpl.s	loc_16FA0
		move.b	#4,$24(a0)

loc_16FA0:
		move.b	$26(a0),d0
		subi.b	#$10,$26(a0)
		subi.b	#$40,d0
		jsr	(Math_GetSine).l
		muls.w	#$C00,d1
		swap	d1
		add.w	$30(a0),d1
		move.w	d1,8(a0)
		muls.w	#$C00,d0
		swap	d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	store information when you hit a lamppost
; ---------------------------------------------------------------------------

Obj79_StoreInfo:			; XREF: Obj79_HitLamp
		move.b	$28(a0),(cp_idx).w 		; lamppost number
		move.b	(cp_idx).w,(cp_idx2).w
		move.w	8(a0),(cp_plyrxpos).w		; x-position
		move.w	$C(a0),(cp_plyrypos).w		; y-position
		move.w	(plyr_rings).w,(cp_rings).w 	; rings
		move.l	(time_minutes).w,(cp_time).w 	; time
		move.b	(lvl_eventid).w,(cp_lvlevent).w 	; routine counter for dynamic level mod
		move.w	(bound_down).w,(cp_dbound).w 	; lower y-boundary of level
		move.w	(lvl_fgxpos).w,(cp_fgxpos).w 	; screen x-position
		move.w	(lvl_fgypos).w,(cp_fgypos).w 	; screen y-position
		move.w	(lvl_bg1xpos).w,(cp_bg1xpos).w 	; bg position
		move.w	(lvl_bg1ypos).w,(cp_bg1ypos).w 	; bg position
		move.w	(lvl_bg2xpos).w,(cp_bg2xpos).w 	; bg position
		move.w	(lvl_bg2ypos).w,(cp_bg2ypos).w 	; bg position
		move.w	(lvl_bg3xpos).w,(cp_bg3xpos).w 	; bg position
		move.w	(lvl_bg3ypos).w,(cp_bg3ypos).w 	; bg position
		move.w	(water_avg).w,(cp_wateravg).w 	; water height
		move.b	(water_routine).w,(cp_waterroutine).w 	; rountine counter for water
		move.b	(water_fullscr).w,(cp_waterfull).w 	; water direction
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	load stored info when you start	a level	from a lamppost
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj79_LoadInfo:				; XREF: LevelSizeLoad
		move.b	(cp_idx2).w,(cp_idx).w
		move.w	(cp_plyrxpos).w,(ACTSLOT_PLAYER+act_xpos).w
		move.w	(cp_plyrypos).w,(ACTSLOT_PLAYER+act_ypos).w
		move.w	(cp_rings).w,(plyr_rings).w
		clr.w	(plyr_rings).w
		move.l	(cp_time).w,(time_minutes).w
		move.b	#59,(time_frames).w
		subq.b	#1,(time_seconds).w
		move.b	(cp_lvlevent).w,(lvl_eventid).w
		move.b	(cp_waterroutine).w,(water_routine).w
		move.w	(cp_dbound).w,(bound_down).w
		move.w	(cp_dbound).w,(bound_dtarget).w
		move.w	(cp_fgxpos).w,(lvl_fgxpos).w
		move.w	(cp_fgypos).w,(lvl_fgypos).w
		move.w	(cp_bg1xpos).w,(lvl_bg1xpos).w
		move.w	(cp_bg1ypos).w,(lvl_bg1ypos).w
		move.w	(cp_bg2xpos).w,(lvl_bg2xpos).w
		move.w	(cp_bg2ypos).w,(lvl_bg2ypos).w
		move.w	(cp_bg3xpos).w,(lvl_bg3xpos).w
		move.w	(cp_bg3ypos).w,(lvl_bg3ypos).w
		cmpi.b	#1,(lvl_id).w
		bne.s	loc_170E4
		move.w	(cp_wateravg).w,(water_avg).w
		move.b	(cp_waterroutine).w,(water_routine).w
		move.b	(cp_waterfull).w,(water_fullscr).w

loc_170E4:
		tst.b	(cp_idx).w
		bpl.s	locret_170F6
		move.w	(cp_plyrxpos).w,d0
		subi.w	#$A0,d0
		move.w	d0,(bound_left).w

locret_170F6:
		rts	
; End of function Obj79_LoadInfo

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - lamppost
; ---------------------------------------------------------------------------
Map_obj79:
	include "_maps\obj79.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3E - prison capsule
; ---------------------------------------------------------------------------

Obj3E:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj3E_Index(pc,d0.w),d1
		jsr	Obj3E_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	Obj3E_Delete
		jmp	Actor_Display
; ===========================================================================

Obj3E_Delete:
		jmp	DeleteObject
; ===========================================================================
Obj3E_Index:	dc.w Obj3E_Main-Obj3E_Index
		dc.w Obj3E_BodyMain-Obj3E_Index
		dc.w Obj3E_Switched-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Explosion-Obj3E_Index
		dc.w Obj3E_Animals-Obj3E_Index
		dc.w Obj3E_EndAct-Obj3E_Index

Obj3E_Var:	dc.b 2,	$20, 4,	0	; routine, width, priority, frame
		dc.b 4,	$C, 5, 1
		dc.b 6,	$10, 4,	3
		dc.b 8,	$10, 3,	5
; ===========================================================================

Obj3E_Main:				; XREF: Obj3E_Index
		move.l	#Map_obj3E,4(a0)
		move.w	#$49D,2(a0)
		move.b	#4,1(a0)
		move.w	$C(a0),$30(a0)
		moveq	#0,d0
		move.b	$28(a0),d0
		lsl.w	#2,d0
		lea	Obj3E_Var(pc,d0.w),a1
		move.b	(a1)+,$24(a0)
		move.b	(a1)+,$19(a0)
		move.b	(a1)+,$18(a0)
		move.b	(a1)+,$1A(a0)
		cmpi.w	#8,d0		; is object type number	02?
		bne.s	Obj3E_Not02	; if not, branch
		move.b	#6,$20(a0)
		move.b	#8,$21(a0)

Obj3E_Not02:
		rts	
; ===========================================================================

Obj3E_BodyMain:				; XREF: Obj3E_Index
		cmpi.b	#2,($FFFFF7A7).w
		beq.s	Obj3E_ChkOpened
		move.w	#$2B,d1
		move.w	#$18,d2
		move.w	#$18,d3
		move.w	8(a0),d4
		jmp	SolidObject
; ===========================================================================

Obj3E_ChkOpened:
		tst.b	$25(a0)		; has the prison been opened?
		beq.s	Obj3E_DoOpen	; if yes, branch
		clr.b	$25(a0)
		bclr	#3,(ACTSLOT_PLAYER+act_status).w
		bset	#1,(ACTSLOT_PLAYER+act_status).w

Obj3E_DoOpen:
		move.b	#2,$1A(a0)	; use frame number 2 (destroyed	prison)
		rts	
; ===========================================================================

Obj3E_Switched:				; XREF: Obj3E_Index
		move.w	#$17,d1
		move.w	#8,d2
		move.w	#8,d3
		move.w	8(a0),d4
		jsr	SolidObject
		lea	(Ani_obj3E).l,a1
		jsr	Actor_Animate
		move.w	$30(a0),$C(a0)
		tst.b	$25(a0)
		beq.s	locret_1AC60
		addq.w	#8,$C(a0)
		move.b	#$A,$24(a0)
		move.w	#$3C,$1E(a0)
		clr.b	($FFFFFE1E).w	; stop time counter
		clr.b	($FFFFF7AA).w	; lock screen position
		move.b	#1,(jpad_ignore).w ; lock	controls
		move.w	#$800,(plyr_btnheld).w ; make Sonic run to	the right
		clr.b	$25(a0)
		bclr	#3,(ACTSLOT_PLAYER+act_status).w
		bset	#1,(ACTSLOT_PLAYER+act_status).w

locret_1AC60:
		rts	
; ===========================================================================

Obj3E_Explosion:			; XREF: Obj3E_Index
		moveq	#7,d0
		and.b	($FFFFFE0F).w,d0
		bne.s	loc_1ACA0
		jsr	SingleObjLoad
		bne.s	loc_1ACA0
		move.b	#$3F,0(a1)	; load explosion object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(RandomNumber).l
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)

loc_1ACA0:
		subq.w	#1,$1E(a0)
		beq.s	Obj3E_MakeAnimal
		rts	
; ===========================================================================

Obj3E_MakeAnimal:
		move.b	#2,($FFFFF7A7).w
		move.b	#$C,$24(a0)	; replace explosions with animals
		move.b	#6,$1A(a0)
		move.w	#$96,$1E(a0)
		addi.w	#$20,$C(a0)
		moveq	#7,d6
		move.w	#$9A,d5
		moveq	#-$1C,d4

Obj3E_Loop:
		jsr	SingleObjLoad
		bne.s	locret_1ACF8
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		add.w	d4,8(a1)
		addq.w	#7,d4
		move.w	d5,$36(a1)
		subq.w	#8,d5
		dbf	d6,Obj3E_Loop	; repeat 7 more	times

locret_1ACF8:
		rts	
; ===========================================================================

Obj3E_Animals:				; XREF: Obj3E_Index
		moveq	#7,d0
		and.b	($FFFFFE0F).w,d0
		bne.s	loc_1AD38
		jsr	SingleObjLoad
		bne.s	loc_1AD38
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(RandomNumber).l
		andi.w	#$1F,d0
		subq.w	#6,d0
		tst.w	d1
		bpl.s	loc_1AD2E
		neg.w	d0

loc_1AD2E:
		add.w	d0,8(a1)
		move.w	#$C,$36(a1)

loc_1AD38:
		subq.w	#1,$1E(a0)
		bne.s	locret_1AD48
		addq.b	#2,$24(a0)
		move.w	#180,$1E(a0)

locret_1AD48:
		rts	
; ===========================================================================

Obj3E_EndAct:				; XREF: Obj3E_Index
		moveq	#$3E,d0
		moveq	#$28,d1
		moveq	#$40,d2
		lea	($FFFFD040).w,a1 ; load	object RAM

Obj3E_FindObj28:
		cmp.b	(a1),d1		; is object $28	(animal) loaded?
		beq.s	Obj3E_Obj28Found ; if yes, branch
		adda.w	d2,a1		; next object RAM
		dbf	d0,Obj3E_FindObj28 ; repeat $3E	times

		jmp	DeleteObject
; ===========================================================================

Obj3E_Obj28Found:
		rts	
; ===========================================================================
Ani_obj3E:
	include "_anim\obj3E.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - prison capsule
; ---------------------------------------------------------------------------
Map_obj3E:
	include "_maps\obj3E.asm"

; ---------------------------------------------------------------------------
; Object touch response	subroutine - $20(a0) in	the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


TouchResponse:				; XREF: Obj01
		nop	
		move.w	8(a0),d2	; load Sonic's x-axis value
		move.w	$C(a0),d3	; load Sonic's y-axis value
		subq.w	#8,d2
		moveq	#0,d5
		move.b	$16(a0),d5	; load Sonic's height
		subq.b	#3,d5
		sub.w	d5,d3
		cmpi.b	#$39,$1A(a0)	; is Sonic ducking?
		bne.s	Touch_NoDuck	; if not, branch
		addi.w	#$C,d3
		moveq	#$A,d5

Touch_NoDuck:
		move.w	#$10,d4
		add.w	d5,d5
		lea	(act_dynamic).w,a1 ; begin checking the object RAM
		move.w	#$5F,d6

Touch_Loop:
		tst.b	1(a1)
		bpl.s	Touch_NextObj
		move.b	$20(a1),d0	; load touch response number
		bne.s	Touch_Height	; if touch response is not 0, branch

Touch_NextObj:
		lea	$40(a1),a1	; next object RAM
		dbf	d6,Touch_Loop	; repeat $5F more times

		moveq	#0,d0
		rts	
; ===========================================================================
Touch_Sizes:	dc.b  $14, $14		; width, height
		dc.b   $C, $14
		dc.b  $14,  $C
		dc.b	4, $10
		dc.b   $C, $12
		dc.b  $10, $10
		dc.b	6,   6
		dc.b  $18,  $C
		dc.b   $C, $10
		dc.b  $10,  $C
		dc.b	8,   8
		dc.b  $14, $10
		dc.b  $14,   8
		dc.b   $E,  $E
		dc.b  $18, $18
		dc.b  $28, $10
		dc.b  $10, $18
		dc.b	8, $10
		dc.b  $20, $70
		dc.b  $40, $20
		dc.b  $80, $20
		dc.b  $20, $20
		dc.b	8,   8
		dc.b	4,   4
		dc.b  $20,   8
		dc.b   $C,  $C
		dc.b	8,   4
		dc.b  $18,   4
		dc.b  $28,   4
		dc.b	4,   8
		dc.b	4, $18
		dc.b	4, $28
		dc.b	4, $20
		dc.b  $18, $18
		dc.b   $C, $18
		dc.b  $48,   8
; ===========================================================================

Touch_Height:				; XREF: TouchResponse
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	Touch_Sizes-2(pc,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	8(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.s	loc_1AE98
		add.w	d1,d1
		add.w	d1,d0
		bcs.s	Touch_Width
		bra.w	Touch_NextObj
; ===========================================================================

loc_1AE98:
		cmp.w	d4,d0
		bhi.w	Touch_NextObj

Touch_Width:
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	$C(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.s	loc_1AEB6
		add.w	d1,d1
		add.w	d0,d1
		bcs.s	Touch_ChkValue
		bra.w	Touch_NextObj
; ===========================================================================

loc_1AEB6:
		cmp.w	d5,d0
		bhi.w	Touch_NextObj

Touch_ChkValue:
		move.b	$20(a1),d1	; load touch response number
		andi.b	#$C0,d1		; is touch response $40	or higher?
		beq.w	Touch_Enemy	; if not, branch
		cmpi.b	#$C0,d1		; is touch response $C0	or higher?
		beq.w	Touch_Special	; if yes, branch
		tst.b	d1		; is touch response $80-$BF ?
		bmi.w	Touch_ChkHurt	; if yes, branch

; touch	response is $40-$7F

		move.b	$20(a1),d0
		andi.b	#$3F,d0
		cmpi.b	#6,d0		; is touch response $46	?
		beq.s	Touch_Monitor	; if yes, branch
		cmpi.w	#$5A,$30(a0)
		bcc.w	locret_1AEF2
		addq.b	#2,$24(a1)	; advance the object's routine counter

locret_1AEF2:
		rts	
; ===========================================================================

Touch_Monitor:
		tst.w	$12(a0)		; is Sonic moving upwards?
		bpl.s	loc_1AF1E	; if not, branch
		move.w	$C(a0),d0
		subi.w	#$10,d0
		cmp.w	$C(a1),d0
		bcs.s	locret_1AF2E
		neg.w	$12(a0)		; reverse Sonic's y-motion
		move.w	#-$180,$12(a1)
		tst.b	$25(a1)
		bne.s	locret_1AF2E
		addq.b	#4,$25(a1)	; advance the monitor's routine counter
		rts	
; ===========================================================================

loc_1AF1E:
		cmpi.b	#2,$1C(a0)	; is Sonic rolling/jumping?
		bne.s	locret_1AF2E
		neg.w	$12(a0)		; reverse Sonic's y-motion
		addq.b	#2,$24(a1)	; advance the monitor's routine counter

locret_1AF2E:
		rts	
; ===========================================================================

Touch_Enemy:				; XREF: Touch_ChkValue
		tst.b	(plyr_invincflag).w	; is Sonic invincible?
		bne.s	loc_1AF40	; if yes, branch
		cmpi.b	#2,$1C(a0)	; is Sonic rolling?
		bne.w	Touch_ChkHurt	; if not, branch

loc_1AF40:
		tst.b	$21(a1)
		beq.s	Touch_KillEnemy
		neg.w	$10(a0)
		neg.w	$12(a0)
		asr	$10(a0)
		asr	$12(a0)
		move.b	#0,$20(a1)
		subq.b	#1,$21(a1)
		bne.s	locret_1AF68
		bset	#7,$22(a1)

locret_1AF68:
		rts	
; ===========================================================================

Touch_KillEnemy:
		bset	#7,$22(a1)
		moveq	#0,d0
		move.w	($FFFFF7D0).w,d0
		addq.w	#2,($FFFFF7D0).w ; add 2 to item bonus counter
		cmpi.w	#6,d0
		bcs.s	loc_1AF82
		moveq	#6,d0

loc_1AF82:
		move.w	d0,$3E(a1)
		move.w	Enemy_Points(pc,d0.w),d0
		cmpi.w	#$20,($FFFFF7D0).w ; have 16 enemies been destroyed?
		bcs.s	loc_1AF9C	; if not, branch
		move.w	#1000,d0	; fix bonus to 10000
		move.w	#$A,$3E(a1)

loc_1AF9C:
		bsr.w	AddPoints
		move.b	#$27,0(a1)	; change object	to points
		move.b	#0,$24(a1)
		tst.w	$12(a0)
		bmi.s	loc_1AFC2
		move.w	$C(a0),d0
		cmp.w	$C(a1),d0
		bcc.s	loc_1AFCA
		neg.w	$12(a0)
		rts	
; ===========================================================================

loc_1AFC2:
		addi.w	#$100,$12(a0)
		rts	
; ===========================================================================

loc_1AFCA:
		subi.w	#$100,$12(a0)
		rts	
; ===========================================================================
Enemy_Points:	dc.w 10, 20, 50, 100
; ===========================================================================

loc_1AFDA:				; XREF: Touch_CatKiller
		bset	#7,$22(a1)

Touch_ChkHurt:				; XREF: Touch_ChkValue
		tst.b	(plyr_invincflag).w	; is Sonic invincible?
		beq.s	Touch_Hurt	; if not, branch

loc_1AFE6:				; XREF: Touch_Hurt
		moveq	#-1,d0
		rts	
; ===========================================================================

Touch_Hurt:				; XREF: Touch_ChkHurt
		nop	
		tst.w	$30(a0)
		bne.s	loc_1AFE6
		movea.l	a1,a2

; End of function TouchResponse
; continue straight to HurtSonic

; ---------------------------------------------------------------------------
; Hurting Sonic	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HurtSonic:
		tst.b	(plyr_shieldflag).w	; does Sonic have a shield?
		bne.s	Hurt_Shield	; if yes, branch
		tst.w	(plyr_rings).w	; does Sonic have any rings?
		beq.w	Hurt_NoRings	; if not, branch
		jsr	SingleObjLoad
		bne.s	Hurt_Shield
		move.b	#$37,0(a1)	; load bouncing	multi rings object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Hurt_Shield:
		move.b	#0,(plyr_shieldflag).w ; remove shield
		move.b	#4,$24(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#-$400,$12(a0)	; make Sonic bounce away from the object
		move.w	#-$200,$10(a0)
		btst	#6,$22(a0)
		beq.s	Hurt_Reverse
		move.w	#-$200,$12(a0)
		move.w	#-$100,$10(a0)

Hurt_Reverse:
		move.w	8(a0),d0
		cmp.w	8(a2),d0
		bcs.s	Hurt_ChkSpikes	; if Sonic is left of the object, branch
		neg.w	$10(a0)		; if Sonic is right of the object, reverse

Hurt_ChkSpikes:
		move.w	#0,$14(a0)
		move.b	#$1A,$1C(a0)
		move.w	#$78,$30(a0)
		move.w	#$A3,d0		; load normal damage sound
		cmpi.b	#$36,(a2)	; was damage caused by spikes?
		bne.s	Hurt_Sound	; if not, branch
		cmpi.b	#$16,(a2)	; was damage caused by LZ harpoon?
		bne.s	Hurt_Sound	; if not, branch
		move.w	#$A6,d0		; load spikes damage sound

Hurt_Sound:
		jsr	(Sound_CueSFX).l
		moveq	#-1,d0
		rts	
; ===========================================================================

Hurt_NoRings:
		tst.w	($FFFFFFFA).w	; is debug mode	cheat on?
		bne.w	Hurt_Shield	; if yes, branch
; End of function HurtSonic

; ---------------------------------------------------------------------------
; Subroutine to	kill Sonic
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


KillSonic:
		tst.w	($FFFFFE08).w	; is debug mode	active?
		bne.s	Kill_NoDeath	; if yes, branch
		move.b	#0,(plyr_invincflag).w ; remove invincibility
		move.b	#6,$24(a0)
		bsr.w	Sonic_ResetOnFloor
		bset	#1,$22(a0)
		move.w	#-$700,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$18,$1C(a0)
		bset	#7,2(a0)
		move.w	#$A3,d0		; play normal death sound
		cmpi.b	#$36,(a2)	; check	if you were killed by spikes
		bne.s	Kill_Sound
		move.w	#$A6,d0		; play spikes death sound

Kill_Sound:
		jsr	(Sound_CueSFX).l

Kill_NoDeath:
		moveq	#-1,d0
		rts	
; End of function KillSonic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Touch_Special:				; XREF: Touch_ChkValue
		move.b	$20(a1),d1
		andi.b	#$3F,d1
		cmpi.b	#$B,d1		; is touch response $CB	?
		beq.s	Touch_CatKiller	; if yes, branch
		cmpi.b	#$C,d1		; is touch response $CC	?
		beq.s	Touch_Yadrin	; if yes, branch
		cmpi.b	#$17,d1		; is touch response $D7	?
		beq.s	Touch_D7orE1	; if yes, branch
		cmpi.b	#$21,d1		; is touch response $E1	?
		beq.s	Touch_D7orE1	; if yes, branch
		rts	
; ===========================================================================

Touch_CatKiller:			; XREF: Touch_Special
		bra.w	loc_1AFDA
; ===========================================================================

Touch_Yadrin:				; XREF: Touch_Special
		sub.w	d0,d5
		cmpi.w	#8,d5
		bcc.s	loc_1B144
		move.w	8(a1),d0
		subq.w	#4,d0
		btst	#0,$22(a1)
		beq.s	loc_1B130
		subi.w	#$10,d0

loc_1B130:
		sub.w	d2,d0
		bcc.s	loc_1B13C
		addi.w	#$18,d0
		bcs.s	loc_1B140
		bra.s	loc_1B144
; ===========================================================================

loc_1B13C:
		cmp.w	d4,d0
		bhi.s	loc_1B144

loc_1B140:
		bra.w	Touch_ChkHurt
; ===========================================================================

loc_1B144:
		bra.w	Touch_Enemy
; ===========================================================================

Touch_D7orE1:				; XREF: Touch_Special
		addq.b	#1,$21(a1)
		rts	
; End of function Touch_Special

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 03 - Collision plane/layer switcher (From Sonic 2 [Modified])
; ---------------------------------------------------------------------------

Obj03:
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj03_Index(pc,d0.w),d1
		jsr	Obj03_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.s	Obj03_MarkChkGone
		rts

Obj03_MarkChkGone:
		jmp	Mark_ChkGone
; ===========================================================================
; ---------------------------------------------------------------------------
Obj03_Index:	dc.w Obj03_Init-Obj03_Index
		dc.w Obj03_MainX-Obj03_Index
		dc.w Obj03_MainY-Obj03_Index
; ---------------------------------------------------------------------------
; ===========================================================================
; ---------------------------------------------------------------------------
; Initiation
; ---------------------------------------------------------------------------

Obj03_Init:
		addq.b	#2,$24(a0)
		move.l	#$00000000,$04(a0)
		move.w	#$26BC,$02(a0)
		ori.b	#4,$01(a0)
		move.b	#$10,$19(a0)
		move.b	#5,$18(a0)
		move.b	$28(a0),d0
		btst	#2,d0
		beq.s	Obj03_Init_CheckX

;Obj03_Init_CheckY:
		addq.b	#2,$24(a0) ; => Obj03_MainY
		andi.w	#7,d0
		move.b	d0,$1A(a0)
		andi.w	#3,d0
		add.w	d0,d0
		move.w	word_1FD68(pc,d0.w),$32(a0)
		move.w	$0C(a0),d1
		lea	($FFFFD000).w,a1 ; a1=character
		cmp.w	$0C(a1),d1
		bcc.s	Obj03_Init_Next
		move.b	#1,$34(a0)
Obj03_Init_Next:
	;	lea	(Sidekick).w,a1 ; a1=character
	;	cmp.w	$0C(a1),d1
	;	bcc.s	+
	;	move.b	#1,$35(a0)
;+
		bra.w	Obj03_MainY
; ===========================================================================
word_1FD68:
	dc.w  $020
	dc.w  $040	; 1
	dc.w  $080	; 2
	dc.w  $100	; 3
; ===========================================================================
; loc_1FD70:
Obj03_Init_CheckX:
		andi.w	#3,d0
		move.b	d0,$1A(a0)
		add.w	d0,d0
		move.w	word_1FD68(pc,d0.w),$32(a0)
		move.w	$08(a0),d1
		lea	($FFFFD000).w,a1 ; a1=character
		cmp.w	$08(a1),d1
		bcc.s	Obj03_Init_CheckX_Next
		move.b	#1,$34(a0)
Obj03_Init_CheckX_Next:
	;	lea	(Sidekick).w,a1 ; a1=character
	;	cmp.w	$08(a1),d1
	;	bcc.s	+
	;	move.b	#1,$35(a0)
;+

Obj03_MainX:
		tst.w	($FFFFFE08).w
		bne.w	return_1FEAC
		move.w	$08(a0),d1
		lea	$34(a0),a2
		lea	($FFFFD000).w,a1 ; a1=character
;		bsr.s	+
;		lea	(Sidekick).w,a1 ; a1=character

;+
		tst.b	(a2)+
		bne.s	Obj03_MainX_Alt
		cmp.w	$08(a1),d1
		bhi.w	return_1FEAC
		move.b	#1,-1(a2)
		move.w	$0C(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$0C(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FEAC
		cmp.w	d3,d4
		bge.w	return_1FEAC
		move.b	$28(a0),d0
		bpl.s	Obj03_ICX_B1
		btst	#1,$2B(a1)
		bne.w	return_1FEAC

Obj03_ICX_B1:
		btst	#0,$01(a0)
		bne.s	Obj03_ICX_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#3,d0
		beq.s	Obj03_ICX_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_ICX_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#5,d0
		beq.s	return_1FEAC
		ori.w	#$8000,$02(a1)
		bra.s	return_1FEAC
; ===========================================================================

Obj03_MainX_Alt:
		cmp.w	$08(a1),d1
		bls.w	return_1FEAC
		move.b	#0,-1(a2)
		move.w	$0C(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$0C(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FEAC
		cmp.w	d3,d4
		bge.w	return_1FEAC
		move.b	$28(a0),d0
		bpl.s	Obj03_MXA_B1
		btst	#1,$2B(a1)
		bne.w	return_1FEAC

Obj03_MXA_B1:
		btst	#0,$01(a0)
		bne.s	Obj03_MXA_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#4,d0
		beq.s	Obj03_MXA_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_MXA_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#6,d0
		beq.s	return_1FEAC
		ori.w	#$8000,$02(a1)

return_1FEAC:
		rts

; ===========================================================================

Obj03_MainY:
		tst.w	($FFFFFE08).w
		bne.w	return_1FFB6
		move.w	$0C(a0),d1
		lea	$34(a0),a2
		lea	($FFFFD000).w,a1 ; a1=character
;		bsr.s	+
;		lea	(Sidekick).w,a1 ; a1=character

;+
		tst.b	(a2)+
		bne.s	Obj03_MainY_Alt
		cmp.w	$0C(a1),d1
		bhi.w	return_1FFB6
		move.b	#1,-1(a2)
		move.w	$08(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$08(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FFB6
		cmp.w	d3,d4
		bge.w	return_1FFB6
		move.b	$28(a0),d0
		bpl.s	Obj03_MY_B1
		btst	#1,$2B(a1)
		bne.w	return_1FFB6

Obj03_MY_B1:
		btst	#0,$01(a0)
		bne.s	Obj03_MY_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#3,d0
		beq.s	Obj03_MY_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_MY_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#5,d0
		beq.s	return_1FFB6
		ori.w	#$8000,$02(a1)
		bra.s	return_1FFB6

; ===========================================================================

Obj03_MainY_Alt:
		cmp.w	$0C(a1),d1
		bls.w	return_1FFB6
		move.b	#0,-1(a2)
		move.w	$08(a0),d2
		move.w	d2,d3
		move.w	$32(a0),d4
		sub.w	d4,d2
		add.w	d4,d3
		move.w	$08(a1),d4
		cmp.w	d2,d4
		blt.w	return_1FFB6
		cmp.w	d3,d4
		bge.w	return_1FFB6
		move.b	$28(a0),d0
		bpl.s	Obj03_MYA_B1
		btst	#1,$2B(a1)
		bne.w	return_1FFB6

Obj03_MYA_B1
		btst	#0,$01(a0)
		bne.s	Obj03_MYA_B2
			move.b	#$00,($FFFFFFF7).w
	;	move.b	#$C,$3E(a1)
	;	move.b	#$D,$3F(a1)
		btst	#4,d0
		beq.s	Obj03_MYA_B2
			move.b	#$01,($FFFFFFF7).w
	;	move.b	#$E,$3E(a1)
	;	move.b	#$F,$3F(a1)

Obj03_MYA_B2:
		andi.w	#$7FFF,$02(a1)
		btst	#6,d0
		beq.s	return_1FFB6
		ori.w	#$8000,$02(a1)

return_1FFB6:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	animate	level graphics
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AniArt_Load:				; XREF: Demo_Time; loc_F54
		tst.w	(gm_paused).w	; is the game paused?
		bne.s	AniArt_Pause	; if yes, branch
		lea	($C00000).l,a6
		moveq	#0,d0
		move.b	(lvl_id).w,d0
		add.w	d0,d0
		move.w	AniArt_Index(pc,d0.w),d0
		jmp	AniArt_Index(pc,d0.w)
; ===========================================================================

AniArt_Pause:
		rts	
; End of function AniArt_Load

; ===========================================================================
AniArt_Index:	dc.w AniArt_GHZ-AniArt_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Green Hill
; ---------------------------------------------------------------------------

AniArt_GHZ:				; XREF: AniArt_Index
		rts
; ===========================================================================

AniArt_none:				; XREF: AniArt_Index
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	load (d1 - 1) 8x8 tiles
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTiles:
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		dbf	d1,LoadTiles
		rts	
; End of function LoadTiles

; ===========================================================================

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 21 - SCORE, TIME, RINGS
; ---------------------------------------------------------------------------

Obj21:					; XREF: Obj_Index
		moveq	#0,d0
		move.b	$24(a0),d0
		move.w	Obj21_Index(pc,d0.w),d1
		jmp	Obj21_Index(pc,d1.w)
; ===========================================================================
Obj21_Index:	dc.w Obj21_Main-Obj21_Index
		dc.w Obj21_Flash-Obj21_Index
; ===========================================================================

Obj21_Main:				; XREF: Obj21_Main
		addq.b	#2,$24(a0)
		move.w	#$90,8(a0)
		move.w	#$108,$A(a0)
		move.l	#Map_obj21,4(a0)
		move.w	#$6CA,2(a0)
		move.b	#0,1(a0)
		move.b	#0,$18(a0)

Obj21_Flash:				; XREF: Obj21_Main
		tst.w	(plyr_rings).w	; do you have any rings?
		beq.s	Obj21_Flash2	; if not, branch
		clr.b	$1A(a0)		; make all counters yellow
		jmp	Actor_Display
; ===========================================================================

Obj21_Flash2:
		moveq	#0,d0
		btst	#3,($FFFFFE05).w
		bne.s	Obj21_Display
		addq.w	#1,d0		; make ring counter flash red
		cmpi.b	#9,($FFFFFE23).w ; have	9 minutes elapsed?
		bne.s	Obj21_Display	; if not, branch
		addq.w	#2,d0		; make time counter flash red

Obj21_Display:
		move.b	d0,$1A(a0)
		jmp	Actor_Display
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - SCORE, TIME, RINGS
; ---------------------------------------------------------------------------
Map_obj21:
	include "_maps\obj21.asm"

; ---------------------------------------------------------------------------
; Add points subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AddPoints:
		move.b	#1,($FFFFFE1F).w ; set score counter to	update
		lea	(score_next1up).w,a2
		lea	($FFFFFE26).w,a3
		add.l	d0,(a3)		; add d0*10 to the score
		move.l	#999999,d1
		cmp.l	(a3),d1		; is #999999 higher than the score?
		bhi.w	loc_1C6AC	; if yes, branch
		move.l	d1,(a3)		; reset	score to #999999
		move.l	d1,(a2)

loc_1C6AC:
		move.l	(a3),d0
		cmp.l	(a2),d0
		bcs.w	locret_1C6B6
		move.l	d0,(a2)

locret_1C6B6:
		rts	
; End of function AddPoints

; ---------------------------------------------------------------------------
; Subroutine to	update the HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HudUpdate:
		tst.b	($FFFFFE1F).w	; does the score need updating?
		beq.s	Hud_ChkRings	; if not, branch
		clr.b	($FFFFFE1F).w
		move.l	#$5C800003,d0	; set VRAM address
		move.l	($FFFFFE26).w,d1 ; load	score
		bsr.w	Hud_Score

Hud_ChkRings:
		tst.b	($FFFFFE1D).w	; does the ring	counter	need updating?
		beq.s	Hud_ChkTime	; if not, branch
		bpl.s	loc_1C6E4
		bsr.w	Hud_LoadZero

loc_1C6E4:
		clr.b	($FFFFFE1D).w
		move.l	#$5F400003,d0	; set VRAM address
		moveq	#0,d1
		move.w	(plyr_rings).w,d1 ; load	number of rings
		bsr.w	Hud_Rings

Hud_ChkTime:
		tst.b	($FFFFFE1E).w	; does the time	need updating?
		beq.s	Hud_ChkLives	; if not, branch
		tst.w	(gm_paused).w	; is the game paused?
		bne.s	Hud_ChkLives	; if yes, branch
		lea	(time_minutes).w,a1
		cmpi.l	#$93B3B,(a1)+	; is the time 9.59?
		beq.s	TimeOver	; if yes, branch
		addq.b	#1,-(a1)
		cmpi.b	#60,(a1)
		bcs.s	Hud_ChkLives
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#60,(a1)
		bcs.s	loc_1C734
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#9,(a1)
		bcs.s	loc_1C734
		move.b	#9,(a1)

loc_1C734:
		move.l	#$5E400003,d0
		moveq	#0,d1
		move.b	($FFFFFE23).w,d1 ; load	minutes
		bsr.w	Hud_Mins
		move.l	#$5EC00003,d0
		moveq	#0,d1
		move.b	(time_seconds).w,d1 ; load	seconds
		bsr.w	Hud_Secs

Hud_ChkLives:
		tst.b	($FFFFF7D6).w	; do time/ring bonus counters need updating?
		beq.s	Hud_End		; if not, branch
		clr.b	($FFFFF7D6).w
		move.l	#$6E000002,($C00004).l
		moveq	#0,d1
		move.w	($FFFFF7D2).w,d1 ; load	time bonus
		bsr.w	Hud_TimeRingBonus
		moveq	#0,d1
		move.w	($FFFFF7D4).w,d1 ; load	ring bonus
		bsr.w	Hud_TimeRingBonus

Hud_End:
		rts	
; ===========================================================================

TimeOver:				; XREF: Hud_ChkTime
		clr.b	($FFFFFE1E).w
		lea	($FFFFD000).w,a0
		movea.l	a0,a2
		bsr.w	KillSonic
		move.b	#1,(plyr_air).w
		rts	
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	load "0" on the	HUD
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_LoadZero:				; XREF: HudUpdate
		move.l	#$5F400003,($C00004).l
		lea	Hud_TilesZero(pc),a2
		move.w	#2,d2
		bra.s	loc_1C83E
; End of function Hud_LoadZero

; ---------------------------------------------------------------------------
; Subroutine to	load uncompressed HUD patterns ("E", "0", colon)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Base:				; XREF: Level; SS_EndLoop; EndingSequence
		lea	($C00000).l,a6
		move.l	#$5C400003,($C00004).l
		lea	Hud_TilesBase(pc),a2
		move.w	#$E,d2

loc_1C83E:				; XREF: Hud_LoadZero
		lea	Art_Hud(pc),a1

loc_1C842:
		move.w	#$F,d1
		move.b	(a2)+,d0
		bmi.s	loc_1C85E
		ext.w	d0
		lsl.w	#5,d0
		lea	(a1,d0.w),a3

loc_1C852:
		move.l	(a3)+,(a6)
		dbf	d1,loc_1C852

loc_1C858:
		dbf	d2,loc_1C842

		rts	
; ===========================================================================

loc_1C85E:
		move.l	#0,(a6)
		dbf	d1,loc_1C85E

		bra.s	loc_1C858
; End of function Hud_Base

; ===========================================================================
Hud_TilesBase:	dc.b $16, $FF, $FF, $FF, $FF, $FF, $FF,	0, 0, $14, 0, 0
Hud_TilesZero:	dc.b $FF, $FF, 0, 0

; ---------------------------------------------------------------------------
; Subroutine to	load rings numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Rings:				; XREF: HudUpdate
		lea	(Hud_100).l,a2
		moveq	#2,d6
		bra.s	Hud_LoadArt
; End of function Hud_Rings

; ---------------------------------------------------------------------------
; Subroutine to	load score numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Score:				; XREF: HudUpdate
		lea	(Hud_100000).l,a2
		moveq	#5,d6

Hud_LoadArt:
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_ScoreLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C8EC:
		sub.l	d3,d1
		bcs.s	loc_1C8F4
		addq.w	#1,d2
		bra.s	loc_1C8EC
; ===========================================================================

loc_1C8F4:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1C8FE
		move.w	#1,d4

loc_1C8FE:
		tst.w	d4
		beq.s	loc_1C92C
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1C92C:
		addi.l	#$400000,d0
		dbf	d6,Hud_ScoreLoop

		rts	
; End of function Hud_Score

; ---------------------------------------------------------------------------
; Subroutine to	load countdown numbers on the continue screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ContScrCounter:				; XREF: ContinueScreen
		move.l	#$5F800003,($C00004).l ; set VRAM address
		lea	($C00000).l,a6
		lea	(Hud_10).l,a2
		moveq	#1,d6
		moveq	#0,d4
		lea	Art_Hud(pc),a1 ; load numbers patterns

ContScr_Loop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C95A:
		sub.l	d3,d1
		bcs.s	loc_1C962
		addq.w	#1,d2
		bra.s	loc_1C95A
; ===========================================================================

loc_1C962:
		add.l	d3,d1
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		dbf	d6,ContScr_Loop	; repeat 1 more	time

		rts	
; End of function ContScrCounter

; ===========================================================================
; ---------------------------------------------------------------------------
; HUD counter sizes
; ---------------------------------------------------------------------------
Hud_100000:	dc.l 100000		; XREF: Hud_Score
Hud_10000:	dc.l 10000
Hud_1000:	dc.l 1000		; XREF: Hud_TimeRingBonus
Hud_100:	dc.l 100		; XREF: Hud_Rings
Hud_10:		dc.l 10			; XREF: ContScrCounter; Hud_Secs; Hud_Lives
Hud_1:		dc.l 1			; XREF: Hud_Mins

; ---------------------------------------------------------------------------
; Subroutine to	load time numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Mins:				; XREF: Hud_ChkTime
		lea	(Hud_1).l,a2
		moveq	#0,d6
		bra.s	loc_1C9BA
; End of function Hud_Mins


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_Secs:				; XREF: Hud_ChkTime
		lea	(Hud_10).l,a2
		moveq	#1,d6

loc_1C9BA:
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_TimeLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1C9C4:
		sub.l	d3,d1
		bcs.s	loc_1C9CC
		addq.w	#1,d2
		bra.s	loc_1C9C4
; ===========================================================================

loc_1C9CC:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1C9D6
		move.w	#1,d4

loc_1C9D6:
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		addi.l	#$400000,d0
		dbf	d6,Hud_TimeLoop

		rts	
; End of function Hud_Secs

; ---------------------------------------------------------------------------
; Subroutine to	load time/ring bonus numbers patterns
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hud_TimeRingBonus:			; XREF: Hud_ChkBonus
		lea	(Hud_1000).l,a2
		moveq	#3,d6
		moveq	#0,d4
		lea	Art_Hud(pc),a1

Hud_BonusLoop:
		moveq	#0,d2
		move.l	(a2)+,d3

loc_1CA1E:
		sub.l	d3,d1
		bcs.s	loc_1CA26
		addq.w	#1,d2
		bra.s	loc_1CA1E
; ===========================================================================

loc_1CA26:
		add.l	d3,d1
		tst.w	d2
		beq.s	loc_1CA30
		move.w	#1,d4

loc_1CA30:
		tst.w	d4
		beq.s	Hud_ClrBonus
		lsl.w	#6,d2
		lea	(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)

loc_1CA5A:
		dbf	d6,Hud_BonusLoop ; repeat 3 more times

		rts	
; ===========================================================================

Hud_ClrBonus:
		moveq	#$F,d5

Hud_ClrBonusLoop:
		move.l	#0,(a6)
		dbf	d5,Hud_ClrBonusLoop

		bra.s	loc_1CA5A
; End of function Hud_TimeRingBonus

; ===========================================================================
Art_Hud:	incbin	"Action Stage/Global/HUD/Number Tiles.unc"	; 8x16 pixel numbers on HUD
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Main level load blocks
;
; ===FORMAT===
; level	patterns + (1st	PLC num	* 10^6)
; 16x16	mappings + (2nd	PLC num	* 10^6)
; 256x256 mappings
; blank, music (unused), pal index (unused), pal index
; ---------------------------------------------------------------------------
MainLoadBlocks:
	dc.l Nem_GHZ+$4000000
	dc.l Blk16_GHZ+$5000000
	dc.l Blk256_GHZ
	dc.b 0,	$81, 4,	4
	even

; ---------------------------------------------------------------------------
; Pattern load cues
; ---------------------------------------------------------------------------
ArtLoadCues:
	dc.w PLC_Main-ArtLoadCues, PLC_Main2-ArtLoadCues
	dc.w PLC_Explode-ArtLoadCues, PLC_GameOver-ArtLoadCues
	dc.w PLC_GHZ-ArtLoadCues, PLC_GHZ2-ArtLoadCues
	dc.w PLC_LZ-ArtLoadCues, PLC_LZ2-ArtLoadCues
	dc.w PLC_MZ-ArtLoadCues, PLC_MZ2-ArtLoadCues
	dc.w PLC_SLZ-ArtLoadCues, PLC_SLZ2-ArtLoadCues
	dc.w PLC_SYZ-ArtLoadCues, PLC_SYZ2-ArtLoadCues
	dc.w PLC_SBZ-ArtLoadCues, PLC_SBZ2-ArtLoadCues
	dc.w PLC_TitleCard-ArtLoadCues,	PLC_Boss-ArtLoadCues
	dc.w PLC_Signpost-ArtLoadCues, PLC_Signpost-ArtLoadCues
	dc.w PLC_Signpost-ArtLoadCues, PLC_GHZAnimals-ArtLoadCues
; ---------------------------------------------------------------------------
; Pattern load cues - standard block 1
; ---------------------------------------------------------------------------
PLC_Main:	dc.w 3
		dc.l Nem_Lamp		; lamppost
		dc.w $F400
		dc.l Nem_Hud		; HUD
		dc.w $D940
		dc.l Nem_Lives		; lives	counter
		dc.w $FA80
		dc.l Nem_Ring		; rings
		dc.w $F640
; ---------------------------------------------------------------------------
; Pattern load cues - standard block 2
; ---------------------------------------------------------------------------
PLC_Main2:	dc.w 2
		dc.l Nem_Monitors	; monitors
		dc.w $D000
		dc.l Nem_Shield		; shield
		dc.w $A820
		dc.l Nem_Stars		; invincibility	stars
		dc.w $AB80
; ---------------------------------------------------------------------------
; Pattern load cues - explosion
; ---------------------------------------------------------------------------
PLC_Explode:	dc.w 0
		dc.l Nem_Explode	; explosion
		dc.w $B400
; ---------------------------------------------------------------------------
; Pattern load cues - game/time	over
; ---------------------------------------------------------------------------
PLC_GameOver:
; ---------------------------------------------------------------------------
; Pattern load cues - Green Hill
; ---------------------------------------------------------------------------
PLC_GHZ:	dc.w 1
		dc.l Nem_GHZ		; GHZ main patterns
		dc.w 0
		dc.l Nem_Spikes		; spikes
		dc.w $A360
PLC_GHZ2:	dc.w 1
		dc.l Nem_HSpring	; horizontal spring
		dc.w $A460
		dc.l Nem_VSpring	; vertical spring
		dc.w $A660
; ---------------------------------------------------------------------------
; Pattern load cues - Labyrinth
; ---------------------------------------------------------------------------
PLC_LZ:
PLC_LZ2:
; ---------------------------------------------------------------------------
; Pattern load cues - Marble
; ---------------------------------------------------------------------------
PLC_MZ:
PLC_MZ2:
; ---------------------------------------------------------------------------
; Pattern load cues - Star Light
; ---------------------------------------------------------------------------
PLC_SLZ:
PLC_SLZ2:
; ---------------------------------------------------------------------------
; Pattern load cues - Spring Yard
; ---------------------------------------------------------------------------
PLC_SYZ:
PLC_SYZ2:
; ---------------------------------------------------------------------------
; Pattern load cues - Scrap Brain
; ---------------------------------------------------------------------------
PLC_SBZ:
PLC_SBZ2:
; ---------------------------------------------------------------------------
; Pattern load cues - title card
; ---------------------------------------------------------------------------
PLC_TitleCard:	dc.w 0
		dc.l Nem_TitleCard
		dc.w $B000
; ---------------------------------------------------------------------------
; Pattern load cues - act 3 boss
; ---------------------------------------------------------------------------
PLC_Boss:
; ---------------------------------------------------------------------------
; Pattern load cues - act 1/2 signpost
; ---------------------------------------------------------------------------
PLC_Signpost:	dc.w 0
		dc.l Nem_Prison		; prison capsule
		dc.w $93A0
; ---------------------------------------------------------------------------
; Pattern load cues - GHZ animals
; ---------------------------------------------------------------------------
PLC_GHZAnimals:	dc.w 1
		dc.l Nem_Rabbit		; rabbit
		dc.w $B000
		dc.l Nem_Flicky		; flicky
		dc.w $B240
		even

; ----------<Title Screen Data>----------

Title_Tiles:
		incbin	"Title Screen/Tiles.nem"
		even

TitleNorm_Pal:
		incbin	"Title Screen/Normal.pal"
		even

TitleLight_Pal:
		incbin	"Title Screen/Light.pal"
		even

Title_BGAMaps:
		incbin	"Title Screen/BG A.eni"
		even

Title_BGBMaps:
		incbin	"Title Screen/BG B.eni"
		even

; ---------------------------------------------------------------------------
; Sprite mappings - Sonic
; ---------------------------------------------------------------------------
Map_Sonic:
	include "Action Stage/Global/Actors/Players/Sonic Maps.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	loading	array for Sonic
; ---------------------------------------------------------------------------
SonicDynPLC:
	include "Action Stage/Global/Actors/Players/Sonic DPLCs.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	- Sonic
; ---------------------------------------------------------------------------
Art_Sonic:	incbin	"Action Stage/Global/Actors/Players/Sonic Tiles.unc"	; Sonic
		even

Action_MainPal:
		incbin	"Action Stage/Global/Main.pal"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_Shield:	incbin	artnem\shield.bin	; shield
		even
Nem_Stars:	incbin	artnem\invstars.bin	; invincibility stars
		even
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Spikes:	incbin	artnem\spikes.bin	; spikes
		even
; ---------------------------------------------------------------------------
; Compressed graphics - LZ stuff
; ---------------------------------------------------------------------------
Nem_Water:	incbin	artnem\lzwater.bin	; LZ water surface
		even
Nem_Splash:	incbin	artnem\lzsplash.bin	; LZ waterfalls and splashes
		even
Nem_Bubbles:	incbin	artnem\lzbubble.bin	; LZ bubbles and countdown numbers
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_TitleCard:	incbin	artnem\ttlcards.bin	; title cards
		even
Nem_Hud:	incbin	artnem\hud.bin		; HUD (rings, time, score)
		even
Nem_Lives:	incbin	artnem\lifeicon.bin	; life counter icon
		even
Nem_Ring:	incbin	artnem\rings.bin	; rings
		even
Nem_Monitors:	incbin	"Action Stage/Global/Actors/Item Box/Tiles.nem"	; monitors
		even
Nem_Explode:	incbin	artnem\explosio.bin	; explosion
		even
Nem_HSpring:	incbin	artnem\springh.bin	; horizontal spring
		even
Nem_VSpring:	incbin	artnem\springv.bin	; vertical spring
		even
Nem_Lamp:	incbin	artnem\lamppost.bin	; lamppost
		even
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Prison:	incbin	artnem\prison.bin
		even
Nem_Rabbit:	incbin	artnem\rabbit.bin	; rabbit
		even
Nem_Flicky:	incbin	artnem\flicky.bin	; flicky
		even
; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------

Blk16_GHZ:	incbin	"Action Stage/Emerald/Blocks.eni"
		even
Nem_GHZ:	incbin	"Action Stage/Emerald/Tiles.nem"	; GHZ primary patterns
		even
Blk256_GHZ:	incbin	"Action Stage/Emerald/Chunks.kos"
		even
; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	incbin	"Action Stage/Global/Angle Maps.bin"	; floor angle map
		even
CollArray1:	incbin	"Action Stage/Global/Coll Array Norm.bin"	; normal collision array
		even
CollArray2:	incbin	"Action Stage/Global/Coll Array Rot.bin"	; rotated collision array
		even
Col_GHZ_1:	incbin	"Action Stage/Emerald/Path 1.col"	; GHZ index 1
		even
Col_GHZ_2:	incbin	"Action Stage/Emerald/Path 2.col"	; GHZ index 2
		even

; ---------------------------------------------------------------------------
; Level	layout index
; ---------------------------------------------------------------------------
Level_Index:
        dc.l Level_GHZ1

Layout_Null:    dc.l 0

Level_GHZ1:	incbin	"Action Stage/Emerald/Layout.bin"
		even

; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
ObjPos_Index:	dc.w ObjPos_GHZ1-ObjPos_Index
		dc.b $FF, $FF, 0, 0, 0,	0
ObjPos_GHZ1:	incbin	"Action Stage/Emerald/Sonic Actors.act"
		even
ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0,	0
; ---------------------------------------------------------------------------

Go_SoundTypes:	dc.l SoundTypes		; XREF: Sound_Play
Go_SoundD0:	dc.l SoundD0Index	; XREF: Sound_D0toDF
Go_MusicIndex:	dc.l MusicIndex		; XREF: Sound_81to9F
Go_SoundIndex:	dc.l SoundIndex		; XREF: Sound_A0toCF
off_719A0:	dc.l byte_71A94		; XREF: Sound_81to9F
Go_PSGIndex:	dc.l PSG_Index		; XREF: sub_72926
; ---------------------------------------------------------------------------
; PSG instruments used in music
; ---------------------------------------------------------------------------
PSG_Index:	dc.l PSG1, PSG2, PSG3
		dc.l PSG4, PSG5, PSG6
		dc.l PSG7, PSG8, PSG9
PSG1:		incbin	sound\psg1.bin
PSG2:		incbin	sound\psg2.bin
PSG3:		incbin	sound\psg3.bin
PSG4:		incbin	sound\psg4.bin
PSG6:		incbin	sound\psg6.bin
PSG5:		incbin	sound\psg5.bin
PSG7:		incbin	sound\psg7.bin
PSG8:		incbin	sound\psg8.bin
PSG9:		incbin	sound\psg9.bin

byte_71A94:	dc.b 7,	$72, $73, $26, $15, 8, $FF, 5
; ---------------------------------------------------------------------------
; Music	Pointers
; ---------------------------------------------------------------------------
MusicIndex:	dc.l Music81, Music82
		dc.l Music83, Music84
		dc.l Music85, Music86
		dc.l Music87, Music88
		dc.l Music89, Music8A
		dc.l Music8B, Music8C
		dc.l Music8D, Music8E
		dc.l Music8F, Music90
		dc.l Music91, Music92
		dc.l Music93
; ---------------------------------------------------------------------------
; Type of sound	being played ($90 = music; $70 = normal	sound effect)
; ---------------------------------------------------------------------------
SoundTypes:	dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$90
		dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$80
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $68, $70, $70, $70, $60, $70,	$70
		dc.b $60, $70, $60, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $7F,	$60
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $70,	$80
		dc.b $80, $80, $80, $80, $80, $80, $80,	$80, $80, $80, $80, $80, $80, $80, $80,	$90
		dc.b $90, $90, $90, $90

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71B4C:				; XREF: loc_B10; PalToCRAM
		move.w	#$100,($A11100).l ; stop the Z80
		nop	
		nop	
		nop	

loc_71B5A:
		btst	#0,($A11100).l
		bne.s	loc_71B5A

		btst	#7,($A01FFD).l
		beq.s	loc_71B82
		move.w	#0,($A11100).l	; start	the Z80
		nop	
		nop	
		nop	
		nop	
		nop	
		bra.s	sub_71B4C
; ===========================================================================

loc_71B82:
		lea	($FFF000).l,a6
		clr.b	$E(a6)
		tst.b	3(a6)		; is music paused?
		bne.w	loc_71E50	; if yes, branch
		subq.b	#1,1(a6)
		bne.s	loc_71B9E
		jsr	sub_7260C(pc)

loc_71B9E:
		move.b	4(a6),d0
		beq.s	loc_71BA8
		jsr	sub_72504(pc)

loc_71BA8:
		tst.b	$24(a6)
		beq.s	loc_71BB2
		jsr	sub_7267C(pc)

loc_71BB2:
		tst.w	$A(a6)		; is music or sound being played?
		beq.s	loc_71BBC	; if not, branch
		jsr	Sound_Play(pc)

loc_71BBC:
		cmpi.b	#$80,9(a6)
		beq.s	loc_71BC8
		jsr	Sound_ChkValue(pc)

loc_71BC8:
		lea	$40(a6),a5
		tst.b	(a5)
		bpl.s	loc_71BD4
		jsr	sub_71C4E(pc)

loc_71BD4:
		clr.b	8(a6)
		moveq	#5,d7

loc_71BDA:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71BE6
		jsr	sub_71CCA(pc)

loc_71BE6:
		dbf	d7,loc_71BDA

		moveq	#2,d7

loc_71BEC:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71BF8
		jsr	sub_72850(pc)

loc_71BF8:
		dbf	d7,loc_71BEC

		move.b	#$80,$E(a6)
		moveq	#2,d7

loc_71C04:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C10
		jsr	sub_71CCA(pc)

loc_71C10:
		dbf	d7,loc_71C04

		moveq	#2,d7

loc_71C16:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C22
		jsr	sub_72850(pc)

loc_71C22:
		dbf	d7,loc_71C16
		move.b	#$40,$E(a6)
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C38
		jsr	sub_71CCA(pc)

loc_71C38:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.s	loc_71C44
		jsr	sub_72850(pc)

loc_71C44:
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function sub_71B4C


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71C4E:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	locret_71CAA
		move.b	#$80,8(a6)
		movea.l	4(a5),a4

loc_71C5E:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.s	loc_71C6E
		jsr	sub_72A5A(pc)
		bra.s	loc_71C5E
; ===========================================================================

loc_71C6E:
		tst.b	d5
		bpl.s	loc_71C84
		move.b	d5,$10(a5)
		move.b	(a4)+,d5
		bpl.s	loc_71C84
		subq.w	#1,a4
		move.b	$F(a5),$E(a5)
		bra.s	loc_71C88
; ===========================================================================

loc_71C84:
		jsr	sub_71D40(pc)

loc_71C88:
		move.l	a4,4(a5)
		btst	#2,(a5)
		bne.s	locret_71CAA
		moveq	#0,d0
		move.b	$10(a5),d0
		cmpi.b	#$80,d0
		beq.s	locret_71CAA
		btst	#3,d0
		bne.s	loc_71CAC
		move.b	d0,($A01FFF).l

locret_71CAA:
		rts	
; ===========================================================================

loc_71CAC:
		subi.b	#$88,d0
		move.b	byte_71CC4(pc,d0.w),d0
		move.b	d0,($A000EA).l
		move.b	#$83,($A01FFF).l
		rts	
; End of function sub_71C4E

; ===========================================================================
byte_71CC4:	dc.b $12, $15, $1C, $1D, $FF, $FF

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CCA:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	loc_71CE0
		bclr	#4,(a5)
		jsr	sub_71CEC(pc)
		jsr	sub_71E18(pc)
		bra.w	loc_726E2
; ===========================================================================

loc_71CE0:
		jsr	sub_71D9E(pc)
		jsr	sub_71DC6(pc)
		bra.w	loc_71E24
; End of function sub_71CCA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CEC:				; XREF: sub_71CCA
		movea.l	4(a5),a4
		bclr	#1,(a5)

loc_71CF4:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.s	loc_71D04
		jsr	sub_72A5A(pc)
		bra.s	loc_71CF4
; ===========================================================================

loc_71D04:
		jsr	sub_726FE(pc)
		tst.b	d5
		bpl.s	loc_71D1A
		jsr	sub_71D22(pc)
		move.b	(a4)+,d5
		bpl.s	loc_71D1A
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_71D1A:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_71CEC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D22:				; XREF: sub_71CEC
		subi.b	#$80,d5
		beq.s	loc_71D58
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_72790(pc),a0
		move.w	(a0,d5.w),d6
		move.w	d6,$10(a5)
		rts	
; End of function sub_71D22


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D40:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		move.b	d5,d0
		move.b	2(a5),d1

loc_71D46:
		subq.b	#1,d1
		beq.s	loc_71D4E
		add.b	d5,d0
		bra.s	loc_71D46
; ===========================================================================

loc_71D4E:
		move.b	d0,$F(a5)
		move.b	d0,$E(a5)
		rts	
; End of function sub_71D40

; ===========================================================================

loc_71D58:				; XREF: sub_71D22
		bset	#1,(a5)
		clr.w	$10(a5)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D60:				; XREF: sub_71CEC; sub_72878; sub_728AC
		move.l	a4,4(a5)
		move.b	$F(a5),$E(a5)
		btst	#4,(a5)
		bne.s	locret_71D9C
		move.b	$13(a5),$12(a5)
		clr.b	$C(a5)
		btst	#3,(a5)
		beq.s	locret_71D9C
		movea.l	$14(a5),a0
		move.b	(a0)+,$18(a5)
		move.b	(a0)+,$19(a5)
		move.b	(a0)+,$1A(a5)
		move.b	(a0)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)

locret_71D9C:
		rts	
; End of function sub_71D60


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D9E:				; XREF: sub_71CCA; sub_72850
		tst.b	$12(a5)
		beq.s	locret_71DC4
		subq.b	#1,$12(a5)
		bne.s	locret_71DC4
		bset	#1,(a5)
		tst.b	1(a5)
		bmi.w	loc_71DBE
		jsr	sub_726FE(pc)
		addq.w	#4,sp
		rts	
; ===========================================================================

loc_71DBE:
		jsr	sub_729A0(pc)
		addq.w	#4,sp

locret_71DC4:
		rts	
; End of function sub_71D9E


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71DC6:				; XREF: sub_71CCA; sub_72850
		addq.w	#4,sp
		btst	#3,(a5)
		beq.s	locret_71E16
		tst.b	$18(a5)
		beq.s	loc_71DDA
		subq.b	#1,$18(a5)
		rts	
; ===========================================================================

loc_71DDA:
		subq.b	#1,$19(a5)
		beq.s	loc_71DE2
		rts	
; ===========================================================================

loc_71DE2:
		movea.l	$14(a5),a0
		move.b	1(a0),$19(a5)
		tst.b	$1B(a5)
		bne.s	loc_71DFE
		move.b	3(a0),$1B(a5)
		neg.b	$1A(a5)
		rts	
; ===========================================================================

loc_71DFE:
		subq.b	#1,$1B(a5)
		move.b	$1A(a5),d6
		ext.w	d6
		add.w	$1C(a5),d6
		move.w	d6,$1C(a5)
		add.w	$10(a5),d6
		subq.w	#4,sp

locret_71E16:
		rts	
; End of function sub_71DC6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71E18:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.s	locret_71E48
		move.w	$10(a5),d6
		beq.s	loc_71E4A

loc_71E24:				; XREF: sub_71CCA
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.s	locret_71E48
		move.w	d6,d1
		lsr.w	#8,d1
		move.b	#-$5C,d0
		jsr	sub_72722(pc)
		move.b	d6,d1
		move.b	#-$60,d0
		jsr	sub_72722(pc)

locret_71E48:
		rts	
; ===========================================================================

loc_71E4A:
		bset	#1,(a5)
		rts	
; End of function sub_71E18

; ===========================================================================

loc_71E50:				; XREF: sub_71B4C
		bmi.s	loc_71E94
		cmpi.b	#2,3(a6)
		beq.w	loc_71EFE
		move.b	#2,3(a6)
		moveq	#2,d3
		move.b	#-$4C,d0
		moveq	#0,d1

loc_71E6A:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.b	#1,d0
		dbf	d3,loc_71E6A

		moveq	#2,d3
		moveq	#$28,d0

loc_71E7C:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbf	d3,loc_71E7C

		jsr	sub_729B6(pc)
		bra.w	loc_71C44
; ===========================================================================

loc_71E94:				; XREF: loc_71E50
		clr.b	3(a6)
		moveq	#$30,d3
		lea	$40(a6),a5
		moveq	#6,d4

loc_71EA0:
		btst	#7,(a5)
		beq.s	loc_71EB8
		btst	#2,(a5)
		bne.s	loc_71EB8
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EB8:
		adda.w	d3,a5
		dbf	d4,loc_71EA0

		lea	$220(a6),a5
		moveq	#2,d4

loc_71EC4:
		btst	#7,(a5)
		beq.s	loc_71EDC
		btst	#2,(a5)
		bne.s	loc_71EDC
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EDC:
		adda.w	d3,a5
		dbf	d4,loc_71EC4

		lea	$340(a6),a5
		btst	#7,(a5)
		beq.s	loc_71EFE
		btst	#2,(a5)
		bne.s	loc_71EFE
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EFE:
		bra.w	loc_71C44

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_Play:				; XREF: sub_71B4C
		movea.l	(Go_SoundTypes).l,a0
		lea	$A(a6),a1	; load music track number
		move.b	0(a6),d3
		moveq	#2,d4

loc_71F12:
		move.b	(a1),d0		; move track number to d0
		move.b	d0,d1
		clr.b	(a1)+
		subi.b	#$81,d0
		bcs.s	loc_71F3E
		cmpi.b	#$80,9(a6)
		beq.s	loc_71F2C
		move.b	d1,$A(a6)
		bra.s	loc_71F3E
; ===========================================================================

loc_71F2C:
		andi.w	#$7F,d0
		move.b	(a0,d0.w),d2
		cmp.b	d3,d2
		bcs.s	loc_71F3E
		move.b	d2,d3
		move.b	d1,9(a6)	; set music flag

loc_71F3E:
		dbf	d4,loc_71F12

		tst.b	d3
		bmi.s	locret_71F4A
		move.b	d3,0(a6)

locret_71F4A:
		rts	
; End of function Sound_Play


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_ChkValue:				; XREF: sub_71B4C
		moveq	#0,d7
		move.b	9(a6),d7
		beq.w	Sound_E4
		bpl.s	locret_71F8C
		move.b	#$80,9(a6)	; reset	music flag
		cmpi.b	#$9F,d7
		bls.w	Sound_81to9F	; music	$81-$9F
		cmpi.b	#$A0,d7
		bcs.w	locret_71F8C
		cmpi.b	#$CF,d7
		bls.w	Sound_A0toCF	; sound	$A0-$CF
		cmpi.b	#$D0,d7
		bcs.w	locret_71F8C
		cmpi.b	#$E0,d7
		bcs.w	Sound_D0toDF	; sound	$D0-$DF
		cmpi.b	#$E4,d7
		bls.s	Sound_E0toE4	; sound	$E0-$E4

locret_71F8C:
		rts	
; ===========================================================================

Sound_E0toE4:				; XREF: Sound_ChkValue
		subi.b	#$E0,d7
		lsl.w	#2,d7
		jmp	Sound_ExIndex(pc,d7.w)
; ===========================================================================

Sound_ExIndex:
		bra.w	Sound_E0
; ===========================================================================
		bra.w	Sound_E1
; ===========================================================================
		bra.w	Sound_E2
; ===========================================================================
		bra.w	Sound_E3
; ===========================================================================
		bra.w	Sound_E4
; ===========================================================================
; ---------------------------------------------------------------------------
; Play "Say-gaa" PCM sound
; ---------------------------------------------------------------------------

Sound_E1:
		rts

; ===========================================================================
; ---------------------------------------------------------------------------
; Play music track $81-$9F
; ---------------------------------------------------------------------------

Sound_81to9F:				; XREF: Sound_ChkValue
		cmpi.b	#$88,d7		; is "extra life" music	played?
		bne.s	loc_72024	; if not, branch
		tst.b	$27(a6)
		bne.w	loc_721B6
		lea	$40(a6),a5
		moveq	#9,d0

loc_71FE6:
		bclr	#2,(a5)
		adda.w	#$30,a5
		dbf	d0,loc_71FE6

		lea	$220(a6),a5
		moveq	#5,d0

loc_71FF8:
		bclr	#7,(a5)
		adda.w	#$30,a5
		dbf	d0,loc_71FF8
		clr.b	0(a6)
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72012:
		move.l	(a0)+,(a1)+
		dbf	d0,loc_72012

		move.b	#$80,$27(a6)
		clr.b	0(a6)
		bra.s	loc_7202C
; ===========================================================================

loc_72024:
		clr.b	$27(a6)
		clr.b	$26(a6)

loc_7202C:
		jsr	sub_725CA(pc)
		movea.l	(off_719A0).l,a4
		subi.b	#$81,d7
		move.b	(a4,d7.w),$29(a6)
		movea.l	(Go_MusicIndex).l,a4
		lsl.w	#2,d7
		movea.l	(a4,d7.w),a4
		moveq	#0,d0
		move.w	(a4),d0
		add.l	a4,d0
		move.l	d0,$18(a6)
		move.b	5(a4),d0
		move.b	d0,$28(a6)
		tst.b	$2A(a6)
		beq.s	loc_72068
		move.b	$29(a6),d0

loc_72068:
		move.b	d0,2(a6)
		move.b	d0,1(a6)
		moveq	#0,d1
		movea.l	a4,a3
		addq.w	#6,a4
		moveq	#0,d7
		move.b	2(a3),d7
		beq.w	loc_72114
		subq.b	#1,d7
		move.b	#-$40,d1
		move.b	4(a3),d4
		moveq	#$30,d6
		move.b	#1,d5
		lea	$40(a6),a1
		lea	byte_721BA(pc),a2

loc_72098:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d1,$A(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		adda.w	d6,a1
		dbf	d7,loc_72098
		cmpi.b	#7,2(a3)
		bne.s	loc_720D8
		moveq	#$2B,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		bra.w	loc_72114
; ===========================================================================

loc_720D8:
		moveq	#$28,d0
		moveq	#6,d1
		jsr	sub_7272E(pc)
		move.b	#$42,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4A,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$46,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4E,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#-$4A,d0
		move.b	#-$40,d1
		jsr	sub_72764(pc)

loc_72114:
		moveq	#0,d7
		move.b	3(a3),d7
		beq.s	loc_72154
		subq.b	#1,d7
		lea	$190(a6),a1
		lea	byte_721C2(pc),a2

loc_72126:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		move.b	(a4)+,d0
		move.b	(a4)+,$B(a1)
		adda.w	d6,a1
		dbf	d7,loc_72126

loc_72154:
		lea	$220(a6),a1
		moveq	#5,d7

loc_7215A:
		tst.b	(a1)
		bpl.w	loc_7217C
		moveq	#0,d0
		move.b	1(a1),d0
		bmi.s	loc_7216E
		subq.b	#2,d0
		lsl.b	#2,d0
		bra.s	loc_72170
; ===========================================================================

loc_7216E:
		lsr.b	#3,d0

loc_72170:
		lea	dword_722CC(pc),a0
		movea.l	(a0,d0.w),a0
		bset	#2,(a0)

loc_7217C:
		adda.w	d6,a1
		dbf	d7,loc_7215A

		tst.w	$340(a6)
		bpl.s	loc_7218E
		bset	#2,$100(a6)

loc_7218E:
		tst.w	$370(a6)
		bpl.s	loc_7219A
		bset	#2,$1F0(a6)

loc_7219A:
		lea	$70(a6),a5
		moveq	#5,d4

loc_721A0:
		jsr	sub_726FE(pc)
		adda.w	d6,a5
		dbf	d4,loc_721A0
		moveq	#2,d4

loc_721AC:
		jsr	sub_729A0(pc)
		adda.w	d6,a5
		dbf	d4,loc_721AC

loc_721B6:
		addq.w	#4,sp
		rts	
; ===========================================================================
byte_721BA:	dc.b 6,	0, 1, 2, 4, 5, 6, 0
		even
byte_721C2:	dc.b $80, $A0, $C0, 0
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Play normal sound effect
; ---------------------------------------------------------------------------

Sound_A0toCF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	loc_722C6
		tst.b	4(a6)
		bne.w	loc_722C6
		tst.b	$24(a6)
		bne.w	loc_722C6
		cmpi.b	#$B5,d7		; is ring sound	effect played?
		bne.s	Sound_notB5	; if not, branch
		tst.b	$2B(a6)
		bne.s	loc_721EE
		move.b	#$CE,d7		; play ring sound in left speaker

loc_721EE:
		bchg	#0,$2B(a6)	; change speaker

Sound_notB5:
		cmpi.b	#$A7,d7		; is "pushing" sound played?
		bne.s	Sound_notA7	; if not, branch
		tst.b	$2C(a6)
		bne.w	locret_722C4
		move.b	#$80,$2C(a6)

Sound_notA7:
		movea.l	(Go_SoundIndex).l,a0
		subi.b	#$A0,d7
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d1
		move.w	(a1)+,d1
		add.l	a3,d1
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72228:
		moveq	#0,d3
		move.b	1(a1),d3
		move.b	d3,d4
		bmi.s	loc_72244
		subq.w	#2,d3
		lsl.w	#2,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		bra.s	loc_7226E
; ===========================================================================

loc_72244:
		lsr.w	#3,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		cmpi.b	#$C0,d4
		bne.s	loc_7226E
		move.b	d4,d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l
		bchg	#5,d0
		move.b	d0,($C00011).l

loc_7226E:
		movea.l	dword_722EC(pc,d3.w),a5
		movea.l	a5,a2
		moveq	#$B,d0

loc_72276:
		clr.l	(a2)+
		dbf	d0,loc_72276

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.s	loc_722A8
		move.b	#$C0,$A(a5)
		move.l	d1,$20(a5)

loc_722A8:
		dbf	d7,loc_72228

		tst.b	$250(a6)
		bpl.s	loc_722B8
		bset	#2,$340(a6)

loc_722B8:
		tst.b	$310(a6)
		bpl.s	locret_722C4
		bset	#2,$370(a6)

locret_722C4:
		rts	
; ===========================================================================

loc_722C6:
		clr.b	0(a6)
		rts	
; ===========================================================================
dword_722CC:	dc.l $FFF0D0
		dc.l 0
		dc.l $FFF100
		dc.l $FFF130
		dc.l $FFF190
		dc.l $FFF1C0
		dc.l $FFF1F0
		dc.l $FFF1F0
dword_722EC:	dc.l $FFF220
		dc.l 0
		dc.l $FFF250
		dc.l $FFF280
		dc.l $FFF2B0
		dc.l $FFF2E0
		dc.l $FFF310
		dc.l $FFF310
; ===========================================================================
; ---------------------------------------------------------------------------
; Play GHZ waterfall sound
; ---------------------------------------------------------------------------

Sound_D0toDF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	locret_723C6
		tst.b	4(a6)
		bne.w	locret_723C6
		tst.b	$24(a6)
		bne.w	locret_723C6
		movea.l	(Go_SoundD0).l,a0
		subi.b	#$D0,d7
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,$20(a6)
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72348:
		move.b	1(a1),d4
		bmi.s	loc_7235A
		bset	#2,$100(a6)
		lea	$340(a6),a5
		bra.s	loc_72364
; ===========================================================================

loc_7235A:
		bset	#2,$1F0(a6)
		lea	$370(a6),a5

loc_72364:
		movea.l	a5,a2
		moveq	#$B,d0

loc_72368:
		clr.l	(a2)+
		dbf	d0,loc_72368

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.s	loc_72396
		move.b	#$C0,$A(a5)

loc_72396:
		dbf	d7,loc_72348

		tst.b	$250(a6)
		bpl.s	loc_723A6
		bset	#2,$340(a6)

loc_723A6:
		tst.b	$310(a6)
		bpl.s	locret_723C6
		bset	#2,$370(a6)
		ori.b	#$1F,d4
		move.b	d4,($C00011).l
		bchg	#5,d4
		move.b	d4,($C00011).l

locret_723C6:
		rts	
; End of function Sound_ChkValue

; ===========================================================================
		dc.l $FFF100
		dc.l $FFF1F0
		dc.l $FFF250
		dc.l $FFF310
		dc.l $FFF340
		dc.l $FFF370

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut1:				; XREF: Sound_E0
		clr.b	0(a6)
		lea	$220(a6),a5
		moveq	#5,d7

loc_723EA:
		tst.b	(a5)
		bpl.w	loc_72472
		bclr	#7,(a5)
		moveq	#0,d3
		move.b	1(a5),d3
		bmi.s	loc_7243C
		jsr	sub_726FE(pc)
		cmpi.b	#4,d3
		bne.s	loc_72416
		tst.b	$340(a6)
		bpl.s	loc_72416
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.s	loc_72428
; ===========================================================================

loc_72416:
		subq.b	#2,d3
		lsl.b	#2,d3
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		movea.l	(a0,d3.w),a5
		movea.l	$18(a6),a1

loc_72428:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5
		bra.s	loc_72472
; ===========================================================================

loc_7243C:
		jsr	sub_729A0(pc)
		lea	$370(a6),a0
		cmpi.b	#$E0,d3
		beq.s	loc_7245A
		cmpi.b	#$C0,d3
		beq.s	loc_7245A
		lsr.b	#3,d3
		lea	dword_722CC(pc),a0
		movea.l	(a0,d3.w),a0

loc_7245A:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.s	loc_72472
		move.b	$1F(a0),($C00011).l

loc_72472:
		adda.w	#$30,a5
		dbf	d7,loc_723EA

		rts	
; End of function Snd_FadeOut1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut2:				; XREF: Sound_E0
		lea	$340(a6),a5
		tst.b	(a5)
		bpl.s	loc_724AE
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.s	loc_724AE
		jsr	loc_7270A(pc)
		lea	$100(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.s	loc_724AE
		movea.l	$18(a6),a1
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_724AE:
		lea	$370(a6),a5
		tst.b	(a5)
		bpl.s	locret_724E4
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.s	locret_724E4
		jsr	loc_729A6(pc)
		lea	$1F0(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.s	locret_724E4
		cmpi.b	#-$20,1(a5)
		bne.s	locret_724E4
		move.b	$1F(a5),($C00011).l

locret_724E4:
		rts	
; End of function Snd_FadeOut2

; ===========================================================================
; ---------------------------------------------------------------------------
; Fade out music
; ---------------------------------------------------------------------------

Sound_E0:				; XREF: Sound_ExIndex
		jsr	Snd_FadeOut1(pc)
		jsr	Snd_FadeOut2(pc)
		move.b	#3,6(a6)
		move.b	#$28,4(a6)
		clr.b	$40(a6)
		clr.b	$2A(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72504:				; XREF: sub_71B4C
		move.b	6(a6),d0
		beq.s	loc_72510
		subq.b	#1,6(a6)
		rts	
; ===========================================================================

loc_72510:
		subq.b	#1,4(a6)
		beq.w	Sound_E4
		move.b	#3,6(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_72524:
		tst.b	(a5)
		bpl.s	loc_72538
		addq.b	#1,9(a5)
		bpl.s	loc_72534
		bclr	#7,(a5)
		bra.s	loc_72538
; ===========================================================================

loc_72534:
		jsr	sub_72CB4(pc)

loc_72538:
		adda.w	#$30,a5
		dbf	d7,loc_72524

		moveq	#2,d7

loc_72542:
		tst.b	(a5)
		bpl.s	loc_72560
		addq.b	#1,9(a5)
		cmpi.b	#$10,9(a5)
		bcs.s	loc_72558
		bclr	#7,(a5)
		bra.s	loc_72560
; ===========================================================================

loc_72558:
		move.b	9(a5),d6
		jsr	sub_7296A(pc)

loc_72560:
		adda.w	#$30,a5
		dbf	d7,loc_72542

		rts	
; End of function sub_72504


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7256A:				; XREF: Sound_E4; sub_725CA
		moveq	#2,d3
		moveq	#$28,d0

loc_7256E:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbf	d3,loc_7256E

		moveq	#$40,d0
		moveq	#$7F,d1
		moveq	#2,d4

loc_72584:
		moveq	#3,d3

loc_72586:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.w	#4,d0
		dbf	d3,loc_72586

		subi.b	#$F,d0
		dbf	d4,loc_72584

		rts	
; End of function sub_7256A

; ===========================================================================
; ---------------------------------------------------------------------------
; Stop music
; ---------------------------------------------------------------------------

Sound_E4:				; XREF: Sound_ChkValue; Sound_ExIndex; sub_72504
		moveq	#$2B,d0
		move.b	#$80,d1
		jsr	sub_7272E(pc)
		moveq	#$27,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		movea.l	a6,a0
		move.w	#$E3,d0

loc_725B6:
		clr.l	(a0)+
		dbf	d0,loc_725B6

		move.b	#$80,9(a6)	; set music to $80 (silence)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_725CA:				; XREF: Sound_ChkValue
		movea.l	a6,a0
		move.b	0(a6),d1
		move.b	$27(a6),d2
		move.b	$2A(a6),d3
		move.b	$26(a6),d4
		move.w	$A(a6),d5
		move.w	#$87,d0

loc_725E4:
		clr.l	(a0)+
		dbf	d0,loc_725E4

		move.b	d1,0(a6)
		move.b	d2,$27(a6)
		move.b	d3,$2A(a6)
		move.b	d4,$26(a6)
		move.w	d5,$A(a6)
		move.b	#$80,9(a6)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6
; End of function sub_725CA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7260C:				; XREF: sub_71B4C
		move.b	2(a6),1(a6)
		lea	$4E(a6),a0
		moveq	#$30,d0
		moveq	#9,d1

loc_7261A:
		addq.b	#1,(a0)
		adda.w	d0,a0
		dbf	d1,loc_7261A

		rts	
; End of function sub_7260C

; ===========================================================================
; ---------------------------------------------------------------------------
; Speed	up music
; ---------------------------------------------------------------------------

Sound_E2:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.s	loc_7263E
		move.b	$29(a6),2(a6)
		move.b	$29(a6),1(a6)
		move.b	#$80,$2A(a6)
		rts	
; ===========================================================================

loc_7263E:
		move.b	$3C9(a6),$3A2(a6)
		move.b	$3C9(a6),$3A1(a6)
		move.b	#$80,$3CA(a6)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Change music back to normal speed
; ---------------------------------------------------------------------------

Sound_E3:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.s	loc_7266A
		move.b	$28(a6),2(a6)
		move.b	$28(a6),1(a6)
		clr.b	$2A(a6)
		rts	
; ===========================================================================

loc_7266A:
		move.b	$3C8(a6),$3A2(a6)
		move.b	$3C8(a6),$3A1(a6)
		clr.b	$3CA(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7267C:				; XREF: sub_71B4C
		tst.b	$25(a6)
		beq.s	loc_72688
		subq.b	#1,$25(a6)
		rts	
; ===========================================================================

loc_72688:
		tst.b	$26(a6)
		beq.s	loc_726D6
		subq.b	#1,$26(a6)
		move.b	#2,$25(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_7269E:
		tst.b	(a5)
		bpl.s	loc_726AA
		subq.b	#1,9(a5)
		jsr	sub_72CB4(pc)

loc_726AA:
		adda.w	#$30,a5
		dbf	d7,loc_7269E
		moveq	#2,d7

loc_726B4:
		tst.b	(a5)
		bpl.s	loc_726CC
		subq.b	#1,9(a5)
		move.b	9(a5),d6
		cmpi.b	#$10,d6
		bcs.s	loc_726C8
		moveq	#$F,d6

loc_726C8:
		jsr	sub_7296A(pc)

loc_726CC:
		adda.w	#$30,a5
		dbf	d7,loc_726B4
		rts	
; ===========================================================================

loc_726D6:
		bclr	#2,$40(a6)
		clr.b	$24(a6)
		rts	
; End of function sub_7267C

; ===========================================================================

loc_726E2:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.s	locret_726FC
		btst	#2,(a5)
		bne.s	locret_726FC
		moveq	#$28,d0
		move.b	1(a5),d1
		ori.b	#-$10,d1
		bra.w	sub_7272E
; ===========================================================================

locret_726FC:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_726FE:				; XREF: sub_71CEC; sub_71D9E; Sound_ChkValue; Snd_FadeOut1
		btst	#4,(a5)
		bne.s	locret_72714
		btst	#2,(a5)
		bne.s	locret_72714

loc_7270A:				; XREF: Snd_FadeOut2
		moveq	#$28,d0
		move.b	1(a5),d1
		bra.w	sub_7272E
; ===========================================================================

locret_72714:
		rts	
; End of function sub_726FE

; ===========================================================================

loc_72716:				; XREF: sub_72A5A
		btst	#2,(a5)
		bne.s	locret_72720
		bra.w	sub_72722
; ===========================================================================

locret_72720:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72722:				; XREF: sub_71E18; sub_72C4E; sub_72CB4
		btst	#2,1(a5)
		bne.s	loc_7275A
		add.b	1(a5),d0
; End of function sub_72722


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7272E:				; XREF: loc_71E6A
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	sub_7272E
		move.b	d0,($A04000).l
		nop	
		nop	
		nop	

loc_72746:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	loc_72746

		move.b	d1,($A04001).l
		rts	
; End of function sub_7272E

; ===========================================================================

loc_7275A:				; XREF: sub_72722
		move.b	1(a5),d2
		bclr	#2,d2
		add.b	d2,d0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72764:				; XREF: loc_71E6A; Sound_ChkValue; sub_7256A; sub_72764
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	sub_72764
		move.b	d0,($A04002).l
		nop	
		nop	
		nop	

loc_7277C:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.s	loc_7277C

		move.b	d1,($A04003).l
		rts	
; End of function sub_72764

; ===========================================================================
word_72790:	dc.w $25E, $284, $2AB, $2D3, $2FE, $32D, $35C, $38F, $3C5
		dc.w $3FF, $43C, $47C, $A5E, $A84, $AAB, $AD3, $AFE, $B2D
		dc.w $B5C, $B8F, $BC5, $BFF, $C3C, $C7C, $125E,	$1284
		dc.w $12AB, $12D3, $12FE, $132D, $135C,	$138F, $13C5, $13FF
		dc.w $143C, $147C, $1A5E, $1A84, $1AAB,	$1AD3, $1AFE, $1B2D
		dc.w $1B5C, $1B8F, $1BC5, $1BFF, $1C3C,	$1C7C, $225E, $2284
		dc.w $22AB, $22D3, $22FE, $232D, $235C,	$238F, $23C5, $23FF
		dc.w $243C, $247C, $2A5E, $2A84, $2AAB,	$2AD3, $2AFE, $2B2D
		dc.w $2B5C, $2B8F, $2BC5, $2BFF, $2C3C,	$2C7C, $325E, $3284
		dc.w $32AB, $32D3, $32FE, $332D, $335C,	$338F, $33C5, $33FF
		dc.w $343C, $347C, $3A5E, $3A84, $3AAB,	$3AD3, $3AFE, $3B2D
		dc.w $3B5C, $3B8F, $3BC5, $3BFF, $3C3C,	$3C7C

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72850:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.s	loc_72866
		bclr	#4,(a5)
		jsr	sub_72878(pc)
		jsr	sub_728DC(pc)
		bra.w	loc_7292E
; ===========================================================================

loc_72866:
		jsr	sub_71D9E(pc)
		jsr	sub_72926(pc)
		jsr	sub_71DC6(pc)
		jsr	sub_728E2(pc)
		rts	
; End of function sub_72850


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72878:				; XREF: sub_72850
		bclr	#1,(a5)
		movea.l	4(a5),a4

loc_72880:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#$E0,d5
		bcs.s	loc_72890
		jsr	sub_72A5A(pc)
		bra.s	loc_72880
; ===========================================================================

loc_72890:
		tst.b	d5
		bpl.s	loc_728A4
		jsr	sub_728AC(pc)
		move.b	(a4)+,d5
		tst.b	d5
		bpl.s	loc_728A4
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_728A4:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_72878


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728AC:				; XREF: sub_72878
		subi.b	#$81,d5
		bcs.s	loc_728CA
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_729CE(pc),a0
		move.w	(a0,d5.w),$10(a5)
		bra.w	sub_71D60
; ===========================================================================

loc_728CA:
		bset	#1,(a5)
		move.w	#-1,$10(a5)
		jsr	sub_71D60(pc)
		bra.w	sub_729A0
; End of function sub_728AC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728DC:				; XREF: sub_72850
		move.w	$10(a5),d6
		bmi.s	loc_72920
; End of function sub_728DC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728E2:				; XREF: sub_72850
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.s	locret_7291E
		btst	#1,(a5)
		bne.s	locret_7291E
		move.b	1(a5),d0
		cmpi.b	#$E0,d0
		bne.s	loc_72904
		move.b	#$C0,d0

loc_72904:
		move.w	d6,d1
		andi.b	#$F,d1
		or.b	d1,d0
		lsr.w	#4,d6
		andi.b	#$3F,d6
		move.b	d0,($C00011).l
		move.b	d6,($C00011).l

locret_7291E:
		rts	
; End of function sub_728E2

; ===========================================================================

loc_72920:				; XREF: sub_728DC
		bset	#1,(a5)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72926:				; XREF: sub_72850
		tst.b	$B(a5)
		beq.w	locret_7298A

loc_7292E:				; XREF: sub_72850
		move.b	9(a5),d6
		moveq	#0,d0
		move.b	$B(a5),d0
		beq.s	sub_7296A
		movea.l	(Go_PSGIndex).l,a0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a0,d0.w),a0
		move.b	$C(a5),d0
		move.b	(a0,d0.w),d0
		addq.b	#1,$C(a5)
		btst	#7,d0
		beq.s	loc_72960
		cmpi.b	#$80,d0
		beq.s	loc_7299A

loc_72960:
		add.w	d0,d6
		cmpi.b	#$10,d6
		bcs.s	sub_7296A
		moveq	#$F,d6
; End of function sub_72926


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7296A:				; XREF: sub_72504; sub_7267C; sub_72926
		btst	#1,(a5)
		bne.s	locret_7298A
		btst	#2,(a5)
		bne.s	locret_7298A
		btst	#4,(a5)
		bne.s	loc_7298C

loc_7297C:
		or.b	1(a5),d6
		addi.b	#$10,d6
		move.b	d6,($C00011).l

locret_7298A:
		rts	
; ===========================================================================

loc_7298C:
		tst.b	$13(a5)
		beq.s	loc_7297C
		tst.b	$12(a5)
		bne.s	loc_7297C
		rts	
; End of function sub_7296A

; ===========================================================================

loc_7299A:				; XREF: sub_72926
		subq.b	#1,$C(a5)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729A0:				; XREF: sub_71D9E; Sound_ChkValue; Snd_FadeOut1; sub_728AC
		btst	#2,(a5)
		bne.s	locret_729B4

loc_729A6:				; XREF: Snd_FadeOut2
		move.b	1(a5),d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l

locret_729B4:
		rts	
; End of function sub_729A0


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729B6:				; XREF: loc_71E7C
		lea	($C00011).l,a0
		move.b	#$9F,(a0)
		move.b	#$BF,(a0)
		move.b	#$DF,(a0)
		move.b	#$FF,(a0)
		rts	
; End of function sub_729B6

; ===========================================================================
word_729CE:	dc.w $356, $326, $2F9, $2CE, $2A5, $280, $25C, $23A, $21A
		dc.w $1FB, $1DF, $1C4, $1AB, $193, $17D, $167, $153, $140
		dc.w $12E, $11D, $10D, $FE, $EF, $E2, $D6, $C9,	$BE, $B4
		dc.w $A9, $A0, $97, $8F, $87, $7F, $78,	$71, $6B, $65
		dc.w $5F, $5A, $55, $50, $4B, $47, $43,	$40, $3C, $39
		dc.w $36, $33, $30, $2D, $2B, $28, $26,	$24, $22, $20
		dc.w $1F, $1D, $1B, $1A, $18, $17, $16,	$15, $13, $12
		dc.w $11, 0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72A5A:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		subi.w	#$E0,d5
		lsl.w	#2,d5
		jmp	loc_72A64(pc,d5.w)
; End of function sub_72A5A

; ===========================================================================

loc_72A64:
		bra.w	loc_72ACC
; ===========================================================================
		bra.w	loc_72AEC
; ===========================================================================
		bra.w	loc_72AF2
; ===========================================================================
		bra.w	loc_72AF8
; ===========================================================================
		bra.w	loc_72B14
; ===========================================================================
		bra.w	loc_72B9E
; ===========================================================================
		bra.w	loc_72BA4
; ===========================================================================
		bra.w	loc_72BAE
; ===========================================================================
		bra.w	loc_72BB4
; ===========================================================================
		bra.w	loc_72BBE
; ===========================================================================
		bra.w	loc_72BC6
; ===========================================================================
		bra.w	loc_72BD0
; ===========================================================================
		bra.w	loc_72BE6
; ===========================================================================
		bra.w	loc_72BEE
; ===========================================================================
		bra.w	loc_72BF4
; ===========================================================================
		bra.w	loc_72C26
; ===========================================================================
		bra.w	loc_72D30
; ===========================================================================
		bra.w	loc_72D52
; ===========================================================================
		bra.w	loc_72D58
; ===========================================================================
		bra.w	loc_72E06
; ===========================================================================
		bra.w	loc_72E20
; ===========================================================================
		bra.w	loc_72E26
; ===========================================================================
		bra.w	loc_72E2C
; ===========================================================================
		bra.w	loc_72E38
; ===========================================================================
		bra.w	loc_72E52
; ===========================================================================
		bra.w	loc_72E64
; ===========================================================================

loc_72ACC:				; XREF: loc_72A64
		move.b	(a4)+,d1
		tst.b	1(a5)
		bmi.s	locret_72AEA
		move.b	$A(a5),d0
		andi.b	#$37,d0
		or.b	d0,d1
		move.b	d1,$A(a5)
		move.b	#$B4,d0
		bra.w	loc_72716
; ===========================================================================

locret_72AEA:
		rts	
; ===========================================================================

loc_72AEC:				; XREF: loc_72A64
		move.b	(a4)+,$1E(a5)
		rts	
; ===========================================================================

loc_72AF2:				; XREF: loc_72A64
		move.b	(a4)+,7(a6)
		rts	
; ===========================================================================

loc_72AF8:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		movea.l	(a5,d0.w),a4
		move.l	#0,(a5,d0.w)
		addq.w	#2,a4
		addq.b	#4,d0
		move.b	d0,$D(a5)
		rts	
; ===========================================================================

loc_72B14:				; XREF: loc_72A64
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72B1E:
		move.l	(a1)+,(a0)+
		dbf	d0,loc_72B1E

		bset	#2,$40(a6)
		movea.l	a5,a3
		move.b	#$28,d6
		sub.b	$26(a6),d6
		moveq	#5,d7
		lea	$70(a6),a5

loc_72B3A:
		btst	#7,(a5)
		beq.s	loc_72B5C
		bset	#1,(a5)
		add.b	d6,9(a5)
		btst	#2,(a5)
		bne.s	loc_72B5C
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		jsr	sub_72C4E(pc)

loc_72B5C:
		adda.w	#$30,a5
		dbf	d7,loc_72B3A

		moveq	#2,d7

loc_72B66:
		btst	#7,(a5)
		beq.s	loc_72B78
		bset	#1,(a5)
		jsr	sub_729A0(pc)
		add.b	d6,9(a5)

loc_72B78:
		adda.w	#$30,a5
		dbf	d7,loc_72B66
		movea.l	a3,a5
		move.b	#$80,$24(a6)
		move.b	#$28,$26(a6)
		clr.b	$27(a6)
		move.w	#0,($A11100).l
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72B9E:				; XREF: loc_72A64
		move.b	(a4)+,2(a5)
		rts	
; ===========================================================================

loc_72BA4:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		bra.w	sub_72CB4
; ===========================================================================

loc_72BAE:				; XREF: loc_72A64
		bset	#4,(a5)
		rts	
; ===========================================================================

loc_72BB4:				; XREF: loc_72A64
		move.b	(a4),$12(a5)
		move.b	(a4)+,$13(a5)
		rts	
; ===========================================================================

loc_72BBE:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,8(a5)
		rts	
; ===========================================================================

loc_72BC6:				; XREF: loc_72A64
		move.b	(a4),2(a6)
		move.b	(a4)+,1(a6)
		rts	
; ===========================================================================

loc_72BD0:				; XREF: loc_72A64
		lea	$40(a6),a0
		move.b	(a4)+,d0
		moveq	#$30,d1
		moveq	#9,d2

loc_72BDA:
		move.b	d0,2(a0)
		adda.w	d1,a0
		dbf	d2,loc_72BDA

		rts	
; ===========================================================================

loc_72BE6:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		rts	
; ===========================================================================

loc_72BEE:				; XREF: loc_72A64
		clr.b	$2C(a6)
		rts	
; ===========================================================================

loc_72BF4:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		jsr	sub_726FE(pc)
		tst.b	$250(a6)
		bmi.s	loc_72C22
		movea.l	a5,a3
		lea	$100(a6),a5
		movea.l	$18(a6),a1
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5

loc_72C22:
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72C26:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	d0,$B(a5)
		btst	#2,(a5)
		bne.w	locret_72CAA
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.s	sub_72C4E
		movea.l	$20(a5),a1
		tst.b	$E(a6)
		bmi.s	sub_72C4E
		movea.l	$20(a6),a1

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72C4E:				; XREF: Snd_FadeOut1; et al
		subq.w	#1,d0
		bmi.s	loc_72C5C
		move.w	#$19,d1

loc_72C56:
		adda.w	d1,a1
		dbf	d0,loc_72C56

loc_72C5C:
		move.b	(a1)+,d1
		move.b	d1,$1F(a5)
		move.b	d1,d4
		move.b	#$B0,d0
		jsr	sub_72722(pc)
		lea	byte_72D18(pc),a2
		moveq	#$13,d3

loc_72C72:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		jsr	sub_72722(pc)
		dbf	d3,loc_72C72
		moveq	#3,d5
		andi.w	#7,d4
		move.b	byte_72CAC(pc,d4.w),d4
		move.b	9(a5),d3

loc_72C8C:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.s	loc_72C96
		add.b	d3,d1

loc_72C96:
		jsr	sub_72722(pc)
		dbf	d5,loc_72C8C
		move.b	#$B4,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

locret_72CAA:
		rts	
; End of function sub_72C4E

; ===========================================================================
byte_72CAC:	dc.b 8,	8, 8, 8, $A, $E, $E, $F

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72CB4:				; XREF: sub_72504; sub_7267C; loc_72BA4
		btst	#2,(a5)
		bne.s	locret_72D16
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.s	loc_72CD8
		movea.l	$20(a6),a1
		tst.b	$E(a6)
		bmi.s	loc_72CD8
		movea.l	$20(a6),a1

loc_72CD8:
		subq.w	#1,d0
		bmi.s	loc_72CE6
		move.w	#$19,d1

loc_72CE0:
		adda.w	d1,a1
		dbf	d0,loc_72CE0

loc_72CE6:
		adda.w	#$15,a1
		lea	byte_72D2C(pc),a2
		move.b	$1F(a5),d0
		andi.w	#7,d0
		move.b	byte_72CAC(pc,d0.w),d4
		move.b	9(a5),d3
		bmi.s	locret_72D16
		moveq	#3,d5

loc_72D02:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.s	loc_72D12
		add.b	d3,d1
		bcs.s	loc_72D12
		jsr	sub_72722(pc)

loc_72D12:
		dbf	d5,loc_72D02

locret_72D16:
		rts	
; End of function sub_72CB4

; ===========================================================================
byte_72D18:	dc.b $30, $38, $34, $3C, $50, $58, $54,	$5C, $60, $68
		dc.b $64, $6C, $70, $78, $74, $7C, $80,	$88, $84, $8C
byte_72D2C:	dc.b $40, $48, $44, $4C
; ===========================================================================

loc_72D30:				; XREF: loc_72A64
		bset	#3,(a5)
		move.l	a4,$14(a5)
		move.b	(a4)+,$18(a5)
		move.b	(a4)+,$19(a5)
		move.b	(a4)+,$1A(a5)
		move.b	(a4)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)
		rts	
; ===========================================================================

loc_72D52:				; XREF: loc_72A64
		bset	#3,(a5)
		rts	
; ===========================================================================

loc_72D58:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		tst.b	1(a5)
		bmi.s	loc_72D74
		tst.b	8(a6)
		bmi.w	loc_72E02
		jsr	sub_726FE(pc)
		bra.s	loc_72D78
; ===========================================================================

loc_72D74:
		jsr	sub_729A0(pc)

loc_72D78:
		tst.b	$E(a6)
		bpl.w	loc_72E02
		clr.b	0(a6)
		moveq	#0,d0
		move.b	1(a5),d0
		bmi.s	loc_72DCC
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		cmpi.b	#4,d0
		bne.s	loc_72DA8
		tst.b	$340(a6)
		bpl.s	loc_72DA8
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.s	loc_72DB8
; ===========================================================================

loc_72DA8:
		subq.b	#2,d0
		lsl.b	#2,d0
		movea.l	(a0,d0.w),a5
		tst.b	(a5)
		bpl.s	loc_72DC8
		movea.l	$18(a6),a1

loc_72DB8:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_72DC8:
		movea.l	a3,a5
		bra.s	loc_72E02
; ===========================================================================

loc_72DCC:
		lea	$370(a6),a0
		tst.b	(a0)
		bpl.s	loc_72DE0
		cmpi.b	#$E0,d0
		beq.s	loc_72DEA
		cmpi.b	#$C0,d0
		beq.s	loc_72DEA

loc_72DE0:
		lea	dword_722CC(pc),a0
		lsr.b	#3,d0
		movea.l	(a0,d0.w),a0

loc_72DEA:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.s	loc_72E02
		move.b	$1F(a0),($C00011).l

loc_72E02:
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72E06:				; XREF: loc_72A64
		move.b	#$E0,1(a5)
		move.b	(a4)+,$1F(a5)
		btst	#2,(a5)
		bne.s	locret_72E1E
		move.b	-1(a4),($C00011).l

locret_72E1E:
		rts	
; ===========================================================================

loc_72E20:				; XREF: loc_72A64
		bclr	#3,(a5)
		rts	
; ===========================================================================

loc_72E26:				; XREF: loc_72A64
		move.b	(a4)+,$B(a5)
		rts	
; ===========================================================================

loc_72E2C:				; XREF: loc_72A64
		move.b	(a4)+,d0
		lsl.w	#8,d0
		move.b	(a4)+,d0
		adda.w	d0,a4
		subq.w	#1,a4
		rts	
; ===========================================================================

loc_72E38:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	(a4)+,d1
		tst.b	$24(a5,d0.w)
		bne.s	loc_72E48
		move.b	d1,$24(a5,d0.w)

loc_72E48:
		subq.b	#1,$24(a5,d0.w)
		bne.s	loc_72E2C
		addq.w	#2,a4
		rts	
; ===========================================================================

loc_72E52:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		subq.b	#4,d0
		move.l	a4,(a5,d0.w)
		move.b	d0,$D(a5)
		bra.s	loc_72E2C
; ===========================================================================

loc_72E64:				; XREF: loc_72A64
		move.b	#$88,d0
		move.b	#$F,d1
		jsr	sub_7272E(pc)
		move.b	#$8C,d0
		move.b	#$F,d1
		bra.w	sub_7272E
; ===========================================================================
Kos_Z80:	incbin	"sound/DAC Driver.kos"
		even
Music81:	incbin	sound\music81.bin
		even
Music82:	incbin	sound\music82.bin
		even
Music83:	incbin	sound\music83.bin
		even
Music84:	incbin	sound\music84.bin
		even
Music85:	incbin	sound\music85.bin
		even
Music86:	incbin	sound\music86.bin
		even
Music87:	incbin	sound\music87.bin
		even
Music88:	incbin	sound\music88.bin
		even
Music89:	incbin	sound\music89.bin
		even
Music8A:	incbin	sound\music8A.bin
		even
Music8B:	incbin	sound\music8B.bin
		even
Music8C:	incbin	sound\music8C.bin
		even
Music8D:	incbin	sound\music8D.bin
		even
Music8E:	incbin	sound\music8E.bin
		even
Music8F:	incbin	sound\music8F.bin
		even
Music90:	incbin	sound\music90.bin
		even
Music91:	incbin	sound\music91.bin
		even
Music92:	incbin	sound\music92.bin
		even
Music93:	incbin	sound\music93.bin
		even
; ---------------------------------------------------------------------------
; Sound	effect pointers
; ---------------------------------------------------------------------------
SoundIndex:	dc.l SoundA0, SoundA1, SoundA2
		dc.l SoundA3, SoundA4, SoundA5
		dc.l SoundA6, SoundA7, SoundA8
		dc.l SoundA9, SoundAA, SoundAB
		dc.l SoundAC, SoundAD, SoundAE
		dc.l SoundAF, SoundB0, SoundB1
		dc.l SoundB2, SoundB3, SoundB4
		dc.l SoundB5, SoundB6, SoundB7
		dc.l SoundB8, SoundB9, SoundBA
		dc.l SoundBB, SoundBC, SoundBD
		dc.l SoundBE, SoundBF, SoundC0
		dc.l SoundC1, SoundC2, SoundC3
		dc.l SoundC4, SoundC5, SoundC6
		dc.l SoundC7, SoundC8, SoundC9
		dc.l SoundCA, SoundCB, SoundCC
		dc.l SoundCD, SoundCE, SoundCF
SoundD0Index:	dc.l SoundD0
SoundA0:	incbin	sound\soundA0.bin
		even
SoundA1:	incbin	sound\soundA1.bin
		even
SoundA2:	incbin	sound\soundA2.bin
		even
SoundA3:	incbin	sound\soundA3.bin
		even
SoundA4:	incbin	sound\soundA4.bin
		even
SoundA5:	incbin	sound\soundA5.bin
		even
SoundA6:	incbin	sound\soundA6.bin
		even
SoundA7:	incbin	sound\soundA7.bin
		even
SoundA8:	incbin	sound\soundA8.bin
		even
SoundA9:	incbin	sound\soundA9.bin
		even
SoundAA:	incbin	sound\soundAA.bin
		even
SoundAB:	incbin	sound\soundAB.bin
		even
SoundAC:	incbin	sound\soundAC.bin
		even
SoundAD:	incbin	sound\soundAD.bin
		even
SoundAE:	incbin	sound\soundAE.bin
		even
SoundAF:	incbin	sound\soundAF.bin
		even
SoundB0:	incbin	sound\soundB0.bin
		even
SoundB1:	incbin	sound\soundB1.bin
		even
SoundB2:	incbin	sound\soundB2.bin
		even
SoundB3:	incbin	sound\soundB3.bin
		even
SoundB4:	incbin	sound\soundB4.bin
		even
SoundB5:	incbin	sound\soundB5.bin
		even
SoundB6:	incbin	sound\soundB6.bin
		even
SoundB7:	incbin	sound\soundB7.bin
		even
SoundB8:	incbin	sound\soundB8.bin
		even
SoundB9:	incbin	sound\soundB9.bin
		even
SoundBA:	incbin	sound\soundBA.bin
		even
SoundBB:	incbin	sound\soundBB.bin
		even
SoundBC:	incbin	sound\soundBC.bin
		even
SoundBD:	incbin	sound\soundBD.bin
		even
SoundBE:	incbin	sound\soundBE.bin
		even
SoundBF:	incbin	sound\soundBF.bin
		even
SoundC0:	incbin	sound\soundC0.bin
		even
SoundC1:	incbin	sound\soundC1.bin
		even
SoundC2:	incbin	sound\soundC2.bin
		even
SoundC3:	incbin	sound\soundC3.bin
		even
SoundC4:	incbin	sound\soundC4.bin
		even
SoundC5:	incbin	sound\soundC5.bin
		even
SoundC6:	incbin	sound\soundC6.bin
		even
SoundC7:	incbin	sound\soundC7.bin
		even
SoundC8:	incbin	sound\soundC8.bin
		even
SoundC9:	incbin	sound\soundC9.bin
		even
SoundCA:	incbin	sound\soundCA.bin
		even
SoundCB:	incbin	sound\soundCB.bin
		even
SoundCC:	incbin	sound\soundCC.bin
		even
SoundCD:	incbin	sound\soundCD.bin
		even
SoundCE:	incbin	sound\soundCE.bin
		even
SoundCF:	incbin	sound\soundCF.bin
		even
SoundD0:	incbin	sound\soundD0.bin
		even

ROM_End:
		END
