write_cmd EQU 0FF2CH
write_data EQU 0FF2DH
read_status EQU	0FF2EH
read_data EQU 0FF2CH

init EQU 038H					
clear EQU 001H					
on	EQU 00EH 					

TIME EQU 50 					
LOAD EQU (65536 - TIME*1000) 	

SEC EQU 020H
MIN EQU 028H
HOUR EQU 036H

LICZNIK EQU 042H

SEG_CHANGE EQU 050H

ORG 0	
	LCALL	lcd_inicjalizacja
	LCALL 	INICJUJ_TIMER
	CLR	SEG_CHANGE

	SJMP	loop

ORG 0BH 						

    	MOV TH0, #HIGH(LOAD) 		
   	MOV TL0, #LOW(LOAD) 		

	PUSH PSW
	PUSH ACC

	DEC LICZNIK
	DJNZ LICZNIK, int_exit
	MOV LICZNIK, #20 

    	CPL P1.0 					

	SETB SEG_CHANGE

	INC SEC
	MOV A, SEC
	CJNE A, #60, int_exit
	MOV SEC, #0

	INC MIN
	MOV A, MIN
	CJNE A, #60, int_exit
	MOV MIN, #0

	INC HOUR
	MOV A, HOUR
	CJNE A, #24, int_exit
	MOV HOUR, #0

int_exit:
	POP ACC
	POP PSW
    RETI 

loop:
	LCALL time_display
	JNB SEG_CHANGE,  loop
	CLR SEG_CHANGE
	SJMP loop

work:
	SJMP	loop
				
;------------------------------------------------------------------------------------------------------------------------------------
; Zapis komendy		A - kod komendy
;------------------------------------------------------------------------------------------------------------------------------------
lcd_write_cmd:
	PUSH ACC
	MOV DPTR, #read_status		

petla_zajetosci_cmd:
	MOVX A, @DPTR					
	JB ACC.7, petla_zajetosci_cmd 
	
	MOV DPTR, #write_cmd
	POP ACC
	MOVX @DPTR, A

	RET
;------------------------------------------------------------------------------------------------------------------------------------
; Inicjalizacja wyswietlacza
;------------------------------------------------------------------------------------------------------------------------------------
lcd_inicjalizacja:
	MOV A, #init				  		
	CALL lcd_write_cmd			  		
	MOV A, #clear			   	  		
	CALL lcd_write_cmd			  		
	MOV A, #on				   	  		
	CALL lcd_write_cmd			  		
	RET

;------------------------------------------------------------------------------------------------------------------------------------
; Wyswietlanie danych		A - kod wyswietlania danych w lcd 
;------------------------------------------------------------------------------------------------------------------------------------
lcd_write_data:
	PUSH ACC
	MOV DPTR, #read_status				

 petla_zajetosci_danych:
	MOVX A, @DPTR						
	JB ACC.7, petla_zajetosci_danych    

	MOV DPTR, #write_data
	POP ACC
	MOVX @DPTR, A		  				

	RET

;------------------------------------------------------------------------------------------------------------------------------------
; Wypisywanie liczby zapisanej na dwoch pozycjach 
;------------------------------------------------------------------------------------------------------------------------------------
lcd_wyswietl_liczbe:
	MOV B, #10
	DIV AB
	ADD A, #'0'
	CALL lcd_write_data
	MOV A, B
	ADD A, #'0'
	CALL lcd_write_data
	RET

;------------------------------------------------------------------------------------------------------------------------------------
; Realizacja procedury inicjujacej timer wykorzystujacy mechanizmu przerwan
;------------------------------------------------------------------------------------------------------------------------------------
INICJUJ_TIMER:
	MOV SEC, #0
	MOV MIN, #0
	MOV HOUR, #0
	MOV LICZNIK, #20 


    	CLR TR0
    	ANL TMOD, #0F0H 		
    	ORL TMOD, #1 			

    	MOV TH0, #HIGH(LOAD) 	
    	MOV TL0, #LOW(LOAD) 	
    	CLR TF0 				

    	SETB ET0 				
    	SETB EA 				
    	SETB TR0 				

    RET 					


;------------------------------------------------------------------------------------------------------------------------------------
; Wyswietlanie czasu
;------------------------------------------------------------------------------------------------------------------------------------
time_display:
	MOV A, 00000000B
	CALL  gotoxy
	MOV A, HOUR
	CALL lcd_wyswietl_liczbe

	MOV A, #':'
	CALL lcd_write_data

	MOV A, MIN
	CALL lcd_wyswietl_liczbe

	MOV A, #':'
	CALL lcd_write_data

	MOV A, SEC
	CALL lcd_wyswietl_liczbe

RET

gotoxy:
	 MOV R2, #0			
	 JNB ACC.4, next		
	 MOV R2, #1
					  	
	 next:
	 MOV R3, #00001111b		
	 ANL A, R3				
	 MOV R3, A
	 
	 MOV A, R2				
	 MOV B, #01000000b		
	 MUL AB				
     	 ADD A, R3  			
	 MOV A, #10000000b				
	 CALL lcd_write_cmd			

	RET
END 

