; Hardware: 	-LEDs on PORTD[0-7] (active low)
;		-Piezo on PORTB,6 (as output)

ERROR_LOOP:
	sbi	PIEZOPOUT,PIEZOPN
	ldi	XL,0xff
	ldi	XH,0xff
	rcall	WAITX
	cbi	PIEZOPOUT,PIEZOPN
	ldi	XL,0xff
	ldi	XH,0xff
	rcall	WAITX
	rjmp ERROR_LOOP
ERROR0:
	
	rjmp ERROR_LOOP
ERROR1:
	cbi	LED4POUT,LED4PN
	rjmp ERROR_LOOP
ERROR2:
	cbi	LED5POUT,LED5PN
	rjmp ERROR_LOOP
ERROR3:
	cbi	LED4POUT,LED4PN
	cbi	LED5POUT,LED5PN
	rjmp ERROR_LOOP
ERROR4:
	cbi	LED6POUT,LED6PN
	rjmp ERROR_LOOP
ERROR5:
	cbi	LED4POUT,LED4PN
	cbi	LED6POUT,LED6PN
	rjmp ERROR_LOOP
ERROR6:
	cbi	LED5POUT,LED5PN
	cbi	LED6POUT,LED6PN
	rjmp ERROR_LOOP
ERROR7:
	cbi	LED4POUT,LED4PN
	cbi	LED5POUT,LED5PN
	cbi	LED6POUT,LED6PN
	rjmp ERROR_LOOP
ERROR8:
	cbi	LED7POUT,LED7PN
	rjmp ERROR_LOOP