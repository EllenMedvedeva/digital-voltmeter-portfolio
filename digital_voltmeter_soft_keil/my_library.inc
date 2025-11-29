; RAM - пам€ть, дл€ хранени€ данных, существующих в ходе выполнени€ программы. 0х00 - 0х1F - это диапазон адресов дл€ 
; регистров общего назначени€. 0х20 - 0х2F - диапазон битовой адресации.
;CODE_BYTE_1		EQU		0x20
;CODE_BYTE_2		EQU		0x21
;CODE_BYTE_3		EQU		0x22
;COUNTER_I		EQU		0x23
;COUNTER_J		EQU		0x24
;FLAG_1			EQU		0x25
;FLAG_2			EQU		0x26


;CSEG	at	0x0110

;Send_code_to_PC:
	;MOV		SFRPAGE,	#0x01
	;MOV		A,		R5
	;MOV		SBUF1,		A
	;INC		R2
	;ACALL	Wait
	
	;MOV		A,		R6
	;MOV		SBUF1,		A
	;INC		R2
	;ACALL	Wait
	
	;MOV		A,		R7
	;MOV		SBUF1,		A
	;INC		R2
	;ACALL	Wait
	;NOP
;RET


;Wait:
	;CJNE	R2,		#0,		Wait
;RET


;Send_code_to_PC_1:
	;MOV		SFRPAGE,	#0x01
	;MOV		A,		R5
	;MOV		SBUF1,		A
	;Poll_SCON1_b1_1:
		;JNB		TI1,	Poll_SCON1_b1_1
		;CLR		TI1

	;MOV		A,		R6
	;MOV		SBUF1,		A
	;Poll_SCON1_b1_2:
		;JNB		TI1,	Poll_SCON1_b1_2
		;CLR		TI1

	;MOV		A,		R7
	;MOV		SBUF1,		A
	;Poll_SCON1_b1_3:
		;JNB		TI1,	Poll_SCON1_b1_3
		;CLR		TI1		
;RET



;Get_data_from_ADC:
	;CLR		AD0INT
	;SETB	AD0BUSY
;; ¬от тут что-то не работает. ћожет быть где-то нужно добавить задержку в 1.5 мкс.
	;Poll_AD0INT:
		;JNB		 AD0INT,	Poll_AD0INT
	
	;MOV		A,		ADC0H
;RET

;Wait_ADC:
	;MOV		R2,		#0
	;MOV		R1,		#0
	
	;Wait_ln:
		;DJNZ	R2,		Wait_ln
		;DJNZ	R1,		Wait_ln
;RET

;Send_value_to_PC:
	;MOV		SFRPAGE,	#0x01
	;MOV		SBUF1,		A
	;Poll_SCON1_b1_4:
		;JNB		TI1,	Poll_SCON1_b1_4
		;CLR		TI1	
;RET


