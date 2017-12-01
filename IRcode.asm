CODE:
	ldi	ZL,low(DATA_OUT)
	ldi	ZH,high(DATA_OUT)

	ldi	YL,low(DATA_MAP_TYPE)
	ldi	YH,high(DATA_MAP_TYPE)

	ldi	XL,low(DATA_OUT_END)
	ldi	XH,high(DATA_OUT_END)
	
	ld	A,Y+	;Load the type of command to encode
	
	cpi	A,TYPE_ERROR
	breq	CODE_END
	
	cpi	A,TYPE_CACD
	breq	CODE_CACD
	
	cpi	A,TYPE_RC5
	breq	CODE_RC5
	
	cpi	A,TYPE_TECH
	breq	CODE_TECH

	rjmp	CODE_ERR
	
CODE_CACD:
	ldi	G,CACD_STARTBIT_MID
	ldi	H,CACD_PAUSE_MID
	ldi	I,CACD_LONG_MID
	ldi	J,CACD_SHORT_MID
	rjmp	CODE_DISTANCE
CODE_TECH:
	ldi	G,TECH_STARTBIT_MID
	ldi	H,TECH_PAUSE_MID
	ldi	I,TECH_LONG_MID
	ldi	J,TECH_SHORT_MID
	rjmp	CODE_DISTANCE
CODE_RC5:
	ldi	G,RC5_LONG_MID
	ldi	H,RC5_SHORT_MID
	rjmp	CODE_BIPHASE
	
CODE_ERR:	
CODE_END:
	sbiw	ZH:ZL,1
	sts	DATA_OUT_END,ZL
	sts	DATA_OUT_END+1,ZH
	ret
	
CODE_DISTANCE:
	st	Z+,G	;store startbit
	st	Z+,H	;and pause after it
	
	ld	A,Y+	;A is the number of bits to process
	mov	B,A
	lsr	B
	lsr	B
	lsr	B	;B is the number of bytes to read minus 1
	clr	C	;bit in byte counter

COD_DIS_BYTE_LOOP:
	tst	B
	breq	COD_DIS_END
	dec	B
	ld	D,Y+	;D is the current byte
	andi	C,0b00000111
COD_DIS_BIT_LOOP:
	lsr	D	;shifts to right and sets/clears carry flag according to bit 0
	rcall	COD_DIS_W	
	inc	C
	sbrc	C,3
	rjmp	COD_DIS_BYTE_LOOP
	rjmp	COD_DIS_BIT_LOOP
	
COD_DIS_END:
	st	Z+,J	;store the endbit
	st	Z+,B	;store null endbit (B _should_ be zero)
	rjmp	CODE_END
	
COD_DIS_W:
	brcs	COD_DIS_W_1
;CODE_W_0:
	st	Z+,J
	st	Z+,I
;	st	Z+,B
;	st	Z+,C
	ret
COD_DIS_W_1:
	st	Z+,J
	st	Z+,J
;	st	Z+,B
;	st	Z+,C
	ret

CODE_BIPHASE:
	rjmp	CODE_END
