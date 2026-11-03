; ==================================================
; Joypad.asm
; Initializes and processes joypad input
;
; Author: Kilo
; 14-11-2024
; ==================================================

; ----------<Initialization>----------
Joypad_Init:
		Z80_Pause
		move.b	#$40,(io_ctrl1).l
		Z80_Start
		rts	

; ----------<Processing>----------
Joypad_Process:
		lea	(jpad_held).w,a0
		lea	(io_data1).l,a1
		move.b	#0,(a1)			; Pull low, first read.
		nop	
		nop	
		move.b	(a1),d0			; Get data, Start and A.
		lsl.b	#2,d0			; Shift left 2 bits.
		andi.b	#%11000000,d0	; Mask out any other bits that aren't Start or A.
		move.b	#$40,(a1)		; Pull high, second read.
		nop	
		nop	
		move.b	(a1),d1			; Get data, D-Pad, B, and C.
		andi.b	#%00111111,d1	; Mask out any bits that aren't the D-Pad, B, or C.
		or.b	d1,d0			; Put together all inputs.
		not.b	d0				; Invert.
		move.b	(a0),d1			; Get inputs read from previous frame.
		eor.b	d0,d1
		move.b	d0,(a0)+		; Buttons that were active the previous frame that are active this frame are held.
		and.b	d0,d1
		move.b	d1,(a0)+		; And any buttons that weren't pressed before are now pressed.
		rts

; ==================================================
; End of file
; ==================================================