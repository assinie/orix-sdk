; vim: set ft=asm6502-2 ts=8:

;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------
	;error messages
	; Default: Error <acc>

	e1  := $01	; Memory full                   (command LOAD RUN)
	e2  := $02	; Disk full                     (write create)
	e3  := $03	; BOF                           (seek)
	e4  := $04	; EOF                           (read)
	e10 := $10	; Filename error                (more than 14 char.)
	e11 := $11	; Device error                  (directory select)
	e12 := $12	; Filename missing              (open)
	e13 := $13	; <filename> not found          (open)
	e15 := $15	; Option error
	e16 := $16	; Data error                    (hex/dec data)
	e20 := $20	; No more entries               (no entry to open a file)
	e21 := $21	; <filespec> open file          (try to open opened file)
	e25 := $25	; <filespec> delete protected   (delete)
	e26 := $26	; <filespec> write protected    (open w, w+)
	e27 := $27	; <filespec> read protected     (open r, r+)
	e28 := $28	; <filespec> permission denied  (open ext. bits)
	e29 := $29	; <filespec> incorrect format

	e30 := $30	; File not open
	e31 := $31	; Fd error                      (non existing fd)
	e35 := $35	; no delete alloeed             (delete)
	e36 := $36	; not write opened              (write)
	e37 := $37	; not read, seek opened         (read seek)
	e38 := $38	; no seek r/w
	e39 := $39	; seek function
	e41 := $41	; existing file                 (rename)
	e42 := $42	; not the same drive
	e46 := $46	; status function

	e80 := $80	; Write <drive>:<track>:<sector> protected
	e90 := $90	; Read <drive>:<track>:<sector> protected
	eb0 := $b0	; Dr:tr:sc <drive>:<track>:<sector> error
	ec0 := $c0	; Drive <drive> not ready
	ed0 := $d0	; Disk <drive> error            (disk protected)
	;		  add $01 for system, $02 for directory
	;		  and $04 for tsl sector

