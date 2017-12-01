TRANSMIT:
	ldi	ZL,low(DATA_OUT)
	ldi	ZH,high(DATA_OUT)

	lds	I,DATA_OUT_END
	lds	J,DATA_OUT_END+1

TRANSMIT_LOOP:	
	cp	ZL,I
	cpc	ZH,J
	brcc	TRANS_END

	ld	A,Z+
	tst	A
	breq	TRANS_END
	subi	A,7
	rcall	TRANS_LIGHT
	
	
	ld	A,Z+
	tst	A
	breq	TRANS_END
	rcall	TRANS_DARK

	rjmp	TRANSMIT_LOOP
	
TRANS_END:
	sbi	IRAMPPOUT,IRAMPPN	;just to be sure
	ret

TRANS_DARK:	;(calling +3)
	cbi	IRAMPPOUT,IRAMPPN	;+2	just to be sure
	ldi	XL,low(POLL_INTRV)	;+1
	ldi	XH,high(POLL_INTRV)	;+1
	rcall	WAITX	;Wait 4*X 	 +6
	dec	A			;+1
	;nop				;+1	\ 
	nop				;+1	 } To make this loop equally long as IR_ON/OFF in IRreceive.
	nop				;+1	/	
	brne	TRANS_DARK		;+2(+1)
	ret				;(+4)

TRANS_LIGHT:
;We want to switch on and off the IR LED at 36 kHz. Period of this frequency is 222 clock cycles long (@8MHz)
;Standard recommends 25% to 33% duty cycle. We will use 25%. 25% of 222 is 56 and 75% is 166.
.equ LIGHT_INTRV=18 ;56/3
.equ DARK_INTRV=53; 166/3
;and POLL_INTRV is set 37 in IRreceive.asm, it is almost exactly 1/6 of 222 (0.1% error)

	cbi	IRAMPPOUT,IRAMPPN	;+2
	ldi	B,LIGHT_INTRV		;+1
TRANS_WAIT_1:				;3*B
	dec	B			;+1
	brne	TRANS_WAIT_1		;+2
	
	sbi	IRAMPPOUT,IRAMPPN	;+2
	ldi	B,DARK_INTRV		;+1
TRANS_WAIT_2:				;3*B
	dec	B			;+1
	brne	TRANS_WAIT_2		;+2

	dec	A			;+1

	brne	TRANS_LIGHT		;+2(+1)
	ret
