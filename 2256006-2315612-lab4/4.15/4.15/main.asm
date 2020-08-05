.include "m128def.inc"
RJMP MAIN
.ORG 0x24
RJMP IsrRec
.org 0x26
RJMP IsrTr


MAIN:ldi r16,high(RAMEND)
out SPH,r16
ldi r16,low(RAMEND)
out SPL,r16
LDI R16,(1<<UCSZ01)|(1<<UCSZ00); 8 bit data, no parity, 1 stop bit
sts UCSR0C, R16
LDI R16,0x33 ; 9600 baud rate
OUT UBRR0L, R16 ; XTAL = 8 MHz
LDI R16, 0xFF
OUT DDRB, R16
out DDRA, r16 ; set PORTB as output
SEI ; enable interrupts globally
ldi ZL, LOW(MSG1<<1)
ldi ZH, HIGH(MSG1<<1)
ldi ZL, LOW(MSG1<<1);
ldi ZH, HIGH(MSG1<<1);
ldi YL, LOW(0x200);
ldi YH, HIGH(0x200);
call welcome
WAIT: RJMP WAIT ; stay here until a byte arrives

welcome:
		ldi ZL, LOW(MSG1<<1)
		ldi ZH, HIGH(MSG1<<1)
		ldi XL,LOW(0x0200)
		ldi XH,HIGH(0x0200)
		ldi r18, '$'
L7:		lpm r19, Z+
		st X+,r19
		cp  r19,r18
		breq L8
		jmp L7
L8:		ldi XL,LOW(0x200)
		ldi XH,HIGH(0x200)
		ldi R16,(1<<TXEN0)|(1<<UDRIE0);enabling interrupt to write to memory
		out ucsr0b,r16;
		ldi ZL,LOW(MSG2<<1)
		ldi ZH,HIGH(MSG2<<1)
		ldi XL,LOW(0x300)
		ldi XH,HIGH(0x300)
L9:		lpm r19,Z+
		cpi r19,'$'
		breq print
		st X+,r19
		jmp L9
print:	ldi R16,(1<<RXEN0)|(1<<RXCIE0);
		ldi XL,LOW(0x300)
		ldi XH,HIGH(0x300)
		ldi R16,(1<<TXEN0)|(1<<UDRIE0);enable interrupt to sent data
ret


IsrRec:;receive char
in  r18, UDR0 ; copy UDR to R17
	st X+,r18
	cpi r18,'$'
	brne keep_going
	ldi r16,0
	out UCSR0B,r16;disable interrupt
keep_going:reti


IsrTr:;send to terminal
ld r17,X+
out portb,r17
out UDR0,r17
cpi r17,'$'
brne keep_trans
ldi r16,0
out ucsr0b,r16;disable interrupt
keep_trans:RETI



.ORG 0x500
MSG1: .DB "What is your name ?",'\n','\r','$'
MSG2: .DB "Hello $"

;LDI R16,(1<<RXEN0)|(1<<RXCIE0); enable receiver and RXC0 interrupt
;ldi XL,LOW(0x400)
;ldi XH,HIGH(0x400)
;OUT UCSR0B, R16