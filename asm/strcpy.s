.include "telestrat.inc"

.export _strcpy

.segment "CODE"


.proc _strcpy

	ldy #$00
loop:
	lda (RES),y
	beq end
	sta (RESB),y
	iny
	bne loop
	tya	; <=> lda #$00
end:
	sta (RESB),y
	; y return the length
	rts
.endproc

