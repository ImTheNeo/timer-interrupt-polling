.include "m128def.inc"

.org 0x0000
rjmp main

.org 0x0018
rjmp IsrTim





main:
ldi r16,high(RAMEND)
out SPH,r16
ldi r16,low(RAMEND)
out SPL,r16
call USART
call INTEN ; enable interrupt
call timer ; call timer
END:call WELCOME


rjmp END




USART:	
		ldi r16,0x00;
		out UCSR0A,r16;
		ldi r16,0x18
		out UCSR0B,r16;
		ldi r16,0x86
		sts UCSR0C,r16
		ldi r16,0x00;
		sts UBRR0H,r16
		ldi r16,0x33;
		out UBRR0L,r16;
ret

SENDCHAR:
Loop_1:		sbis UCSR0A, UDRE0 
		rjmp Loop_1 
		out UDR0, R16 
ret

SENDSTR:
		ldi XL,LOW(0x0200)
		ldi XH,HIGH(0x0200)
		ldi r18, '$'
Loop_2:		ld r16, X+
		cp r16, r18
		breq Loop_3
        call SENDCHAR
		jmp Loop_2
Loop_3:		ret

RECVCHAR:
Loop_4:		sbis UCSR0A,RXC0
		rjmp Loop_4
		in r17, UDR0
ret

RECVSTR:
		ldi YL,LOW(0x0400)
		ldi YH,HIGH(0x0400)
		ldi r18,'$'
Loop_5:		call RECVCHAR
		cp r17,r18
		breq Loop_6
		st Y+, r17
		jmp Loop_5
Loop_6:		ldi r20,'\n'
		st Y+,r20
		ldi r20,'\r'
		st Y+,r20
		st Y+,r18
ret

WELCOME:
		ldi ZL, LOW(MSG1<<1)
		ldi ZH, HIGH(MSG1<<1)
		ldi XL,LOW(0x0200)
		ldi XH,HIGH(0x0200)
		ldi r18, '$'
Loop_7:		lpm r19, Z+
		st X+,r19
		cp  r19,r18
		breq Loop_8
		jmp Loop_7
Loop_8:		call SENDSTR
		call RECVSTR
		ldi ZL, LOW(MSG2<<1)
		ldi ZH, HIGH(MSG2<<1)
		ldi XH, HIGH(0x200)
		ldi XL, LOW(0x200)
Loop_9:		lpm r19,Z+
		st X+,r19
		cp  r19,r18
		breq Loop_10
		jmp Loop_9
Loop_10:	call SENDSTR
		ldi XL,LOW(0x0200)
		ldi XH,HIGH(0x0200)
		ldi YL,LOW(0x0400)
		ldi YH,HIGH(0x0400)
		
cont:	ld  r20, Y+
		st X+,r20
		cp  r20, r18
		breq Loop_11
		jmp cont
Loop_11:	call SENDSTR			
		ret

.ORG 0x500
MSG1: .DB "What is your name ?",'\n','\r','$'
MSG2: .DB "Hello $"

Timer:
LDI R16,0xFF
out ddra,R16
out ddrb,r16
LDI R20,0x0
OUT TCCR1A,R20 ;timer starts from 0;
OUT TCNT1H,R20	;timer starts from 0;
OUT TCNT1L,R20 ;timer starts from 0;

LDI R20,0x1E 
OUT OCR1AH,R20 
LDI R20,0x84;prescaler is clk/1024 1/(8*10^6/(1024))*x=1 s
OUT OCR1AL,R20 ;loaded will cause interrupt to occur when counter reaches 1e84 since we are using compare match and using a prescaler to slowdown the counter

LDI R20,0x0D
OUT TCCR1B,R20

ldi R21,0
ldi R22,0
LDI R20,(1<<OCIE1A);enable interrupt for compare flag for timre1 A
OUT TIMSK,R20
SEI
ret

IsrTim:;we are holding our values for ports here on r21,r22 and incrementing r21 if when we increment 21 it becomes 0 that means there is an overflow on register and we should increment r22 which shows the upper 8 bits
clc
Inc R21
brne still
inc R22
still:
out portA,R21
out portB,R22
reti

INTEN:
SEI
ret