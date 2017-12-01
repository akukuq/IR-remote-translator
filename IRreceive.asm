;Real polling interval -> RPI
;Should be as short as possible (accuracy), but long enough not to overflow 8bit integer in 4.8 ms
;which is the longest pulse we expect. RPI>(1/255)*4.8ms -> RPI > 18.82 us
.equ	POLL_INTRV=37	;RPI = (POLL_INTRV * 4 + 16) * 1/8 us
;POLL_INTRV=34 is a minimum not to overflow in 4.8 ms
;With 10% margin POLL_INTRV=37 should be ok.
;30 -> 17us	37 -> 20.5us	40 -> 22us	56 -> 29.5us

RECEIVE:
	ldi	YL,low(DATA_RAW)	
	ldi	YH,high(DATA_RAW)
	ldi	ZL,low(DATA_RAW_END)
	ldi	ZH,high(DATA_RAW_END)
	
	ldi	C,0
	ldi	B,0		;Initialize pulse length counters

	
	ldi	A,(1<<SE)|(1<<SM0)	;enable sleep and set ADC noise reduction mode
	out	MCUCR,A
	
	ldi	A,(1<<INT0)
	out	GICR,A		;enable Ext Int 0 (low level activates)

WAIT_FOR_INT:
	sei			;enable interrupts
	sleep			;and enter sleep
	;cli	;We don't have to do this because INT0 vector is "ret", not "reti"
	clr	A
	out	GICR,A		;disable Ext Int 0
	out	MCUCR,A		;disable sleep

	;sbic	IRSENPIN,IRSENPN
	;rjmp	POLL		;Poll for signal start

	;------------REAL-TIME SECTION START-------------;
	;numbers on the end of each line are processor cycles needed to execute given command 

IR_ON:
	ldi	XL,low(POLL_INTRV)	;+1
	ldi	XH,high(POLL_INTRV)	;+1
	rcall	WAITX	;Wait 4*X 	 +6
	sbic	IRSENPIN,IRSENPN	;+2(+1)
	rjmp	STORE_IR_ON		;skipped(+2)
	inc	B			;+1
	breq	WAIT_FOR_INT		;+1	Corrupted signal! (light pulse too long)
	rjmp	IR_ON			;+2
	;Each loop of IR_ON is (X*4 +14) cycles long
STORE_IR_ON:
	st	Y+,B			;+1
	clr	B			;+1
	cp	ZL,YL			;+1
	cpc	ZH,YH			;+1
	brcs	RECEIVE			;+1
	;Last loop of IR_ON is (X*4 +16) cycles long
IR_OFF:	
	ldi	XL,low(POLL_INTRV)	;+1
	ldi	XH,high(POLL_INTRV)	;+1
	rcall	WAITX	;Wait 4*X	 +6
	sbis	IRSENPIN,IRSENPN	;+2(+1)
	rjmp	STORE_IR_OFF		;skipped(+2)
	inc	C			;+1
	breq	EOT			;+1	OK, end of transmission (long pause)
	rjmp	IR_OFF			;+2
	;Each loop of IR_OFF is (X*4 +14) cycles long
STORE_IR_OFF:
	st	Y+,C			;+1
	clr	C			;+1	
	rjmp	IR_ON			;+2
	;Last loop of IR_OFF is (X*4 +15) cycles long

	;------------REAL-TIME SECTION END-------------;

EOT:
	st	Y,C		;overflowed pause on the end (is zero)
	;This time without post incrementing the Y pointer!
	
	sts	DATA_RAW_END,YL
	sts	DATA_RAW_END+1,YH	;finally update the DATA_RAW_END pointer

	ret
	
