;Stack pointer must be initialized and interrupts controlled.

EEPROM_WRITE:	;Writes data from data space locations between Y and Z (inclusive)
		;to cosecutive EEPROM locations starting with location pointed at by
		;pointer stored in (EE_FIRST_EMPTY):(EE_FIRST_EMPTY+1) eeprom locations.
	rcall	EE_EMPTY_R
	ldi	A,low(EEPROMEND)
	ldi	B,high(EEPROMEND)
	
EEPROM_WRITE_LOOP:
	sbic	EECR,EEWE
	rjmp	EEPROM_WRITE_LOOP	;poll until eeprom ready
	
	cp	XL,A
	cpc	XH,B
	breq	EEPROM_WRITE_END
	
	out	EEARL,XL
	out	EEARH,XH	;EE address
	
	ld	C,Y+
	out	EEDR,C		;EE data
	
	sbi EECR,EEMWE		; Write logical one to EEMWE
	sbi EECR,EEWE		; Start eeprom write by setting EEWE

	adiw	XH:XL,1
	
	cp	ZL,YL		;Y points to last read SRAM +1
	cpc	ZH,YH		;Z points to data end
	brcs	EEPROM_WRITE_END	;Ok, all requested data is written to EE
	rjmp	EEPROM_WRITE_LOOP
	
EEPROM_WRITE_END:
	rcall	EE_EMPTY_W
	ret


EE_EMPTY_R:	;Reads and stores in register pair X pointer to first empty eeprom location.
EE_EMPTY_R_LOW:		;Read lower byte of pointer to first empty EEPROM address.
	sbic	EECR,EEWE
	rjmp	EE_EMPTY_R_LOW
	ldi	XL,low(EE_FIRST_EMPTY)
	ldi	XH,high(EE_FIRST_EMPTY)	;load pointer address to X
	out	EEARL,XL
	out	EEARH,XH
	sbi	EECR,EERE
	in	A,EEDR
	
EE_EMPTY_R_HIGH:	;Read higher byte of pointer to first empty EEPROM address.
	sbic	EECR,EEWE
	rjmp	EE_EMPTY_R_HIGH
	ldi	XL,low(EE_FIRST_EMPTY+1)
	ldi	XH,high(EE_FIRST_EMPTY+1)
	out	EEARL,XL
	out	EEARH,XH
	sbi	EECR,EERE
	in	B,EEDR
	movw	XH:XL,B:A
	ret


EE_EMPTY_W:
	movw	B:A,XH:XL
EE_EMPTY_W_LOW:
	sbic	EECR,EEWE
	rjmp	EE_EMPTY_W_LOW
	ldi	XL,low(EE_FIRST_EMPTY)
	ldi	XH,high(EE_FIRST_EMPTY)
	out	EEARL,XL
	out	EEARH,XH
	out	EEDR,A
	sbi	EECR,EEMWE
	sbi	EECR,EEWE
		
EE_EMPTY_W_HIGH:
	sbic	EECR,EEWE
	rjmp	EE_EMPTY_W_HIGH
	ldi	XL,low(EE_FIRST_EMPTY+1)
	ldi	XH,high(EE_FIRST_EMPTY+1)
	out	EEARL,XL
	out	EEARH,XH
	out	EEDR,B	
	sbi	EECR,EEMWE
	sbi	EECR,EEWE
	ret

EEPROM_RESTART:
	ldi	A,2
	ldi	B,0
EE_RESTART_LOW:
	sbic	EECR,EEWE
	rjmp	EE_EMPTY_W_LOW
	ldi	XL,low(EE_FIRST_EMPTY)
	ldi	XH,high(EE_FIRST_EMPTY)
	out	EEARL,XL
	out	EEARH,XH
	out	EEDR,A
	sbi	EECR,EEMWE
	sbi	EECR,EEWE
		
EE_RESTART_HIGH:
	sbic	EECR,EEWE
	rjmp	EE_EMPTY_W_HIGH
	ldi	XL,low(EE_FIRST_EMPTY+1)
	ldi	XH,high(EE_FIRST_EMPTY+1)
	out	EEARL,XL
	out	EEARH,XH
	out	EEDR,B	
	sbi	EECR,EEMWE
	sbi	EECR,EEWE
	ret
	
