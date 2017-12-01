.nolist 
.include "m8def.inc"
.include "registers.asm"

;Piloty zdalnego sterowania zasadniczo nie są zestandaryzowane pomiędzy producentami sprzętu.
;Wysyłają one zmodulowane amplitudowo (z częstotliwością ok. 36 kHz) impulsy światła podczerwonego.
;Pozwala to na rozróżnienie ich w urządzeniu odbiorczym od szumów tła.
;Jednak na tym kończą się podobieństwa pomiędzy protokołami transmisji.
;Takie parametry jak częstotliwość taktowania tych sygnałów i sposób kodowania informacji są różne.

;Mam 2 piloty zdalnego sterowania.
;Pierwszy to pilot od wzmacniacza Cambridge Audio a drugi jest od odtwarzacza CD Technicsa.

;Pilot od Cambridge Audio może też sterować odtwarzaczami CD tej firmy.
;1 guzik wysyła naprzemiennie 2 komunikaty zrozumiałe dla wzmacniacza i dla odtwarzaczy, jest to komunikat ON/OFF.
;9 guzików pilota wysyła komunikaty skierowane do wzmacniacza (wybór wejść, ster. głośnością i wyciszanie).
;Pozostałe 26 guzików steruje odtwarzaczami.
;Protokół transmisji komunikatów do wzmacniacza i odtwarzaczy jest różny! Jest to więc pilot dwustandardowy.
;Guzik ON/OFF wysyła naprzemiennie komunikaty w dwóch standardach.
;Komunikaty do wzmacniacza są w ogólnoprzyjętym standardzie RC-5.
;Patrz: https://secure.wikimedia.org/wikipedia/en/wiki/RC-5 .
;Komunikaty do odtwarzaczy mają format podobny do formatu NEC, ale są szybciej taktowane.
;Patrz: http://ken.net/blog/LG_IR_Codes.pdf i http://www.sbprojects.com/knowledge/ir/nec.htm

;Pilot do odtwaracza CD Technicsa pracuje w standardzie podobnym na pierwszy rzut oka do standardu
;komunikatów pilota Cambridge Audio skierowanych do odtwarzaczy tej firmy.
;Jednak częstotliwość taktowania obu tych pilotów jest różna.

;Z tego powodu dekodowanie konkretnych numerów urządzeń i rozkazów jest trudne.

;Zmierzone długości bitów startowych to:
;RC5			CAudio cdpl	Technics
;0.917 lub 1.834 ms	4.8 ms		3.5 ms
;4.8 ms i 3.5 ms to dość blisko siebie położone wartości.
;Znajdźmy największą procentową ich odchyłkę która nie sprawi że zakresy nałożą się:
;3.5*(1+x)<4.8/(1+x) -> (1+x)^2<4.8/3.5 -> (1+x)^2<1.37 -> x<17%
;Wygląda więc na to że 10% margines błędu będzie wystarczający i nie za duży.

;Dalsze informacje o kodowaniu są w pliku IRdatabase.asm

;Procek ma ustawioną częstotliwość 8MHz
;Czyli MCU clock = 1/8 us
.list

.DSEG	;SRAM ranges. Sum of all should be less than 1k minus maximum stack size!
;Data space address range of internal SRAM starts from 0x60
	DATA_START:
	;Received data:
	DATA_REC_TYPE:	.BYTE	1	;The type of startbit detected
	DATA_REC_BITS:	.BYTE	1	;Number of written bits
	DATA_REC_SEQ:	.BYTE	6	;The decoded device and command number.
	DATA_REC_END:
	
	;Mapped data:
	DATA_MAP_TYPE:	.BYTE	1
	DATA_MAP_BITS:	.BYTE	1
	DATA_MAP_SEQ:	.BYTE	6	;The type, bit count, device and command number of command to be transmitted.
	DATA_MAP_END:

	;Captured raw data (pulse and pause lengths)
	DATA_RAW:	.BYTE	150	;Raw data (lengths of impules) of captured sequence
	DATA_RAW_END:	.BYTE	2	;Pointer to the last written addres in DATA_RAW
	;It serves two purposes: its address will be limit to writing precedures
	;			 its content will be limit to reading procedutes

	;Encoded raw data to be transmitted
	DATA_OUT:	.BYTE	150
	DATA_OUT_END:	.BYTE	2
	
;.ESEG	;EEPROM ranges. Sum of all should be less than 512
;	EE_FIRST_EMPTY:	.DW	0x0002	;Pointer to the first empty location in EEPROM
;	EE_NULL:	.DW	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

.CSEG	;Code

.ORG	0x0000
	rjmp	MAIN
.ORG	INT0addr
	ret	;INT0's only purpose is to wake up the MCU
.ORG	OVF0addr
	reti	;OVF0's only purpose is to wake up the MCU
	
MAIN:
	ldi	A,low(RAMEND)
	out	SPL,A
	ldi	A,high(RAMEND)
	out	SPH,A		;Stack pointer initialization

	rcall	INIT

	;rcall	SRAM_ERASE	;Makes debugging easier

	rcall	RECEIVE

	rcall	DECODE

	ldi	A,1
	lds	B,DATA_REC_TYPE
	cp	A,B
	brne	NOT_KEY_HOLD

	ldi	A,1
	lds	B,DATA_REC_BITS
	cp	A,B
	brne	NOT_KEY_HOLD

	ldi	A,0
	lds	B,DATA_REC_SEQ
	cp	A,B
	brne	NOT_KEY_HOLD
	
	rcall	TIMER_WAIT_18
	rjmp	KEY_HOLD
	
NOT_KEY_HOLD:
	rcall	TRANSLATE

	lds	A,DATA_MAP_TYPE
	cpi	A,TYPE_ERROR
	breq	MAIN

	rcall	CODE

	rcall	TIMER_WAIT_76 ;Wait until the first key hold sequence ends + some additional ms

KEY_HOLD:	
	rcall	TRANSMIT

	;rcall	EEPROM_RESTART

	;;Set up environment for EEPROM_WRITE:
	;ldi	YL,low(DATA_START)
	;ldi	YH,high(DATA_START)	;Y points to data start

	;lds	ZL,DATA_OUT_END
	;lds	ZH,DATA_OUT_END+1	;Z points to data end
	
	;rcall	EEPROM_WRITE

	rjmp	MAIN 
	
;FOREVER:
	;;cbi	LED8POUT,LED8PN 
	;rjmp	FOREVER
	
WAITX:			;delays 4*[XH:XL] clocks (+ 6 calling and returning)
	sbiw	XL,1	;2 clocks	
	brne	WAITX	;2 clocks
	ret

;----PROGRAM SECTIONS----;
.include "IRreceive.asm"	;Pin state changes (demodulated by IR sensor) -->  DATA_RAW
.include "IRdecode.asm"		;DATA_RAW  -->  DATA_REC
.include "IRtranslate.asm"	;DATA_REC  -->  DATA_MAP
.include "IRcode.asm"		;DATA_MAP  -->  DATA_OUT
.include "IRtransmit.asm"	;DATA_OUT  -->  Pin state changes (and 36kHz modulation)

;-------FUNCTIONS-------;
;.include "errors.asm"
;.include "eeprom_write.asm"

;--------DATABASE-------;
.include "IRdatabase.asm"

INIT:

;; LED[1-8] debugging leds
;.equ	LED1POUT= PORTD
;.equ	LED1PDD = DDRD
;.equ	LED1PN	= 0

;.equ	LED2POUT= PORTD
;.equ	LED2PDD = DDRD
;.equ	LED2PN	= 1

;;Pins 2 and 3 of port D are External Interrupt Pins

;.equ	LED3POUT= PORTD
;.equ	LED3PDD = DDRD
;.equ	LED3PN	= 4

;.equ	LED4POUT= PORTD
;.equ	LED4PDD = DDRD
;.equ	LED4PN	= 5

;.equ	LED5POUT= PORTD
;.equ	LED5PDD = DDRD
;.equ	LED5PN	= 6

;.equ	LED6POUT= PORTD
;.equ	LED6PDD = DDRD
;.equ	LED6PN	= 7

;.equ	LED7POUT= PORTC
;.equ	LED7PDD = DDRC
;.equ	LED7PN	= 0

;.equ	LED8POUT= PORTC
;.equ	LED8PDD = DDRC
;.equ	LED8PN	= 1

; IRSEN IR sensor input
.equ	IRSENPOUT= PORTD
.equ	IRSENPDD = DDRD
.equ	IRSENPIN = PIND
.equ	IRSENPN  = 2

; IR emitting diode output (through driving transistor)
.equ	IRAMPPOUT= PORTB
.equ	IRAMPPDD = DDRB
.equ	IRAMPPN  = 7

;; Piezo buzzer output
;.equ	PIEZOPOUT= PORTB
;.equ	PIEZOPDD = DDRB
;.equ	PIEZOPN  = 6

	;Set all ports as inputs and activate pull-up's
	clr	A
	ser	B
	out	DDRB,A
	out	PORTB,B
	out	DDRC,A
	out	PORTC,B
	out	DDRD,A
	out	PORTD,B
	
	;;Set led pins as outputs and set them high (leds are active low)
	;;sbi	LED1POUT,LED1PN
	;sbi	LED1PDD,LED1PN
	;;sbi	LED2POUT,LED2PN
	;sbi	LED2PDD,LED2PN
	;;sbi	LED3POUT,LED3PN
	;sbi	LED3PDD,LED3PN
	;;sbi	LED4POUT,LED4PN
	;sbi	LED4PDD,LED4PN
	;;sbi	LED5POUT,LED5PN
	;sbi	LED5PDD,LED5PN
	;;sbi	LED6POUT,LED6PN
	;sbi	LED6PDD,LED6PN
	;;sbi	LED7POUT,LED7PN
	;sbi	LED7PDD,LED7PN
	;;sbi	LED8POUT,LED8PN
	;sbi	LED8PDD,LED8PN

	;;Set piezo pin as output and set it low
	;cbi	PIEZOPOUT,PIEZOPN
	;sbi	PIEZOPDD,PIEZOPN

	;Set IR led amplifier pin as output and set it high (active low)
	;sbi	IRAMPPOUT,IRAMPPN
	sbi	IRAMPPDD,IRAMPPN
	
	ldi	A,low(DATA_RAW-1)
	ldi	B,high(DATA_RAW-1)
	sts	DATA_RAW_END,A
	sts	DATA_RAW_END+1,B	;Initialize raw data end pointer

	ldi	A,(1<<ACD)	;Shut down the analog comparator (saves energy during sleep modes)
	out	ACSR,A		; Hmm.. not really...
	
	ret	

TIMER_WAIT_76:	;sleeps 76 ms

	ldi	A,(1<<PSR10)
	out	SFIOR,A				;reset the prescaler

	ldi	A,(1<<CS02)|(0<<CS01)|(1<<CS00)
	out	TCCR0,A				;set prescaler to 1024 and start counting
	
	ldi	A,(1<<TOIE0)
	out	TIMSK,A				;enable TimerOverflow interrupt
	
	ldi	A,(1<<SE)
	out	MCUCR,A				;enable sleep and set Idle mode
	
	sei
	
	clr	A
	out	TCNT0,A		;reset the counter
	sleep			;Will sleep 256*1024 clocks (~ 33 ms)

	clr	A
	out	TCNT0,A		;reset the counter
	sleep			;Will sleep 256*1024 clocks (~ 33 ms)
	
	ldi	A,177		;256-79=177
	out	TCNT0,A
	sleep			;Will sleep 79*1024 clocks (~ 10 ms)

	cli

	clr	A
	out	TIMSK,A		;disable the TimerOverflow interrupt
	out	TCCR0,A		;stop the timer
	out	MCUCR,A		;disable sleep
	
	ret

TIMER_WAIT_18:	;sleeps 18 ms

	ldi	A,(1<<PSR10)
	out	SFIOR,A				;reset the prescaler

	ldi	A,(1<<CS02)|(0<<CS01)|(1<<CS00)
	out	TCCR0,A				;set prescaler to 1024 and start counting
	
	ldi	A,(1<<TOIE0)
	out	TIMSK,A				;enable TimerOverflow interrupt
	
	ldi	A,(1<<SE)
	out	MCUCR,A				;enable sleep and set Idle mode
	
	sei
	
	ldi	A,109		;256-109=146
	out	TCNT0,A
	sleep			;Will sleep 146*1024 clocks (~ 18 ms)

	cli

	clr	A
	out	TIMSK,A		;disable the TimerOverflow interrupt
	out	TCCR0,A		;stop the timer
	out	MCUCR,A		;disable sleep
	
	ret

;SRAM_ERASE:
	;ldi	XL,low(DATA_START)
	;ldi	XH,high(DATA_START)
	;clr	A
	;ldi	B,low(DATA_RAW_END)
	;ldi	C,high(DATA_RAW_END)
;SRAM_ERASE_LOOP:
	;st	X+,A
	;cp	XL,B
	;cpc	XH,C
	;brmi	SRAM_ERASE_LOOP
;SRAM_ERASE_END:
	;ret
