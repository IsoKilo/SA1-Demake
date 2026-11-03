; ==================================================
; Title Screen/Script.asm
; Contains title screen scene code.
; Contains title screen sprite code.
;
; Author: Kilo
; 31-10-2024
; ==================================================

; ----------<Scene Code>----------
Scene_Title:
		move.b	#SFXID_STOP,d0
		bsr.w	Sound_CueSFX
		bsr.w	PalFade_ToBlack
		move	#$2700,sr

; Initialize VDP registers.
		lea		(vdp_ctrl).l,a6
		move.w	#VREG_MODE1|%00000100,(a6)
		move.w	#VREG_PLANEA|($C000/$2000)<<3,(a6)
		move.w	#VREG_PLANEB|($E000/$2000),(a6)
		move.w	#VREG_MAPSZ|%00000001,(a6)
		move.w	#VREG_MODE3|%00000011,(a6)
		move.w	#VREG_MODE4|%00000000,(a6)
		move.w	#VREG_BGCOL|(3<<4)|0,(a6)
		bsr.w	VDP_Clear

; Clear actors.
		lea		(act_buffer).w,a0
		move.w	#((128*$40)/4)-1,d0

@ClrActors:
		move.l	#0,(a0)+
		dbf		d0,@ClrActors

; Load graphics.
		VDP_Cmd	VCMD_VRAMWRT,$0000
		lea		(Title_Tiles).l,a0
		bsr.w	Decomp_Nem
		move	#$2700,sr

; Load BG A map.
		lea		(dec_enibuff).l,a1
		lea		(Title_BGAMaps).l,a0
		move.w	#0,d0
		bsr.w	Decomp_Eni
		lea		(dec_enibuff).l,a1
		VDP_Cmd	VCMD_VRAMWRT,$C000,d0
		moveq	#32-1,d1
		moveq	#28-1,d2
		bsr.w	VDP_DrawTilemap

; Load BG B map.
		lea		(dec_enibuff).l,a1
		lea		(Title_BGBMaps).l,a0
		move.w	#0,d0
		bsr.w	Decomp_Eni
		lea		(dec_enibuff).l,a1
		VDP_Cmd	VCMD_VRAMWRT,$E000,d0
		moveq	#32-1,d1
		moveq	#28-1,d2
		bsr.w	VDP_DrawTilemap

		moveq	#1,d0
		bsr.w	Pal_LoadTarget

; Enable the display
		move.w	($FFFFF60C).w,d0
		ori.b	#%01000000,d0
		move.w	d0,(vdp_ctrl).l

Title_Return:
		clr.w	(ttl_deformspd).w
		move.b	#0,(act_buffer+$C0).w
		move.b	#$8A,d0
		bsr.w	Sound_CueMusic

; Load actors
		move.b	#$E,(act_buffer+0).w			; Logo
		move.b	#3,(act_buffer+0+act_frame).w
		move.w	#134+128,(act_buffer+0+act_xscr).w
		move.w	#96+128,(act_buffer+0+act_yscr).w
		move.b	#0,(act_buffer+0+act_routine).w			; We clear routines for when Title_Return runs.
		move.b	#$E,(act_buffer+$40).w			; PSB
		move.b	#1,(act_buffer+$40+act_frame).w
		move.w	#128+128,(act_buffer+$40+act_xscr).w
		move.w	#170+128,(act_buffer+$40+act_yscr).w
		move.b	#0,(act_buffer+$40+act_routine).w
		move.b	#$E,(act_buffer+$80).w			; Copyright
		move.b	#2,(act_buffer+$80+act_frame).w
		move.w	#128+128,(act_buffer+$80+act_xscr).w
		move.w	#180+128,(act_buffer+$80+act_yscr).w
		move.b	#0,(act_buffer+$80+act_routine).w
		jsr		Actor_Execute
		jsr		Sprites_Render
		bsr.w	PalFade_ToTarget

Title_Loop:
		move.b	#4,($FFFFF62A).w
		bsr.w	VSync
		cmp.b	#4,(act_buffer+0+act_routine).w
		bne.s	@SkipDeform
		bsr.s	Title_Deform

@SkipDeform:
		jsr		Actor_Execute
		jsr		Sprites_Render
		btst	#IO_STARTPOS,($FFFFF605).w
		bne.s	Title_Menu
; Scene loop.
		cmp.b	#SCNID_TITLE,(gm_scene).w
		beq.s	Title_Loop
		rts

Title_Deform:
		lea		(scr_horibuff).w,a1
		moveq	#0,d3
		move.w	#224-1,d2
		move.w	(ttl_deformspd).w,d3

@Loop:
		moveq	#0,d0
		move.w	d3,d0
		bsr.w	Math_GetSine
		asr.w	#6,d0
		neg.w	d3 
		bmi.s	@OddFrame
		addq.w	#5,d3

@OddFrame:
		move.w	d0,(a1)+
		move.w	d0,(a1)+
		dbf		d2,@Loop
		addq.w	#2,(ttl_deformspd).w
		rts

Title_Menu:
		move.b	#SCNID_GAME,(gm_scene).w
		rts
		move.b	#$8A,d0
		bsr.w	Sound_CueMusic
		move	#$2700,sr
		moveq	#2,d0
		bsr.w	Pal_LoadDirect

; Clear horizontal scroll.
		lea		(scr_horibuff).w,a0
		move.w	#(448/2)-1,d0

@Loop:
		clr.l	(a0)+
		dbf		d0,@Loop

; Clear PSB and copyright.
		clr.b	(act_buffer+$40).w
		clr.b	(act_buffer+$80).w
		move.b	#12,(act_buffer+0+act_frame).w

; Load the menu
		move.b	#$F,(act_buffer+$C0).w

TitleMenu_Loop:
		move.b	#4,($FFFFF62A).w
		bsr.w	VSync
		jsr		Actor_Execute
		jsr		Sprites_Render

; Scene loop.
		cmp.b	#SCNID_TITLE,(gm_scene).w
		beq.s	TitleMenu_Loop
		rts

; ----------<Actor Code>----------
Act_Title:
		moveq	#0,d0
		move.b	act_routine(a0),d0
		move.w	Title_Index(pc,d0.w),d0
		jsr		Title_Index(pc,d0.w)
		jmp		Actor_Display

Title_Index:
		dc.w	Title_Init-Title_Index
		dc.w	Title_Animate-Title_Index
		dc.w	Title_DoNothing-Title_Index
		dc.w	Title_Flash-Title_Index

Title_Init:
		addq.b	#2,act_routine(a0)
		move.l	#Title_SprtMaps,act_maps(a0)
		move.b	#1,act_pri(a0)
		cmp.b	#1,act_frame(a0)				; Is this the PSB frame?
		bne.s	@ChkLogo						; If not, check if it's the logo.
		addq.b	#4,act_routine(a0)				; Increment to do the flash routine.
		move.b	#30,act_anitime(a0)				; Set the flash timer.
		bra.s	Title_Flash

@ChkLogo:
		cmp.b	#3,act_frame(a0)				; Is this the logo frame?
		bne.s	@NotLogo						; If not, we need to increment the routine to do nothing.
		rts

@NotLogo:
		addq.b	#2,act_routine(a0)
		rts

Title_Animate:
		lea		(Title_Anims).l,a1
		jmp		Actor_Animate

Title_DoNothing:
		rts

Title_Flash:
		subq.b	#1,act_anitime(a0)
		bne.s	@Return
		bchg	#0,act_frame(a0)
		move.b	#30,act_anitime(a0)

@Return:
		rts

Act_TitleMenu:
		moveq	#0,d0
		move.b	act_routine(a0),d0
		move.w	TitleMenu_Index(pc,d0.w),d0
		jsr		TitleMenu_Index(pc,d0.w)
		jmp		Actor_Display

TitleMenu_Index:
		dc.w	TitleMenu_Init-TitleMenu_Index
		dc.w	TitleMenu_Main-TitleMenu_Index

TitleMenu_Init:
		addq.b	#2,act_routine(a0)
		move.w	#VFLAG_PAL1|VFLAG_PRI,act_tile(a0)
		move.l	#Title_SprtMaps,act_maps(a0)
		move.w	#(256/2)+128,act_xscr(a0)
		move.w	#(224/2)+128,act_yscr(a0)
		move.b	#30,act_free+0(a0)					; Initial input delay timer.
		move.b	#0,act_free+1(a0)					; Initial selection.

TitleMenu_Main:
		addq.b	#1,act_anitime(a0)
		bsr.s	TitleMenu_Input
		move.b	act_free+1(a0),d0
		addq.b	#8,d0
		btst	#5,act_anitime(a0)
		beq.s	@DontBlink
		moveq	#7,d0

@DontBlink:
		move.b	d0,act_frame(a0)
		rts

TitleMenu_Input:
		tst.b	act_free+0(a0)
		bne.w	@End
	
	; Overflow prevention
		cmp.b	#3,act_free+1(a0)
		beq.s	@ChkUp
		btst	#IO_DOWNPOS,($FFFFF605).w
		beq.s	@ChkUp
		addq.b	#1,act_free+1(a0)
		move.b	#11,act_free+0(a0)
		bra.s	@End
		
@ChkUp:
	; Underflow prevention
		tst.b	act_free+1(a0)
		beq.s	@End
		btst	#IO_UPPOS,($FFFFF605).w
		beq.s	@End
		subq.b	#1,act_free+1(a0)
		move.b	#11,act_free+0(a0)

@End:
		subq.b	#1,act_free+0(a0)
		rts

Title_SprtMaps:
		include	"Title Screen/Sprite Maps.asm"

Title_Anims:
		dc.w	TitleAni_Logo-Title_Anims
TitleAni_Logo:
		dc.b	1, 3, 3, 3, 3, 3, 3, 4, 5, 6, $FC	; Increment the routine so we do nothing when we're done.
		even

; ==================================================
; End of file
; ==================================================