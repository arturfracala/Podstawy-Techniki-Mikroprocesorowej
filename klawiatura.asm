P5	EQU		0F8h
P7	EQU		0DBh
	
ORG 0
						

;============================================================================================
; Petla glowna programu
;============================================================================================

loop:
	MOV	A, #01111111B
	LCALL rd_row				   
	JC is_key					 
	MOV P1, #0FFH				 
	SJMP loop

is_key:
	CPL A						  
	CLR ACC.7					 
	MOV P1, A				     
	SJMP loop

;============================================================================================
;Funkcja zwraca numer klawisza wiersza lub informacje o braku odczytu
;============================================================================================
rd_row:	
	ANL P5, #00001111B
	ANL A, #11110000B 	 
    ORL P5, A			  
		 
	MOV A, P7			
    CPL A
    ANL A, #00001111B	 

	CLR C       	   
	JZ koniec

	MOV R0, #0	
rd_row_loop:
    JB ACC.3, koniec2
    INC R0
    RL A                    
    SJMP rd_row_loop

koniec2:
	SETB C				
	MOV A, R0
koniec:
	RET					   ;

END   
