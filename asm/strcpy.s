.include "telestrat.inc"

.export _strcpy

;.org $0801
.segment "CODE"


.proc _strcpy

	ldy #$00
loop:
	lda (RES),y
	beq end
	sta (RESB),y
	iny
.IFPC02
.pc02
	bra loop
.p02  
.else
	jmp loop
.endif
end:
	sta (RESB),y
	; y return the length
	rts
.endproc

