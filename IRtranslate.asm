TRANSLATE:
	ldi	YL,low(DATA_REC_TYPE)
	ldi	YH,high(DATA_REC_TYPE)
	
	ldi	ZL,low(MAPPING_TABLE<<1)
	ldi	ZH,high(MAPPING_TABLE<<1)

	ldi	XL,low(MAPPING_TABLE_END<<1)
	ldi	XH,high(MAPPING_TABLE_END<<1)
	ldi	C,1	;current column
	ld	A,Y
	
TRANS_LOOP:	
	lpm	B,Z
	cp	A,B
	breq	TRANS_NEXT_COL
	brcs	TRANS_NONE_FOUND	;larger item
	adiw	ZH:ZL,MAPPING_TABLE_COLS
	cp	ZL,XL
	cpc	ZH,XH
	brcc	TRANS_NONE_FOUND	;end of table
	rjmp	TRANS_LOOP
TRANS_NEXT_COL:
	cpi	C,6
	breq	TRANS_FOUND
	inc	C
	adiw	ZH:ZL,1
	adiw	YH:YL,1
	ld	A,Y
	rjmp	TRANS_LOOP

TRANS_NONE_FOUND:
	ldi	XL,low(DATA_MAP_TYPE)
	ldi	XH,high(DATA_MAP_TYPE)
	ldi	A,TYPE_ERROR
	st	X+,A	;store type (error)
	clr	A
	st	X+,A	;store length (0)
	ret

TRANS_FOUND:
	adiw	ZH:ZL,1
	lpm	YL,Z+
	lpm	YH,Z
	lsl	YL
	rol	YH	;convert word address to byte address
	movw	ZH:ZL,YH:YL	;Z is the pointer to first code space location to be read
	
	ldi	YL,low(DATA_MAP_TYPE)
	ldi	YH,high(DATA_MAP_TYPE)
	ldi	XL,low(DATA_MAP_END-1)
	ldi	XH,high(DATA_MAP_END-1)
TRANS_FOUND_LOOP:
	lpm	A,Z+
	st	Y+,A
	cp	XL,YL
	cpc	XH,YH
	brcc	TRANS_FOUND_LOOP
	ret
