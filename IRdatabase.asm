;IRdatabase.asm: Defninitions of known IR signal standards.
;This file must be included in .CSEG segment after linear-execution part of program code!


;--------------Cambridge Audio code. It is a distance code.-------------;
;After long startbit and pause, all pules are short. Pauses can be long or short.
.equ	CACD_STARTBIT_MAX=255	;startbit is 240
.equ	CACD_STARTBIT_MID=240
.equ	CACD_STARTBIT_MIN=211
.equ	CACD_PAUSE_MAX	=215	;pause after startbit is 207-208
.equ	CACD_PAUSE_MID	=207
.equ	CACD_PAUSE_MIN	=200
.equ	CACD_LONG_MAX	=90	;long pauses are 76-77
.equ	CACD_LONG_MID	=76
.equ	CACD_LONG_MIN	=65
.equ	CACD_SHORT_MAX	=36	;short pauses are 23-24 short pulses are 30-31
.equ	CACD_SHORT_MID	=27
.equ	CACD_SHORT_MIN	=18
;logical 1: short pulse and short pause
;logical 0: short pulse and long pause
;Command has 32 bits + 1 end bit
;First 16 bits are device number transmitted twice
;0b11111010 11111010
;Last 16 bits are command number transmitted twice (but the second time bitwise negated)

;----------------Technics code. It is a distance code.---------------;
;After long startbit and pause, all pules are short. Pauses can be long or short.
.equ	TECH_STARTBIT_MAX=188	;startbit is 175-176
.equ	TECH_STARTBIT_MID=175
.equ	TECH_STARTBIT_MIN=154
.equ	TECH_PAUSE_MAX	=90	;pause after startbit is 83-84
.equ	TECH_PAUSE_MID	=83
.equ	TECH_PAUSE_MIN	=75
.equ	TECH_LONG_MAX	=70	;long pauses are 61-62
.equ	TECH_LONG_MID	=61
.equ	TECH_LONG_MIN	=57
.equ	TECH_SHORT_MAX	=30	;short pauses are 18-20 short pulses are 23-24
.equ	TECH_SHORT_MID	=23
.equ	TECH_SHORT_MIN	=13
;logical 1: short pulse and short pause
;logical 0: short pulse and long pause
;Sequence has 48 bits + end bit
;First 32 bits are device number
;0b10111111111110111111101010101111
;Last 16 bits are command number

;---------RC5 biphase code. Both pauses and impulses can be long.---------;
.equ	RC5_LONG_MAX	=100	;long pauses are 80-81 long pulses are 92
.equ	RC5_LONG_MID	=85
.equ	RC5_LONG_MIN	=75
.equ	RC5_SHORT_MAX	=52	;short pauses 39 short pulses are 46-47
.equ	RC5_SHORT_MID	=46
.equ	RC5_SHORT_MIN	=13
;logical 1 and logical 0: https://secure.wikimedia.org/wikipedia/en/wiki/Biphase_mark_code
;Sequence has 14 bits. 
;First bit is a start bit (always 1) 
;Second bit is a field bit (1-commands 0-63,0-commands 64-127) 
;Third bit is a toggle bit (toggling each keypress)
;Next 5 bits are the device number
;0b10000
;Last 6 bits are the comand numbers;


;---------------startbit type numbering system----------------;
.equ	TYPE_ERROR=0
.equ	TYPE_CACD=1
.equ	TYPE_TECH=2
.equ	TYPE_RC5=3


;---------------Code tables for remapping of commands----------------;
;Keep'em sorted!
MAPPING_TABLE:
.equ	MAPPING_TABLE_COLS = 8	;number of columns in this table (row increment)
CACD_TABLE:	;	type	bits	s1	s2	c1	~c1

;CACD_KEY_HOLD:	.DB	1,	1,	0,
;CACD_ON:	.DB	1,	32,	95,	95,	185,	70,
;CACD_OFF:	.DB	1,	32,	95,	95,	186,	69,
CACD_SPACE:	.DB	1,	32,	95,	95,	225,	30
		.DW	TECH_VOL_PL
CACD_PAUSE:	.DB	1,	32,	95,	95,	226,	29
		.DW	TECH_PAUSE
CACD_STOP:	.DB	1,	32,	95,	95,	227,	28
		.DW	TECH_STOP
CACD_PROGRAM:	.DB	1,	32,	95,	95,	228,	27
		.DW	TECH_PROGRAM
CACD_NUM8:	.DB	1,	32,	95,	95,	229,	26
		.DW	TECH_NUM8
CACD_NUM4:	.DB	1,	32,	95,	95,	230,	25
		.DW	TECH_NUM4
CACD_A_B:	.DB	1,	32,	95,	95,	232,	23
		.DW	TECH_A_B
CACD_REPEAT:	.DB	1,	32,	95,	95,	233,	22
		.DW	TECH_REPEAT
CACD_PLAY:	.DB	1,	32,	95,	95,	234,	21
		.DW	TECH_PLAY
CACD_GRTH10:	.DB	1,	32,	95,	95,	236,	19
		.DW	TECH_GRTH10
CACD_NUM7:	.DB	1,	32,	95,	95,	237,	18
		.DW	TECH_NUM7
CACD_NUM3:	.DB	1,	32,	95,	95,	238,	17
		.DW	TECH_NUM3
CACD_REMAIN:	.DB	1,	32,	95,	95,	240,	15
		.DW	TECH_T_MODE
CACD_RANDOM:	.DB	1,	32,	95,	95,	241,	14
		.DW	TECH_RANDOM
CACD_SEARF:	.DB	1,	32,	95,	95,	242,	13
		.DW	TECH_SEARF
CACD_SKIPF:	.DB	1,	32,	95,	95,	243,	12
		.DW	TECH_SKIPF
CACD_NUM0:	.DB	1,	32,	95,	95,	244,	11
		.DW	TECH_NUM0
CACD_NUM6:	.DB	1,	32,	95,	95,	245,	10
		.DW	TECH_NUM6
CACD_NUM2:	.DB	1,	32,	95,	95,	246,	9
		.DW	TECH_NUM2
CACD_OPE_CLO:	.DB	1,	32,	95,	95,	248,	7
		.DW	TECH_OPE_CLO
CACD_INTRO:	.DB	1,	32,	95,	95,	249,	6
		.DW	TECH_VOL_MI
CACD_SEARB:	.DB	1,	32,	95,	95,	250,	5
		.DW	TECH_SEARB
CACD_SKIPB:	.DB	1,	32,	95,	95,	251,	4
		.DW	TECH_SKIPB
CACD_NUM9:	.DB	1,	32,	95,	95,	252,	3
		.DW	TECH_NUM9
CACD_NUM5:	.DB	1,	32,	95,	95,	253,	2
		.DW	TECH_NUM5
CACD_NUM1:	.DB	1,	32,	95,	95,	254,	1
		.DW	TECH_NUM1
MAPPING_TABLE_END:


TECH_TABLE:	;	type	bits	s1	s2	s3	s4	c1	c2

;TECH_SIDA_B:	.DB	2,	48,	253,	223,	95,	245,	83,	249
;TECH_TAP_LEN:	.DB	2,	48,	253,	223,	95,	245,	84,	254
;TECH_PK_SCH:	.DB	2,	48,	253,	223,	95,	245,	112,	218
;TECH_AUT_CUE:	.DB	2,	48,	253,	223,	95,	245,	116,	222
TECH_PROGRAM:	.DB	2,	48,	253,	223,	95,	245,	117,	223
;TECH_NUM10:	.DB	2,	48,	253,	223,	95,	245,	122,	208
TECH_GRTH10:	.DB	2,	48,	253,	223,	95,	245,	123,	209
;TECH_RECALL:	.DB	2,	48,	253,	223,	95,	245,	126,	212
;TECH_CLEAR:	.DB	2,	48,	253,	223,	95,	245,	127,	213
TECH_T_MODE:	.DB	2,	48,	253,	223,	95,	245,	170,	0
TECH_RANDOM:	.DB	2,	48,	253,	223,	95,	245,	178,	24
TECH_SKIPF:	.DB	2,	48,	253,	223,	95,	245,	181,	31
TECH_SKIPB:	.DB	2,	48,	253,	223,	95,	245,	182,	28
TECH_A_B:	.DB	2,	48,	253,	223,	95,	245,	183,	29
TECH_REPEAT:	.DB	2,	48,	253,	223,	95,	245,	184,	18
TECH_VOL_MI:	.DB	2,	48,	253,	223,	95,	245,	222,	116
TECH_VOL_PL:	.DB	2,	48,	253,	223,	95,	245,	223,	117
TECH_NUM0:	.DB	2,	48,	253,	223,	95,	245,	230,	76
TECH_NUM9:	.DB	2,	48,	253,	223,	95,	245,	231,	77
TECH_NUM8:	.DB	2,	48,	253,	223,	95,	245,	232,	66
TECH_NUM7:	.DB	2,	48,	253,	223,	95,	245,	233,	67
TECH_NUM6:	.DB	2,	48,	253,	223,	95,	245,	234,	64
TECH_NUM5:	.DB	2,	48,	253,	223,	95,	245,	235,	65
TECH_NUM4:	.DB	2,	48,	253,	223,	95,	245,	236,	70
TECH_NUM3:	.DB	2,	48,	253,	223,	95,	245,	237,	71
TECH_NUM2:	.DB	2,	48,	253,	223,	95,	245,	238,	68
TECH_NUM1:	.DB	2,	48,	253,	223,	95,	245,	239,	69
TECH_PLAY:	.DB	2,	48,	253,	223,	95,	245,	245,	95
TECH_PAUSE:	.DB	2,	48,	253,	223,	95,	245,	249,	83
TECH_SEARF:	.DB	2,	48,	253,	223,	95,	245,	252,	86
TECH_SEARB:	.DB	2,	48,	253,	223,	95,	245,	253,	87
TECH_OPE_CLO:	.DB	2,	48,	253,	223,	95,	245,	254,	84
TECH_STOP:	.DB	2,	48,	253,	223,	95,	245,	255,	85

