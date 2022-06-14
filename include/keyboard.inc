.ifndef SDK_KEYBOARD_INC

	;----------------------------------------------------------------------
	;
	;----------------------------------------------------------------------
	KEY_LCTRL  = 5
	KET_RCTRL  = 6
	KEY_LSHIFT = 7
	KEY_RSHIFT = 8
	KEY_FUNCT  = 9

	;----------------------------------------------------------------------
	;				ASCII codes
	;----------------------------------------------------------------------
	KEY_LEFT   = $08
	KEY_RIGHT  = $09
	KEY_DOWN   = $0A
	KEY_UP     = $0B
	KEY_RETURN = $0D
	KEY_ESC    = $1B
	KEY_DEL    = $7F

	;----------------------------------------------------------------------
	;				Scan codes
	;----------------------------------------------------------------------
	KEYCODE_1 = $A8		; !
	KEYCODE_2 = $B2		; @
	KEYCODE_3 = $B8		; #
	KEYCODE_4 = $9A		; $
	KEYCODE_5 = $90		; %
	KEYCODE_6 = $8A		; ^
	KEYCODE_7 = $80		; &
	KEYCODE_8 = $87		; *
	KEYCODE_9 = $8B		; (
	KEYCODE_0 = $97		; )
	KEYCODE_- = $9B		; £
	KEYCODE_= = $BF		; +
	KEYCODE_DEL = $AD

	KEYCODE_A = $AE
	KEYCODE_Z = $AA
	KEYCODE_E = $9E
	KEYCODE_R = $91
	KEYCODE_T = $89
	KEYCODE_Y = $86
	KEYCODE_U = $85
	KEYCODE_I = $8D
	KEYCODE_O = $95
	KEYCODE_P = $9D
	KEYCODE_LBRACKET = $BD		; [ {
	KEYCODE_RBRACKET = $B5		; ] }
	KEYCODE_QUOTE = $BB		; ' "

	KEYCODE_Q = $B1
	KEYCODE_S = $B6
	KEYCODE_D = $B9
	KEYCODE_F = $99
	KEYCODE_G = $96
	KEYCODE_H = $8E
	KEYCODE_J = $81
	KEYCODE_K = $83
	KEYCODE_L = $8F
	KEYCODE_M = $82
	KEYCODE_SEMICOLON = $93		; ; :
	KEYCODE_CR = $AF

	KEYCODE_W = $BE
	KEYCODE_X = $B0
	KEYCODE_C = $BA
	KEYCODE_V = $98
	KEYCODE_B = $92
	KEYCODE_N = $88
	KEYCODE_COMMA = $8C		; , <
	KEYCODE_DOT = $94		; . >
	KEYCODE_SLASH = $9F		; / ?
	KEYCODE_BACKSLASH = $B3		; \ |

	KEYCODE_Funct = $A5
	KEYCODE_Space = $84

	KEYCODE_LShift = $A4
	KEYCODE_LCtrl  = $A2
	KEYCODE_RShift = $A7
	KEYCODE_RCtrl  = $A0

	KEYCODE_Up    = $9C
	KEYCODE_Down  = $B4
	KEYCODE_Left  = $AC
	KEYCODE_Right = $BC

	KEYCODE_NOKEY  = $38

	;----------------------------------------------------------------------
	;
	;----------------------------------------------------------------------
	SDK_KEYBOARD_INC
.endif
