DECODE:
	lds	ZL,DATA_RAW_END
	lds	ZH,DATA_RAW_END+1	;Z is the pointer to last address to read
	ldi	XL,low(DATA_RAW)	
	ldi	XH,high(DATA_RAW)	;X is the pointer to first address to read
	ldi	YL,low(DATA_REC_SEQ)
	ldi	YH,high(DATA_REC_SEQ)	;Y is the pointer to first address to write
	ld	A,X+	;We will always load data in this way to ensure
	ld	B,X+	;that A is the length of the pulse and B is the length of the pause
	clr	C	;current bit
	clr	D	;current byte
	clr	BLO	;bit number
	st	Y,D	;clear first location, next locations will be cleared on-the-fly.
	
ST_BIT:		;Let's decode startbit
	cpi	A,CACD_STARTBIT_MIN
	brcc	ST_BIT_CACD
	cpi	A,TECH_STARTBIT_MIN
	brcc	ST_BIT_TECH
	cpi	A,RC5_LONG_MIN		;|
	brcc	ST_BIT_RC5_HI_FIELD	;|
	cpi	A,RC5_SHORT_MIN		;|--length of the startbit depends on the field bit.
	brcc	ST_BIT_RC5_LO_FIELD	;|
	rcall	DECODE_ERR_1
ST_BIT_CACD:
	cpi	A,CACD_STARTBIT_MAX
	brcs	ST_PAUSE_CACD
	rcall	DECODE_ERR_1
ST_BIT_TECH:
	cpi	A,TECH_STARTBIT_MAX
	brcs	ST_PAUSE_TECH
	rcall	DECODE_ERR_1	
ST_BIT_RC5_HI_FIELD:
	cpi	A,RC5_LONG_MAX
	brcs	DECODE_RC5
	rcall	DECODE_ERR_1	
ST_BIT_RC5_LO_FIELD:
	cpi	A,RC5_SHORT_MAX
	brcs	DECODE_RC5
	rcall	DECODE_ERR_1	
	;At this point we know that startbit is ok.
ST_PAUSE_CACD:
	cpi	B,CACD_PAUSE_MAX
	brcc	DECODE_ERR_1
	cpi	B,CACD_PAUSE_MIN
	brcs	DECODE_ERR_1
	rjmp	DECODE_CACD
ST_PAUSE_TECH:
	cpi	B,TECH_PAUSE_MAX
	brcc	DECODE_ERR_1
	cpi	B,TECH_PAUSE_MIN
	brcs	DECODE_ERR_1
	rjmp	DECODE_TECH
;ST_PAUSE_RC5:	;pause after startbit can be long (field bit = 1) or short (field bit = 0)!!!
	;At this point we know that pause after startbit is also ok.
	
DECODE_CACD:
	;cbi	LED1POUT,LED1PN
	ldi	A,TYPE_CACD
	sts	DATA_REC_TYPE,A		;store the type of startbit
	ldi	G,CACD_LONG_MIN
	ldi	H,CACD_LONG_MAX
	ldi	I,CACD_SHORT_MIN
	ldi	J,CACD_SHORT_MAX	;set decoding ranges
	rjmp	DECODE_DISTANCE	
DECODE_TECH:
	;cbi	LED3POUT,LED2PN
	ldi	A,TYPE_TECH
	sts	DATA_REC_TYPE,A	;store the type of startbit
	ldi	G,TECH_LONG_MIN
	ldi	H,TECH_LONG_MAX
	ldi	I,TECH_SHORT_MIN
	ldi	J,TECH_SHORT_MAX	;set decoding ranges
	rjmp	DECODE_DISTANCE
	ret
DECODE_RC5:
	;cbi	LED3POUT,LED3PN
	ldi	A,TYPE_RC5
	sts	DATA_REC_TYPE,A	;store the type of startbit
	ldi	G,RC5_LONG_MIN
	ldi	H,RC5_LONG_MAX
	ldi	I,RC5_SHORT_MIN
	ldi	J,RC5_SHORT_MAX	;set decoding ranges
	sbiw	XH:XL,2		;in biphase code we need to know the length of the start bit and pause after it.
	clr	BLU		;register BLO will count how many phase inversions there were so far
	set
	rcall	DEC_W		;write first bit as 1 (inherent attribute of biphase code)
	rjmp	DECODE_BIPHASE

DECODE_ERR_1:
	ldi	A,TYPE_ERROR
	sts	DATA_REC_TYPE,A
	ret
	
DECODE_DISTANCE:
	cp	XL,ZL
	cpc	XH,ZH
	brcc	DECODE_ERR_2	;Eeeek! (Zero at EOT was missing?)
	ld	A,X+
	ld	B,X+
	cpi	B,0
	breq	DECODE_END	;Ok, thats the end bit. EOT
	cp	A,I
	brcs	DECODE_ERR_2
	; pulse is long enough
	cp	A,J
	brcc	DECODE_ERR_2
	; pulse is ok
	cp	B,G
	brcc	DEC_DIST_LONG	; pause is longer than LONG_MIN
	cp	B,I
	brcc	DEC_DIST_SHORT	; pause is longer than SHORT_MIN
	rjmp	DECODE_ERR_2	; pause is too short!
DEC_DIST_LONG:
	cp	B,H
	brcc	DECODE_ERR_2	; pause is longer than LONG_MAX!
	clt
	rcall	DEC_W
	rjmp	DECODE_DISTANCE
DEC_DIST_SHORT:
	cp	B,J
	brcc	DECODE_ERR_2	;pause is longer than SHORT_MAX!
	set
	rcall	DEC_W
	rjmp	DECODE_DISTANCE
	ret
	
DECODE_END:
	sts	DATA_REC_BITS,BLO
	ret

DECODE_ERR_2:
	ldi	A,TYPE_ERROR
	sts	DATA_REC_TYPE,A
	ret

DECODE_BIPHASE:
	cp	XL,ZL
	cpc	XH,ZH
	brcc	DECODE_END	;Eeeek! (Zero at EOT was missing?)
	
	ld	A,X+
	cp	A,G
	brcc	DEC_BIPH_LONG
	cp	A,I
	brcc	DEC_BIPH_SHORT
	
	cpi	A,0
	breq	DECODE_END	; Ok, EOT.
	
	rjmp	DECODE_ERR_3	; whatever it is, is shorter then SHORT_MIN!
	
DEC_BIPH_LONG:
	cp	A,H
	brcc	DECODE_ERR_3	; whatever it is, is longer than LONG_MAX!
	inc	BLU
	rjmp	DEC_BIPH_WRITE
DEC_BIPH_SHORT:
	cp	A,J
	brcc	DECODE_ERR_3	; whatever it is, is longer than SHORT_MAX!
	
	ld	A,X+
	cp	A,J
	brcc	DECODE_ERR_3	; whatever it is, is longer than SHORT_MAX!
	;biphase line code doesn't permit long signal in this place.
	cpi	A,0
	breq	DECODE_END	;Ok, that's the end bit. EOT
	cp	A,I
	brcs	DECODE_ERR_3	;  whatever it is, is shorter then SHORT_MIN!
	rjmp	DEC_BIPH_WRITE
DEC_BIPH_WRITE:
	set
	sbrc	BLU,0
	clt
	rcall	DEC_W
	rjmp	DECODE_BIPHASE
	
DECODE_ERR_3:
	ldi	A,TYPE_ERROR
	sts	DATA_REC_TYPE,A
	ret

;-----------Writes T flag to next bit----------	
DEC_W:
	inc	BLO	;bit control
	sbrc	C,3
	rcall	DEC_NEXT_BYTE
	ld	D,Y
	clr	BLA
	sec	;set carry (rol will place it in LSB of BLA)
	mov	BLE,C
DEC_W_LOOP:
	rol	BLA
	dec	BLE	;luckily dec doesn't affect carry flag
	brpl	DEC_W_LOOP	;loop until F >= 0

	brts	DEC_W_1
	com	BLA
	and	D,BLA
	rjmp	DEC_W_END
DEC_W_1:
	or	D,BLA
DEC_W_END:
	st	Y,D
	inc	C
	ret

DEC_NEXT_BYTE:
	andi	C,0b00000111
	adiw	YH:YL,1
	clr	D
	st	Y,D	;clear the next byte
	ret
