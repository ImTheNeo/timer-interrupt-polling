
.include "m128def.inc"




.ORG 0x0000
.MACRO INITSTACK ; initialize stack
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16
.ENDMACRO
INITSTACK
call USART ; call usart subroutine
END:call welcome ; call welcome subroutine
rjmp END  ; jump and ask again

USART:	;initialize registers
		ldi r16,0x00; all bits are 0
		out UCSR0A,r16;
		ldi r16,0x18 ; just rxen and txen is 1
		out UCSR0B,r16;
		ldi r16,0x86 ; rw , ucszn1 and ucszn0 is 1
		sts UCSR0C,r16
		ldi r16,0x00; ; all bit are 0
		sts UBRR0H,r16
		ldi r16,0x33; baudrate is 51
		out UBRR0L,r16;
ret

SENDCHAR:
Loop_1:	sbis UCSR0A, UDRE0 ; wait until udre0 set
		rjmp Loop_1 
		out UDR0, R16  ; if set send the value to terminal
ret

SENDSTR:
		ldi XL,LOW(0x0200) ; starting adress is 0x200
		ldi XH,HIGH(0x0200) ; same
		ldi r18, '$' ; compare bit
Loop_2:		ld r16, X+ ; store x to r16 and increment x
		cp r16, r18 ; compare
		breq Loop_3 ; if $ is not entered continue
        call SENDCHAR ; if entered send char to terminal
		jmp Loop_2 ; jump until $ entered
Loop_3:		ret ; return

RECVCHAR: ; beginning of receive char subroite
Loop_4:	sbis UCSR0A,RXC0 ; wait until rxc0 set
		rjmp Loop_4 ;jump
		in r17, UDR0 ; put the char in terminal to r17
ret

RECVSTR:; beginning of receive str function
		ldi YL,LOW(0x0400) ; starting adress is 0x400
		ldi YH,HIGH(0x0400) ; same
		ldi r18,'$' ; compare character
Loop_5:	call RECVCHAR ; receive char from terminal
		cp r17,r18 ; check if last bit $
		breq Loop_6 ; if yes, end
		st Y+, r17 ; else store r17 into y pointer then inc y+ 
		jmp Loop_5 ; continue
Loop_6:	ldi r20,'\n' ; this is for next line
		st Y+,r20 ; store next line
		ldi r20,'\r' ; this is also for next line
		st Y+,r20 ; same
		st Y+,r18 ;add $ too
ret ;return

welcome: ; beginning of welcome subroutine
		ldi ZL, LOW(MSG1<<1) ; put MSG1 's adress to Z pointer
		ldi ZH, HIGH(MSG1<<1) ; same
		ldi XL,LOW(0x0200) ; put storing adress to x pointer 
		ldi XH,HIGH(0x0200) ; same
		ldi r18, '$' ; load compare character
Loop_7:		lpm r19, Z+ ; store the char at Z into r19 then inc Z
		st X+,r19 ; store the char r19 to X then inc X
		cp  r19,r18 ; compare r18 and r19
		breq Loop_8 ; if yes then break
		jmp Loop_7 ; else continue
Loop_8:		call SENDSTR ; call sendstr func
		call RECVSTR ; call recvstr func
		ldi ZL, LOW(MSG2<<1) ; put hello's adress to Z pointer
		ldi ZH, HIGH(MSG2<<1) ; same
		ldi XH, HIGH(0x200) ; put the name's adress into X pointer
		ldi XL, LOW(0x200); same
Loop_9:		lpm r19,Z+ ; Put the char at Z into r19 then inc Z
		st X+,r19 ; put the char at r19 into X then inc X
		cp  r19,r18 ; compare
		breq Loop_10 ;if r19 is $ then break
		jmp Loop_9 ;else continue
Loop_10:	call SENDSTR ; call send str func
		ldi XL,LOW(0x0200) ;name is at 0x200
		ldi XH,HIGH(0x0200);same
		ldi YL,LOW(0x0400);recieved string is at 0x400
		ldi YH,HIGH(0x0400);same
		
cont:	ld  r20, Y+ ; put the value to r20 then inc Y
		st X+,r20 ; load r20 into x then inc x
		cp  r20, r18 ;compare if r20 is $
		breq Loop_11 ; if yes end
		jmp cont ; else continue
Loop_11:	call SENDSTR		; send str to terminal	
		ret ; end

.ORG 0x500 ;starting adress
MSG1: .DB "What is your name ?",'\n','\r','$' ; first data
MSG2: .DB "Hello $" ; second data