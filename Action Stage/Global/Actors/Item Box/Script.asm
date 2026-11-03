Act_ItemBox:
		moveq	#0,d0
		move.b	act_routine(a0),d0
		move.w	ItemBox_Index(pc,d0.w),d0
		jmp		ItemBox_Index(pc,d0.w)

ItemBox_Index:
		dc.w	ItemBox_Init-ItemBox_Index
		dc.w	ItemBox_Main-ItemBox_Index
		dc.w	ItemBox_Break-ItemBox_Index

ItemBox_Init:
		addq.b	#2,act_routine(a0)
		move.b	#%00000100,act_flags(a0)
		move.w	#$680,act_tile(a0)
		move.l	#ItemBox_Maps,act_maps(a0)
		move.b	#3,act_pri(a0)
		move.b	act_type(a0),act_frame(a0)
		; Check if this box has already been destroyed.
		lea		($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	act_saveidx(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		beq.s	ItemBox_Main
		jmp		DeleteObject

ItemBox_Main:
		; X collision check.
		move.w	(ACTSLOT_PLAYER+act_xpos).w,d0
		sub.w	act_xpos(a0),d0
		addi.w	#12,d0
		cmp.w	#24,d0
		bcc.s	@DisplayChk
		; Y collision check.
		move.w	(ACTSLOT_PLAYER+act_ypos).w,d0
		sub.w	act_ypos(a0),d0
		addi.w	#12,d0
		cmp.w	#24,d0
		bcc.s	@DisplayChk
		addq.b	#2,act_routine(a0)


@DisplayChk:
		; On screen check.
		move.w	act_xpos(a0),d0
		andi.w	#-128,d0
		move.w	(lvl_fgxpos).w,d1
		subi.w	#128,d1
		andi.w	#-128,d1
		sub.w	d1,d0
		cmpi.w	#640,d0
		bhi.w	DeleteObject
		bra.w	Actor_Display

ItemBox_Break:
		jsr		SingleObjLoad
		bne.s	@Cont
		move.b	#$2E,act_id(a1)
		move.b	act_type(a0),act_type(a1)
@Cont:
		; Save status as broken.
		lea		($FFFFFC00).w,a2
		moveq	#0,d0
		move.b	act_saveidx(a0),d0
		bset	#0,2(a2,d0.w)
		move.w	#$C1,d0
		jsr		(Sound_CueSFX).l
		jmp		DeleteObject

Act_PowerUp:
		moveq	#0,d0
		move.b	act_routine(a0),d0
		move.w	PowerUp_Index(pc,d0.w),d0
		jsr		PowerUp_Index(pc,d0.w)
		jmp		Actor_Display

PowerUp_Index:
		dc.w	PowerUp_Init-PowerUp_Index
		dc.w	PowerUp_Move-PowerUp_Index
		dc.w	PowerUp_Apply-PowerUp_Index
		dc.w	PowerUp_Delete-PowerUp_Index

PowerUp_Init:
		addq.b	#2,act_routine(a0)
		move.w	#$680,act_tile(a0)
		move.l	#ItemBox_Maps,act_maps(a0)
		move.w	#(224-40)+128,act_yscr(a0)
		move.b	#0,act_pri(a0)
		move.b	act_type(a0),d0					; Get item type.
		cmp.b	#2,d0							; Is it a random ring?
		beq.s	@GetRand						; If so, we need to process which random ring we're getting before displaying a frame.
		add.b	#$B,d0							; Otherwise, just add $B to get the item frame.
		move.b	d0,act_frame(a0)
		bra.s	PowerUp_Move

@GetRand:
		jsr		(RandomNumber).l				; Generate a random number.
		andi.b	#%00000111,d1					; Cap it to 7 (We need 5 tho)
		cmp.b	#6,d1							; Is it 6 or above?
		blt.s	@Cont							; If not continue.
		subq.b	#2,d1							; Just subtract 2 to make sure we're in range ig.

@Cont:
		move.b	d1,act_free+0(a0)
		lea	(PowerUp_RandRingFrames).l,a1
		move.b	(a1,d1.w),act_frame(a0)

PowerUp_Move:
		addi.w	#10,act_xscr(a0)
		cmp.w	#(320/2)+128,act_xscr(a0)
		bcs.s	@Return
		addq.b	#2,act_routine(a0)

@Return:
		rts

PowerUp_RandRingFrames:
		dc.b	$B, $C, $D, $16, $17, $18
		even

PowerUp_Apply:
		moveq	#0,d0
		move.b	act_type(a0),d0
		asl		d0
		move.w	PowerUp_PowerIndex(pc,d0.w),d0
		jsr		PowerUp_PowerIndex(pc,d0.w)
		addq.b	#2,act_routine(a0)
		move.b	#120,act_anitime(a0)

PowerUp_Delete:
		subq.b	#1,act_anitime(a0)
		beq.s	@Delete
		rts

@Delete:
		jmp		DeleteObject

PowerUp_PowerIndex:
		dc.w	PowerUp_5Ring-PowerUp_PowerIndex
		dc.w	PowerUp_10Ring-PowerUp_PowerIndex
		dc.w	PowerUp_RandRing-PowerUp_PowerIndex
		dc.w	PowerUp_Shield-PowerUp_PowerIndex
		dc.w	PowerUp_Magnet-PowerUp_PowerIndex
		dc.w	PowerUp_Shoes-PowerUp_PowerIndex
		dc.w	PowerUp_Invinc-PowerUp_PowerIndex
		dc.w	PowerUp_Bomb-PowerUp_PowerIndex
		dc.w	PowerUp_Timer-PowerUp_PowerIndex
		dc.w	PowerUp_Life-PowerUp_PowerIndex

PowerUp_5Ring:
		moveq	#5,d0
		bra.w	PowerUp_ApplyRing

PowerUp_10Ring:
		moveq	#10,d0
		bra.s	PowerUp_ApplyRing

PowerUp_RandRing:
		moveq	#0,d0
		move.b	act_free+0(a0),d0
		asl		d0
		move.w	PowerUp_RingValues(pc,d0.w),d0
		bra.s	PowerUp_ApplyRing

PowerUp_RingValues:
		dc.w	5, 10, 1, 15, 20, 40
		even

PowerUp_ApplyRing:
		add.w	d0,($FFFFFE20).w
		ori.b	#1,($FFFFFE1D).w
		rts

PowerUp_Shield:
PowerUp_Magnet:
		move.b	#1,($FFFFFE2C).w ; give	Sonic a	shield
		move.b	#$38,($FFFFD180).w ; load shield object	($38)
		move.w	#$AF,d0
		jmp	(Sound_CueMusic).l	; play shield sound

PowerUp_Shoes:
		move.b	#1,($FFFFFE2E).w ; speed up the	BG music
		move.w	#$4B0,($FFFFD034).w ; time limit for the power-up
		move.w	#$C00,($FFFFF760).w ; change Sonic's top speed
		move.w	#$18,($FFFFF762).w
		move.w	#$80,($FFFFF764).w
		move.w	#$E2,d0
		jmp	(Sound_CueMusic).l	; Speed	up the music
	
PowerUp_Invinc:
		move.b	#1,($FFFFFE2D).w ; make	Sonic invincible
		move.w	#$4B0,($FFFFD032).w ; time limit for the power-up
		move.b	#$38,($FFFFD200).w ; load stars	object ($3801)
		move.b	#1,($FFFFD21C).w
		move.b	#$38,($FFFFD240).w ; load stars	object ($3802)
		move.b	#2,($FFFFD25C).w
		move.b	#$38,($FFFFD280).w ; load stars	object ($3803)
		move.b	#3,($FFFFD29C).w
		move.b	#$38,($FFFFD2C0).w ; load stars	object ($3804)
		move.b	#4,($FFFFD2DC).w
		move.w	#$87,d0
		jmp	(Sound_CueMusic).l	; play invincibility music

PowerUp_Bomb:
		rts

PowerUp_Timer:
		rts

PowerUp_Life:
		addq.b	#1,($FFFFFE12).w ; add 1 to the	number of lives	you have
		addq.b	#1,($FFFFFE1C).w ; add 1 to the	lives counter
		move.w	#$88,d0
		jmp	(Sound_CueMusic).l	; play extra life music

ItemBox_Maps:
		include	"Action Stage/Global/Actors/Item Box/Mappings.asm"