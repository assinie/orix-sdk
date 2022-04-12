.feature labels_without_colons, c_comments
.listbytes unlimited
.debuginfo

;----------------------------------------------------------------------
;			Tests des Macros
;----------------------------------------------------------------------
/*
 # Assemblage
 cl65 -t none -Ln macros-tests.ca.sym --listing macros-tests.lst --asm-include-dir ../ macros-tests.s

 # Génération du fichier .info
 sed -re '/LOCAL-MACRO/d; /__/d; s/al 00(.{4}) \.(.+)$$/\1 \2/' macros-tests.ca.sym | sort | sed -re 's/^([^ ]+) (.+)/label { addr $\1; name "\2"; };/; s/"(RES|RESB|PTR_READ_DEST|ptr1|ptr2|fp|var|_argv)";/"\1"; size 2;/' > macros-tests.info

 # Ajout des commentaires au fichier .info
 sed -nre ':x /^[^ ]+[0-9]{2}$/ { N; s/\n//g ; bx ; } ; /^[^ ]+[0-9]{2}/p'  macros-tests.s | sed -re 's#(.+)\t(.+)$#s/"\1"/"\1"; comment "\\n; \2"\\n;/;#' | sed -f - -i macros-tests.info

 # Désassemblage
 ../../../cc65/bin/da65 -o macros-tests.out --comments 3 --start-addr 0x1000 --info macros-tests.info macros-tests
*/

/*
label { addr $1FD7; name "src"; size 10; };
range { start $1FD7; end $1FE0; name "src"; type bytetable; };

label { addr $1FE1; name "dst"; size 10; };
range { start $1FE1; end $1FEA; name "dst"; type bytetable; };

label { addr $1FEB; name "ptr1"; size 2; };
range { start $1FEB; end $1FEC; name "ptr1"; type addrtable; };

label { addr $1FED; name "ptr2"; size 2; };
range { start $1FED; end $1FEE; name "ptr2"; type addrtable; };

label { addr $1FEF; name "fp"; size 2; };
range { start $1FEF; end $1FF0; name "fp"; type wordtable; };

label { addr $1FF1; name "msg"; size 6; };
range { start $1FF1; end $1FF6; name "msg"; type texttable; };

label { addr $1FF8; name "_argc"; };

label { addr $1FF9; name "_argv"; size 2; };
range { start $1FF9; end $1FFA; name "_argv"; type addrtable; };
*/

;----------------------------------------------------------------------
;			Orix SDK includes
;----------------------------------------------------------------------
.include "macros/SDK.mac"
;.include "include/SDK.inc"
;.include "macros/types.mac"


;----------------------------------------------------------------------
; Defines / Constants
;----------------------------------------------------------------------
	XWR0 = $10
	XWSTR0 = $14
	XCRLF = $25
	XFREAD = $27
	XOPEN = $30
	XCOSCR = $34
	XCSSCR = $35
	XCLOSE = $3a
	XFWRITE = $3b
	XFSEEK = $3f
	XMKDIR = $4b
	XMALLOC = $5b
	XFREE = $62
	XFSEEK = $3f

	; Path Management
	XGETCWD  = $48          ; Get current CWD
	XPUTCWD  = $49          ; Chdir

	; Main args
	XMAINARGS = $2c
	XGETARGV = $2e

	O_RDONLY = $01

	var = $5678

;----------------------------------------------------------------------
;				Page Zéro
;----------------------------------------------------------------------
.zeropage
	RES: .res 2
	RESB: .res 2

	zptr: .res 2

	PTR_READ_DEST  := $2C


;----------------------------------------------------------------------
;				Variables
;----------------------------------------------------------------------
.segment "DATA"
	src: .res 10, 0
	dst: .res 10, 0
	ptr1: .res 2, 0
	ptr2: .res 2, 0
	fp: .res 2,0
	msg: .asciiz "Erreur"


	_argc:
		.res 1, 0
	_argv:
		.res 2, 0


;----------------------------------------------------------------------
;				Dummy Code
;----------------------------------------------------------------------
.segment "CODE"

_strcpy
	rts
_strcat
	rts
_strlen
	rts


XWR0_ROUTINE
	rts

XWSTR0_ROUTINE
	rts

XOPEN_ROUTINE
	rts

XCLOSE_ROUTINE
	rts

XMKDIR_ROUTINE
	rts

XFREE_ROUTINE
	rts

XGETCWD_ROUTINE
	rts

XPUTCWD_ROUTINE
	rts


_init_argv
	rts
_get_argv
	rts

func:
	rts


;----------------------------------------------------------------------
;			Tests des Macros
;----------------------------------------------------------------------
.segment "CODE"


;======================================================================
;			String functions
;======================================================================

;----------------------------------------------------------------------
;
; usage:
;	strcpy dest, src
;
; Call _strcpy function
;
; note:
;	dest: may be nothing, AY, (ptr), address
;	src : may be nothing, AY, (ptr), address
;----------------------------------------------------------------------
strcpy01
	strcpy dst, src

strcpy02
	strcpy (ptr1), src

strcpy03
	strcpy dst, (ptr2)

strcpy04
	strcpy (ptr1), (ptr2)

strcpy05
	strcpy AY, src

strcpy06
	strcpy AY, (ptr2)

strcpy07
	strcpy dst, AY

strcpy08
	strcpy (ptr1), AY

	;----------------------------------------------------------------------

strcpy11
	strcpy , src

strcpy12
	strcpy , (ptr2)

strcpy13
	strcpy , AY

	;----------------------------------------------------------------------

strcpy21
	strcpy dst

strcpy22
	strcpy (ptr1)

strcpy23
	strcpy AY


;----------------------------------------------------------------------
;
; usage:
;	strcat dest, src
;
; Call _strcat function
;
; note:
;	dest: may be nothing, AY, (ptr), address
;	src : may be nothing, AY, (ptr), address
;----------------------------------------------------------------------
strcat01
	strcat dst, src

strcat02
	strcat (ptr1), src

strcat03
	strcat dst, (ptr2)

strcat04
	strcat (ptr1), (ptr2)

strcat05
	strcat AY, src

strcat06
	strcat AY, (ptr2)

strcat07
	strcat dst, AY

strcat08
	strcat (ptr1), AY

	;----------------------------------------------------------------------

strcat11
	strcat , src

strcat12
	strcat , (ptr2)

strcat13
	strcat , AY

	;----------------------------------------------------------------------

strcat21
	strcat dst

strcat22
	strcat (ptr1)

strcat23
	strcat AY


;----------------------------------------------------------------------
;
; usage:
;	strlen str
;	strlen (ptr)
;
; Call _strlen function
;
;----------------------------------------------------------------------
strlen01
	strlen src

strlen02
	strlen (ptr1)

;======================================================================
;				Print
;======================================================================

;----------------------------------------------------------------------
;
; usage:
;	print #byte [,TELEMON|NOSAVE]
;	print (pointer) [,TELEMON|NOSAVE]
;	print address [,TELEMON|NOSAVE]
;
; Option:
;	- TELEMON: when used within TELEMON bank
;	- NOSAVE : does not preserve A,X,Y registers
;
; Call XWSTR0 function
;
;----------------------------------------------------------------------
print01
	print #'A'

print02
	print #$41

print03
	print (ptr1)

print04
	print src

print05
	print $1234

	;----------------------------------------------------------------------

print11
	print #'A', NOSAVE

print12
	print #$41, NOSAVE

print13
	print (ptr1), NOSAVE

print14
	print src, NOSAVE

print15
	print $1234, NOSAVE

	;----------------------------------------------------------------------

print21
	print #'A', TELEMON

print22
	print #$41, TELEMON

print23
	print (ptr1), TELEMON

print24
	print src, TELEMON

print25
	print $1234, TELEMON

;======================================================================
;			Memory functions
;======================================================================

;----------------------------------------------------------------------
;
; usage:
;	malloc size [,ptr] [,oom_msg_ptr] [,fail_value]
;
;	malloc AY
;	malloc #$0100
;	malloc (ptr)
;	malloc value
;
; Note:
;	- if parameter 'size' is 'AY', get size from AY registers
;	  (A=LSB, Y=MSB)
;	- if parameter 'ptr' is present, store resulting AY in ptr &ptr+1
;	- if parameter 'oom_msg_ptr' is present, emit string pointed by
;		'oom_msg_ptr' and return if AY is null (ie malloc error)
;
; Call XMALLOC function
;
;----------------------------------------------------------------------

malloc01
	malloc AY

malloc02
	malloc AY, ptr1

malloc03
	malloc AY, ptr1, msg

malloc04
	malloc AY, , msg


	;----------------------------------------------------------------------

malloc11
	malloc AY, , , $12

malloc12
	malloc AY, ptr1, , $12

malloc13
	malloc AY, ptr1, msg, $12

malloc14
	malloc AY, , msg, $12

	;----------------------------------------------------------------------

malloc21
	malloc #$1234

malloc22
	malloc #$1234, ptr1

malloc23
	malloc #$1234, ptr1, msg

malloc24
	malloc #$1234, , msg

malloc25
	malloc var

malloc26
	malloc (ptr1)

	;----------------------------------------------------------------------

malloc31
	malloc #$1234, , , $12

malloc32
	malloc #$1234, ptr1, , $12

malloc33
	malloc #$1234, ptr1, msg, $12

malloc34
	malloc #$1234, , msg, $12

malloc35
	malloc var, , , $12

malloc36
	malloc (ptr1), , , $12

;----------------------------------------------------------------------
;
; usage:
;	mfree (ptr)
;
; Call XFREE function
;----------------------------------------------------------------------
mfree01
	mfree (ptr1)


;======================================================================
;				File
;======================================================================

;----------------------------------------------------------------------
;
; usage:
;	fopen file, mode [,TELEMON] [,ptr] [,oom_msg_ptr] [,fail_value]
;
; note:
;	- file may be: (ptr), address
;	- if parameter 'ptr' is present, store resulting AY in ptr &ptr+1
;	- if parameter 'oom_msg_ptr' is present, emit string pointed by
;		'oom_msg_ptr' and return if AY is null (ie malloc error)
;
; Call XOPEN function
;----------------------------------------------------------------------
fopen01
	fopen #$1234, O_RDONLY

fopen02
	fopen (ptr1), O_RDONLY

fopen03
	fopen src, O_RDONLY

	;----------------------------------------------------------------------

fopen11
	fopen #$1234, O_RDONLY, , ptr1

fopen12
	fopen (ptr1), O_RDONLY, , ptr1

fopen13
	fopen src, O_RDONLY, , ptr1

	;----------------------------------------------------------------------

fopen21
	fopen #$1234, O_RDONLY, , , msg

fopen22
	fopen (ptr1), O_RDONLY, , , msg

fopen23
	fopen src, O_RDONLY, , , msg

	;----------------------------------------------------------------------

fopen31
	fopen #$1234, O_RDONLY, , , , $EC

fopen32
	fopen (ptr1), O_RDONLY, , , , $EC

fopen33
	fopen src, O_RDONLY, , , , $EC

	;----------------------------------------------------------------------

fopen41
	fopen #$1234, O_RDONLY, , ptr1 , msg

fopen42
	fopen (ptr1), O_RDONLY, , ptr1, msg

fopen43
	fopen src, O_RDONLY, , ptr1, msg


fopen44
	fopen #$1234, O_RDONLY, , ptr1 , msg, $EC

fopen45
	fopen (ptr1), O_RDONLY, , ptr1, msg, $EC

fopen46
	fopen src, O_RDONLY, , ptr1, msg, $EC


fopen47
	fopen #$1234, O_RDONLY, , ptr1 , , $EC

fopen48
	fopen (ptr1), O_RDONLY, , ptr1, , $EC

fopen49
	fopen src, O_RDONLY, , ptr1, , $EC

	;----------------------------------------------------------------------

fopen51
	fopen #$1234, O_RDONLY, TELEMON

fopen52
	fopen (ptr1), O_RDONLY, TELEMON

fopen53
	fopen src, O_RDONLY, TELEMON

	;----------------------------------------------------------------------

fopen61
	fopen #$1234, O_RDONLY, TELEMON, ptr1

fopen62
	fopen (ptr1), O_RDONLY, TELEMON, ptr1

fopen63
	fopen src, O_RDONLY, TELEMON, ptr1

	;----------------------------------------------------------------------

fopen71
	fopen #$1234, O_RDONLY, TELEMON, , msg

fopen72
	fopen (ptr1), O_RDONLY, TELEMON, , msg

fopen73
	fopen src, O_RDONLY, TELEMON, , msg


fopen74
	fopen #$1234, O_RDONLY, TELEMON, , msg, $EC

fopen75
	fopen (ptr1), O_RDONLY, TELEMON, , msg, $EC

fopen76
	fopen src, O_RDONLY, TELEMON, , msg, $EC


fopen77
	fopen #$1234, O_RDONLY, TELEMON, , , $EC

fopen78
	fopen (ptr1), O_RDONLY, TELEMON, , , $EC

fopen79
	fopen src, O_RDONLY, TELEMON, , , $EC

	;----------------------------------------------------------------------

fopen81
	fopen #$1234, O_RDONLY, TELEMON, ptr1, msg

fopen82
	fopen (ptr1), O_RDONLY, TELEMON, ptr1, msg

fopen83
	fopen src, O_RDONLY, TELEMON, ptr1, msg


fopen84
	fopen #$1234, O_RDONLY, TELEMON, ptr1, msg, $EC

fopen85
	fopen (ptr1), O_RDONLY, TELEMON, ptr1, msg, $EC

fopen86
	fopen src, O_RDONLY, TELEMON, ptr1, msg, $EC


fopen87
	fopen #$1234, O_RDONLY, TELEMON, ptr1, , $EC

fopen88
	fopen (ptr1), O_RDONLY, TELEMON, ptr1, , $EC

fopen89
	fopen src, O_RDONLY, TELEMON, ptr1, , $EC


;----------------------------------------------------------------------
;
; usage:
;	fread ptr, size, count, fp
;
; note:
;	ptr may be : (ptr), address
;	size may be: (ptr), address
;	fp may be  : address, #value, {address,y}
;
; Call XFREAD function
;----------------------------------------------------------------------
fread01
	fread #$1234, #$1234, dummy, fp

fread02
	fread #$1234, (ptr2), dummy, fp

fread03
	fread #$1234, var, dummy, fp

	;----------------------------------------------------------------------

fread11
	fread (ptr1), #$1234, dummy, fp

fread12
	fread (ptr1), (ptr2), dummy, fp

fread13
	fread (ptr1), var, dummy, fp

	;----------------------------------------------------------------------

fread21
	fread src, #$1234, dummy, fp

fread22
	fread src, (ptr2), dummy, fp

fread23
	fread src, var, dummy, fp


;----------------------------------------------------------------------
;
; usage:
;	fwrite ptr, size, count, fp
;
; note:
;	ptr may be : (ptr), address
;	size may be: (ptr), address
;	fp may be  : address, #value, {address,y}
;
; Call XFWRITE function
;----------------------------------------------------------------------
fwrite01
	fwrite #$1234, #$1234, dummy, fp

fwrite02
	fwrite #$1234, (ptr2), dummy, fp

fwrite03
	fwrite #$1234, var, dummy, fp

	;----------------------------------------------------------------------

fwrite11
	fwrite (ptr1), #$1234, dummy, fp

fwrite12
	fwrite (ptr1), (ptr2), dummy, fp

fwrite13
	fwrite (ptr1), var, dummy, fp

	;----------------------------------------------------------------------

fwrite21
	fwrite src, #$1234, dummy, fp

fwrite22
	fwrite src, (ptr2), dummy, fp

fwrite23
	fwrite src, var, dummy, fp


;----------------------------------------------------------------------
;
; usage:
;	fclose (fp) [,TELEMON]
;
; Call XCLOSE function
;----------------------------------------------------------------------
fclose01
	fclose (ptr1)

fclose02
	fclose (ptr1), TELEMON


;----------------------------------------------------------------------
;
; usage:
;	fseek fp, offset, whence
;
; note:
;	fp may be : (ptr), address
;	offset may be: (ptr), address, constant
;	whence may be  : address, #value
;
; Call XFSEEK function
;----------------------------------------------------------------------
fseek01
	fseek fp, $12345678, 2

fseek02
	fseek fp, (zptr), 2

fseek03
	fseek fp, src, 2


;----------------------------------------------------------------------
;
; usage:
;	mkdir ptr [,TELEMON]
;
; note:
;	ptr may be: (ptr), address
;
; Call XMKDIR function
;----------------------------------------------------------------------
mkdir01
	mkdir #$1234

mkdir02
	mkdir (ptr1)

mkdir03
	mkdir src

	;----------------------------------------------------------------------

mkdir11
	mkdir #$1234, TELEMON

mkdir12
	mkdir (ptr1), TELEMON

mkdir13
	mkdir src, TELEMON


;----------------------------------------------------------------------
;
; usage:
;	chdir ptr [,TELEMON]
;
; note:
;	ptr may be: (ptr), address
;
; Call XPUTCWD function
;----------------------------------------------------------------------
chdir01
	chdir #$1234

chdir02
	chdir (ptr1)

chdir03
	chdir src

	;----------------------------------------------------------------------

chdir11
	chdir #$1234, TELEMON

chdir12
	chdir (ptr1), TELEMON

chdir13
	chdir src, TELEMON


;----------------------------------------------------------------------
;
; usage:
;	getcwd ptr [,TELEMON]
;
; note:
;	ptr may be: ptr, address
;
; Call XGETCWD function
;----------------------------------------------------------------------
getcwd01
	getcwd ptr1

getcwd02
	getcwd $5678

	;----------------------------------------------------------------------

getcwd11
	getcwd ptr1, TELEMON

getcwd12
	getcwd $5678, TELEMON


;======================================================================
;			ARGV/ARGC
;======================================================================

;----------------------------------------------------------------------
; init_argv
;
; usage:
;	init_argv argv, cmdline
;
; Note:
;	argv must the address of a buffer
;	argv may be   : address, (ptr), #value
;	cmdline may be: address, (ptr), #value
;
; Initialize _argv array & _argc, must be called before get_argv
;----------------------------------------------------------------------
; #value interdit
;----------------------------------------------------------------------
init_argv01
	init_argv dst, AY

init_argv02
	init_argv dst, src

init_argv03
	init_argv dst, (ptr1)

	;----------------------------------------------------------------------

init_argv11
	init_argv AY, src

init_argv12
	init_argv AY, (ptr1)

	;----------------------------------------------------------------------

init_argv21
	init_argv (ptr2), AY

init_argv22
	init_argv (ptr2), src

init_argv23
	init_argv (ptr2), (ptr1)


;----------------------------------------------------------------------
; get_argv
;
; usage:
;	ldx index
;	get_argv
;
; Note:
;	Use _argv
;
; Get the argument N° X from _argv
;----------------------------------------------------------------------
get_argv01
	get_argv


;======================================================================
;			Main arguments
;======================================================================

;----------------------------------------------------------------------
; initmainargs
;
; usage:
;	initmainargs [ptr_mainargs] [, value_address]
;
; note:
;       ptr_mainargs : may be nothing, AY, address
;       value_address: may be nothing, X, address
;
; Call XMAINARGS function
;----------------------------------------------------------------------
initmainargs_01
	initmainargs

initmainargs_02
	initmainargs AY

initmainargs_03
	initmainargs _argv

	;----------------------------------------------------------------------

initmainargs_11
	initmainargs , X

initmainargs_12
	initmainargs AY, X

initmainargs_13
	initmainargs _argv, X

	;----------------------------------------------------------------------

initmainargs_21
	initmainargs , _argc

initmainargs_22
	initmainargs AY, _argc

initmainargs_23
	initmainargs _argv, _argc


;----------------------------------------------------------------------
; getmainarg
;
; usage:
;	getmainarg id_arg [, ptr_arg] [, out_ptr]
;
; note:
;	id_arg : may be X, #value, address
;       ptr_arg: may be nothing, AY, (ptr), address
;       out_ptr: may be nothing, AY, address
;
; Call XGETARGV function
;----------------------------------------------------------------------
getmainarg_01
	getmainarg X

getmainarg_02
	getmainarg X, AY

getmainarg_03
	getmainarg X, (ptr1)

getmainarg_04
	getmainarg X, _argv

getmainarg_05
	getmainarg X, ,AY

getmainarg_06
	getmainarg X, , dst

	;----------------------------------------------------------------------
getmainarg_11
	getmainarg #2

getmainarg_12
	getmainarg #2, AY

getmainarg_13
	getmainarg #2, (ptr1)

getmainarg_14
	getmainarg #2, _argv

getmainarg_15
	getmainarg #2, , AY

getmainarg_16
	getmainarg #2, , dst

	;----------------------------------------------------------------------

getmainarg_21
	getmainarg _argc

getmainarg_22
	getmainarg _argc, AY

getmainarg_23
	getmainarg _argc, (ptr1)

getmainarg_24
	getmainarg _argc, _argv

getmainarg_25
	getmainarg _argc, , AY

getmainarg_26
	getmainarg _argc, , dst

	;----------------------------------------------------------------------

getmainarg_31
	getmainarg X, AY, AY

getmainarg_32
	getmainarg X, AY, dst

getmainarg_33
	getmainarg X, (ptr1), AY

getmainarg_34
	getmainarg X, (ptr1), dst

getmainarg_35
	getmainarg X, _argv, AY

getmainarg_36
	getmainarg X, _argv, dst

	;----------------------------------------------------------------------

getmainarg_41
	getmainarg #2, AY, AY

getmainarg_42
	getmainarg #2, AY, dst

getmainarg_43
	getmainarg #2, (ptr1), AY

getmainarg_44
	getmainarg #2, (ptr1), dst

getmainarg_45
	getmainarg #2, _argv, AY

getmainarg_46
	getmainarg #2, _argv, dst

	;----------------------------------------------------------------------

getmainarg_51
	getmainarg _argc, AY, AY

getmainarg_52
	getmainarg _argc, AY, dst

getmainarg_53
	getmainarg _argc, (ptr1), AY

getmainarg_54
	getmainarg _argc, (ptr1), dst

getmainarg_55
	getmainarg _argc, _argv, AY

getmainarg_56
	getmainarg _argc, _argv, dst


;======================================================================
;				Misc
;======================================================================
;----------------------------------------------------------------------
;
; usage:
;	cursor ON|OFF
;
; Call XCSSCR/XCOSCR functions
;----------------------------------------------------------------------
cursor01
	cursor on

cursor02
	cursor ON

	;----------------------------------------------------------------------

cursor03
	cursor off

cursor04
	cursor OFF


;======================================================================
;			Pointer functions
;======================================================================
;----------------------------------------------------------------------
; check_regs
;
; usage:
;	check_regs regs [,err_value] [,oom_msg_ptr] [,fail_value]
;
; Note:
;	regs is one of: AX, AY, XY, XA, YA, YX
;
; Check regs pair, display oom_msg_ptr and return if regs pairs is err_value
;----------------------------------------------------------------------
check_regs01
	check_regs AX

check_regs02
	check_regs AY

check_regs03
	check_regs XA

check_regs04
	check_regs XY

check_regs05
	check_regs YA

check_regs06
	check_regs YX

	;----------------------------------------------------------------------

check_regs11
	check_regs AX, $ff

check_regs12
	check_regs AY, $ff

check_regs13
	check_regs XA, $ff

check_regs14
	check_regs XY, $ff

check_regs15
	check_regs YA, $ff

check_regs16
	check_regs YX, $ff

	;----------------------------------------------------------------------

check_regs21
	check_regs AX, , msg

check_regs22
	check_regs AY, , msg

check_regs23
	check_regs XA, , msg

check_regs24
	check_regs XY, , msg

check_regs25
	check_regs YA, , msg

check_regs26
	check_regs YX, , msg

	;----------------------------------------------------------------------

check_regs31
	check_regs AX, , , $01

check_regs32
	check_regs AY, , , $01

check_regs33
	check_regs XA, , , $01

check_regs34
	check_regs XY, , , $01

check_regs35
	check_regs YA, , , $01

check_regs36
	check_regs YX, , , $01

	;----------------------------------------------------------------------

check_regs41
	check_regs AX, , msg, $01

check_regs42
	check_regs AY, , msg, $01

check_regs43
	check_regs XA, , msg, $01

check_regs44
	check_regs XY, , msg, $01

check_regs45
	check_regs YA, , msg, $01

check_regs46
	check_regs YX, , msg, $01


;======================================================================
;			SDK_utils
;======================================================================
	;----------------------------------------------------------------------
	; accept:
	;		   - #byte	-> lda #arg
	;		   - (pointer)	-> lda arg / ldy arg+1
	;		   - address	-> lda #<address / ldy #>address
	;----------------------------------------------------------------------
SDK_imm_or_ind_or_abs01
	SDK_imm_or_ind_or_abs #$1234

SDK_imm_or_ind_or_abs02
	SDK_imm_or_ind_or_abs (ptr1)

SDK_imm_or_ind_or_abs03
	SDK_imm_or_ind_or_abs var

SDK_imm_or_ind_or_abs04
	SDK_imm_or_ind_or_abs $1234

	;----------------------------------------------------------------------
	; accept:
	;		   - #word	-> lda #<arg / ldy #>arg
	;		   - (pointer)	-> lda arg / ldy arg+1
	;		   - address	-> lda #<address / ldy #>address
	;----------------------------------------------------------------------
SDK_get_AY01
	SDK_get_AY #$1234

SDK_get_AY02
	SDK_get_AY (ptr1)

SDK_get_AY03
	SDK_get_AY var

SDK_get_AY04
	SDK_get_AY $1234

	;----------------------------------------------------------------------
	; accept:
	;		   - #word	-> lda #<arg / ldx #>arg
	;		   - (pointer)	-> lda arg / ldx arg+1
	;		   - address	-> lda #<address / ldx #>address
	;----------------------------------------------------------------------
SDK_get_AX01
	SDK_get_AX #$1234

SDK_get_AX02
	SDK_get_AX (ptr1)

SDK_get_AX03
	SDK_get_AX var

SDK_get_AX04
	SDK_get_AX $1234

	;----------------------------------------------------------------------
	; Place les paramètres dans RES et RESB puis appelle la fonction func
	;
	; dest -> RESB
	; src  -> RES
	;
	; Si dest/src n'est pas indiqué, la valeur de RESB/RES n'est pas modifiée
	; Si dest/src est 'AY', on place la valeur des registres AY dans RESB/RES
	; Si func n'est pas indiqué, seuls RES et RESB sont mis à jour et il
	; n'y aura pas d'appel vers une fonction.
	;
	;----------------------------------------------------------------------
SDK_call_function01
	SDK_call_function func, $1234

SDK_call_function02
	SDK_call_function func, dst

SDK_call_function03
	SDK_call_function func, (ptr2)


SDK_call_function11
	SDK_call_function func, dst, $1234

SDK_call_function12
	SDK_call_function func, dst, src

SDK_call_function13
	SDK_call_function func, dst, (ptr1)


SDK_call_function21
	SDK_call_function func, , $1234

SDK_call_function22
	SDK_call_function func, , src

SDK_call_function23
	SDK_call_function func, , (ptr1)


SDK_call_function31
	SDK_call_function func, (ptr2), $1234

SDK_call_function32
	SDK_call_function func, (ptr2), src

SDK_call_function33
	SDK_call_function func, (ptr2), (ptr1)

