write_cmd EQU 0FF2CH
write_data EQU 0FF2DH
read_status EQU	0FF2EH
read_data EQU 0FF2CH

init EQU 038H					; Kod inicjalizacji wyswietlacza
clear EQU 001H					; Kod wyczyszczenia wyswielacza
on	EQU 00EH 					; Kod wlaczenia lcd

TIME EQU 50 					; Zmienna - czas do odmierzenia w ms
LOAD EQU (65536 - TIME*1000) 	; Zmienna - liczba cykli potrzebnych do odmierzenia czasu 

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

ORG 0BH 						; Blok kodu obslugi przerwania, start pod adresem 0x00BH

    MOV TH0, #HIGH(LOAD) 		; Zaladowanie starszych bitów zmiennej z liczba cykli(stop)
    MOV TL0, #LOW(LOAD) 		; Zaladowanie mlodszych bitów zmiennej z liczba cykli(start)


	PUSH PSW
	PUSH ACC

	DEC LICZNIK
	DJNZ LICZNIK, int_exit
	MOV LICZNIK, #20 

    CPL P1.0 					; Zapalanie/zgaszenie diody na linii 0 portu P1

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
    RETI ; Wyjscie z bloku kodu obslugi przerwania

loop:
	LCALL time_display
	JNB SEG_CHANGE,  loop
	CLR SEG_CHANGE
	SJMP loop

work:
	SJMP	loop
				
;--------------------------------------------
; Zapis komendy		A - kod komendy
;--------------------------------------------
lcd_write_cmd:
	PUSH ACC
	MOV DPTR, #read_status		;Wartosc adresu pamieci do dptra

petla_zajetosci_cmd:
	MOVX A, @DPTR					;Zawartosc z adresu read_status wkladamy do akumulatora
	JB ACC.7, petla_zajetosci_cmd   ;Na 6 bicie jest ostatni adres, a na 7 jest BF. Musimy sprawdzic, czy jest zajeta
	
	MOV DPTR, #write_cmd
	POP ACC
	MOVX @DPTR, A

	RET
;--------------------------------------------
; Inicjalizacja wyswietlacza
;--------------------------------------------
lcd_inicjalizacja:
	MOV A, #init				  		; Do akumulatora kod inicjalizujacy wyswietlacz
	CALL lcd_write_cmd			  		; Wywolanie funckji zapisu komendy - dla init
	MOV A, #clear			   	  		; Czyszczenie lcd
	CALL lcd_write_cmd			  		; Wywolanie czyszczenia
	MOV A, #on				   	  		; Do akumulatora wpisujmey kod wlaczajacy wyswietlacz lcd
	CALL lcd_write_cmd			  		; Wywolujemy wlaczenie lcd
	RET

;--------------------------------------------
; Wyswietlanie danych		A - kod wyswietlania danych w lcd 
;--------------------------------------------
lcd_write_data:
	PUSH ACC
	MOV DPTR, #read_status				; Wartosc adresu pamieci do dptra

 petla_zajetosci_danych:
	MOVX A, @DPTR						; Zawartosc z adresu read_status wkladamy do akumulatora
	JB ACC.7, petla_zajetosci_danych    ; Na 6 bicie jest ostatni adres, a na 7 jest BF. Musimy sprawdzic, czy jest zajeta

	MOV DPTR, #write_data
	POP ACC
	MOVX @DPTR, A		  				; Musimy to odzyskaæ, bo w A bylyby smieci

	RET

;--------------------------------------------
; Wypisywanie liczby zapisanej na dwoch miejscach 
;--------------------------------------------
lcd_wyswietl_liczbe:
	MOV B, #10
	DIV AB
	ADD A, #'0'
	CALL lcd_write_data
	MOV A, B
	ADD A, #'0'
	CALL lcd_write_data
	RET

;---------------------------------------------------------------------------------------------
; Realizacja procedury inicjujacej timer wykorzystujacy mechanizm przerwan
;---------------------------------------------------------------------------------------------
INICJUJ_TIMER:
	MOV SEC, #0
	MOV MIN, #0
	MOV HOUR, #0
	MOV LICZNIK, #20 


    CLR TR0 				; Wylaczanie timera
    ANL TMOD, #0F0H 		; Wyzerowanie rejestru sterujacego timera nr 0
    ORL TMOD, #1 			; Ustawienie trybu timera na 16 bitów

    MOV TH0, #HIGH(LOAD) 	; Zaladowanie starszych bitów zmiennej z liczba cykli(stop)
    MOV TL0, #LOW(LOAD) 	; Zaladowanie mlodszych bitów zmiennej z liczba cykli(start)
    CLR TF0 				; Wyzerowanie bitu przepelnienia

    SETB ET0 				; Ustawienie obslugi przerwania dla timera nr 0
    SETB EA 				; Ustawienie obslugi przerwania
    SETB TR0 				; Wlaczenie timera

    RET 					; Wyjscie z procedury


;---------------------------------------------------------------------------------------------
; Wyswietlanie czasu
;---------------------------------------------------------------------------------------------
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
	 MOV R2, #0				; Zerwanie rejestru r2
	 JNB ACC.4, next		; Jesli flaga BF next
	 MOV R2, #1
					  	
	 next:
	 MOV R3, #00001111b		; Maska na 4 ost bity
	 ANL A, R3				; Iloczyn logiczny maski z akumulatorem, bierzemy pod uwage tylko 4 ostatnie bity
	 MOV R3, A
	 
	 MOV A, R2				; Wpisujemy bit 0 - linia y do A
	 MOV B, #01000000b		; Przesanie 64 - liczby bitow w pojedynczej linii lcd
	 MUL AB					; Wyznaczenie adresu paiemieci dla y - wyznaczenie miejsca pamieci, w ktorym jest y
     ADD A, R3  			; Dodanie do akumulatora wsp x
	 MOV A, #10000000b		; Wlaczanie adresowanie pamieci XRAM DDRAM		
	 CALL lcd_write_cmd		; Wywolanie zapisu 	

	RET
END 

