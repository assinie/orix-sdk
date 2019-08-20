.include "telestrat.inc"

.export _strcat

.segment "CODE"

; strcat (RES, RESB)

.proc _strcat
    ldy #$00
loop:
    lda (RES),y
    beq end_string_found
    iny
    bne loop
    beq end ; prevent BOF

end_string_found:
    tya
    clc
    adc RES
    bcc skip
    inc RES+1
skip:
    sta RES

    ldy #$00
loopcopy:
    lda (RESB),y
    beq end
    sta (RES),y
    iny
    bne loopcopy
;    beq end

end:
    lda #$00
    sta (RES),y
    ; y return the length
    rts
.endproc

