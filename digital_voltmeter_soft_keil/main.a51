$include (c8051F120.inc)		
$include (my_library.inc)	
	

CSEG AT 0
LJMP Main

;-------------------------------------------------------------------------------------------------------------------
;--------------------------------------------INTERRUPTION-UART1-START-----------------------------------------------
;-------------------------------------------------------------------------------------------------------------------
CSEG	at	0x00A3							; Вектор прерывания от UART1.
	
	MOV	SFRPAGE,	#0x01
;Проверяем, от кого пришло прерывание - от приемника или от передатчика. Нам нужен именно приемник.

	JNB		RI1,	Iinterruption_from_transmitter 		; Переход, если бит равен нулю, т.е. прерывание пришло от передатчика, поэтому скипаем часть кода.
	
	CLR		RI1				; Очистить флаг прерывания.
	MOV		A,		SBUF1	; Извлечь данные из буфера приемника.
	MOV		R6,		A
	MOV		B,		#0x0F
		
	DIV		AB		; Если пришло число типа ХХХХ.0000 - это код от ПК. Если пришло число типа 0000.ХХХХ - это служебная информация.
					; В А записывается результат от деления, а в В - остаток.
	
	JZ 		Process_app_inf	; переход, если аккумулятор навен 0, т.е. если пришел диапазон от ПК.

	MOV		R5,		COUNTER_J
	CJNE 	R5,		#0x00,	Byte_1_is_checked	; Сравнение регистра с константой и переход, если не равно.
	
	CJNE 	R6,		#0xAA,	Byte_is_not_correct
	INC		COUNTER_J
	AJMP	End_UART1
	
Byte_1_is_checked:
	CJNE 	R5,		#0x01,	Byte_2_is_checked

	CJNE 	R6,		#0xBB,	Byte_is_not_correct
	INC		COUNTER_J
	AJMP	End_UART1
	
Byte_2_is_checked:
	CJNE 	R6,		#0xCC,	Byte_is_not_correct

; Если код, полученный от ПК, верный:
	CLR		P1.3
	MOV		FLAG_1,		#0x01

	MOV		COUNTER_J,		#0x00		; R4 = j
	MOV		COUNTER_I,		#0x00		; R3 = i
	ACALL	Send_code_to_PC_1
	
	SJMP	End_UART1

Byte_is_not_correct:
	SETB	P1.3
	MOV		FLAG_1,		#0x00
	
	MOV		COUNTER_J,		#0x00		; R4 = j
	MOV		COUNTER_I,		#0x00		; R3 = i
	ACALL	Send_code_to_PC_1
	SJMP	End_UART1


;-------------------------------------------------------------------------------------------------------------------
Process_app_inf:
	MOV		R5,		B
	CJNE 	R5,		#0x00,		Set_f2
	MOV		FLAG_2,	#0x00
	LJMP	End_UART1
	Set_f2:
		MOV		FLAG_2,		#0x01
		LJMP	End_UART1

Iinterruption_from_transmitter:
	CLR		TI1
	MOV		R2,	#0x00
End_UART1:
	RETI	
;-------------------------------------------------------------------------------------------------------------------
;---------------------------------------------INTERRUPTION-UART1-END------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------



;-------------------------------------------------------------------------------------------------------------------
;----------------------------------------------INTERRUPTION-T0-START------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------
CSEG	at		0x000B							; Вектор прерывания от Таймера-0.
	MOV		SFRPAGE,	#0x00
	INC		COUNTER_I	
	MOV		R7,		COUNTER_I
	CJNE 	R7,		#0x78,	Restart_timer	;было 0х78
	
	MOV		FLAG_1,		#0x00
	SETB		P1.3	; Т.е. создаем высокоимпедансный вход.
	
	MOV		COUNTER_I,		#0x00
	MOV		COUNTER_J,		#0x00
	ACALL	Send_code_to_PC_1

Restart_timer:
	MOV		SFRPAGE,	#0x00
	MOV	TH0,	#0x9E
	MOV	TL0,	#0x58
	SETB	TR0
;	CPL		P1.0

RETI
;-------------------------------------------------------------------------------------------------------------------
;-----------------------------------------------INTERRUPTION-T0-END-------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------




;-------------------------------------------------------------------------------------------------------------------
;-------------------------------------------------SETTINGS-START----------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------

CSEG	at	0x0200
Main:
; -1.. Предварительная настройка МК.
	MOV WDTCN,		#0xDE	; Отключить строковый таймер.
	MOV WDTCN,		#0xAD	; Отключить сторожевой таймер. В общем, отключаем приндительную перезагрузку системы по 
;истечении какого-то времени, придуманному разработчиком камушка. См. стр. 183 даташита.
	MOV SFRPAGE,	#0x0F	; Перейдем на станицу F, чтобы настроить матрицу и автоматическое переключение страниц.
;	MOV SFRPGCN,	#0x01	; Запрещаем автоматическое перключение страниц.
;	MOV OSCICN,		#0xC3	; Вкючаем внутренний генератор с частотой 24,5 МГц.
;-------------------------------------------------------------------------------------------------------------------

; 0. Настройка тактирования ядра.
 
	MOV	OSCXCN,		#01100111b	; стр. 191
; 					 76543210
; При сбросе по умолчанию включен внутренний генератор. Ждем, пока всключится ии установится внутренний генератор.
	MOV	R0,	#0
	MOV	R1,	#80
 
Waiting_ms:
	DJNZ	R0,	Waiting_ms
	DJNZ	R1,	Waiting_ms

Waiting_XTLVLD:
	MOV	B,			OSCXCN
	JNB	B.7,		Waiting_XTLVLD

; А вот теперь выбираем тактовый сигнал.
	MOV CLKSEL,	#00000001b		; Т.е.  SYSCLK = 12 МГц.
;			 76543210

; Выключаем внутренний генератор.
	MOV OSCICN,	#0x00

;-------------------------------------------------------------------------------------------------------------------

; 1. Настройка ножек Порта-0.

	MOV	P0MDOUT,	#00001101b 
	MOV		P0,		#11111111b
					;76543210
	
	MOV	P1MDOUT,	#01000000b 
	MOV		P1,		#00001111b
					;76543210
					
	;SCK - P0.0
	;MISO - P0.1
	;MOSI - P0.2				
	;TX1 - P0.3
	;RX1 - P0.4

;-------------------------------------------------------------------------------------------------------------------
; 2. Настройка SPI, который не используется.

	MOV		SFRPAGE,	#0x00		
	MOV		SPI0CFG,	#01000000b	; включаем ведущий режим
	MOV		SPI0CN,		#00000001b	; включаем модуль SPI0
	
;-------------------------------------------------------------------------------------------------------------------
; 3. Настройка Таймера-1 для UART и Таймера-0.
; Таймер-1 должен быть настроен как 8-разрядный таймер с автоматической перезагрзкой (стр. 300).
; Таймер-0 должен отсчитывать 200 ms. Настраиваем его как 16-разрядный Т/С по примеру ДВ.

	MOV	TMOD,	#00100001b	; стр. 319.
;				 76543210
	MOV	CKCON,	#00000000b	; стр. 320.
;				 76543210
	MOV	TH1,	#0xCC	; Расчитывается по формуле на стр. 300 или для скорости 9600 бит/с можно взять 
						; значение из таблички на стр. 309.
	MOV	TL1,	#0	; На стр. 316 написано, что этот регистр в любом случае придется инициализировать.

	MOV	TH0,	#0x9E
	MOV	TL0,	#0x58
	
	SETB	TR1				; Включить таймер TR-1.
	
;-------------------------------------------------------------------------------------------------------------------
; 4. Настройка UART1.
	
	MOV	SFRPAGE,	#0x01		
	MOV	SCON1,		#00110000b	
;					 76543210

;-------------------------------------------------------------------------------------------------------------------
; 5. Включение тактирования Порта-0.

	MOV	SFRPAGE,	#0x0F 
	MOV XBR0,	#00000010b	; стр. 247.
;			 	 76543210
	MOV XBR2,	#11000100b
;			 	 76543210

;-------------------------------------------------------------------------------------------------------------------

; 6. Настройка прерываний.
;	SETB	EA
;	CLR		EA
	MOV  IE,	#10000010b	; стр. 159.
;			 	 76543210
;	SETB	ET0
;	MOV  IP,	#00000000b	; стр. 160.
;			 	 76543210

;	MOV  EIE1,	#00000000b	; стр. 161.  Тут потом будем настраивать АЦП.
;			 	 76543210

	MOV  EIE2,	#01000000b	; стр. 162.
;			 	 76543210
	
;	MOV  EIP1,	#00000000b	; стр. 164.
;			 	 76543210

;	MOV  EIP2,	#01000000b	; стр. 164.  Назначили прерываниям от UART1 высокий приоритет.
;			 	 76543210

;	SETB	EA
;-------------------------------------------------------------------------------------------------------------------

; 7. Настройка 12-разрядного АЦП0.

; По умолчанию все входы мультиплексора сконфигурированы как однофазные, пэтому регистр AMX0CF (стр. 62) не меняем.
; По умолчанию датчик температуры для АЦП выключен, поэтому регистр REF0CN (стр. 118) тоже не меняем.

; Выбираем частоту дискретизации. Непонятно как ее выбирать, если честно, но частота не должна првышать 2,5 МГц.
; Пусть частота дискретизации примерно равна 2 МГц, как у ДВ. Тогда AD0SC = 5 или 00101b. Стр. 64.
	MOV		SFRPAGE,	#0x00
		
	MOV 	REF0CN,		#00000011b
	MOV 	ADC0CF,		#00010000b	
;	MOV		AMX0SL,		#00000000b
		
	MOV 	ADC0CN,		#11010001b
;						 76543210
; Для этого регистра копируем настройки, как у ДВ, а именно:
; Бит 0: данные выровнены по левому краю.
; Бит 1: выключаем флаг прерывания от детектора диапазона.
; Биты 2-3: "Запуск преобразователя осуществляется установкой в 1 бита AD0BUSY", все как рекомендует даташит.
; Бит 4: Бит AD0BUSY пока инициализируем в 0.
; Бит 5: Флаг прерывания AD0INT очищаем.
; Бит 6: Косвенно выключаем слежение.
; Бит7 - бит включения АЦП.
;-------------------------------------------------------------------------------------------------------------------
;--------------------------------------------------SETTINGS-END-----------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------




;-------------------------------------------------------------------------------------------------------------------
;---------------------------------------------------MAIN-START------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------

; Изначально ножка DIV настроена как высокоимпедансный вход, т.е. делитель выключен.
	MOV		CODE_BYTE_1,	#0xAA
	MOV		CODE_BYTE_2,	#0xBB
	MOV		CODE_BYTE_3,	#0xCC
	MOV		COUNTER_I,		#0x00
	MOV		COUNTER_J,		#0x00
	MOV		FLAG_1,			#0x00
	MOV		FLAG_2,			#0x00
;	MOV		RANGE,			#0x01
	
	MOV		COUNTER_R1,		#0x00
	MOV		COUNTER_R2,		#0x00
	MOV		R3_LAST,		#0x00
		
; В первый раз передаем код на ПК.
	MOV		SFRPAGE,	#0x01
	MOV		A,		CODE_BYTE_1
	MOV		SBUF1,		A
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	MOV		A,		CODE_BYTE_2
	MOV		SBUF1,		A
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	MOV		A,		CODE_BYTE_3
	MOV		SBUF1,		A
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
; В первый раз зпускаем таймер.
	MOV		SFRPAGE,	#0x00
	SETB	TR0

Loop:
	;MOV		A,		FLAG_1
	;CJNE 	A,		#0x01,		Loop
	
	;MOV		A,		FLAG_2
	;CJNE 	A,		#0x01,		Loop
;	MOV		SFRPAGE,	#0x00
	MOV		A,		FLAG_1
	CJNE	A,		#1,		No_con
	
	ACALL	ADC	
	SJMP Loop

No_con:
						SETB	P1.0
						SETB	P1.2
						SETB	P1.1
						
	SJMP Loop
;-------------------------------------------------------------------------------------------------------------------
;----------------------------------------------------MAIN-END-------------------------------------------------------
;-------------------------------------------------------------------------------------------------------------------
	
	
ADC:
	
; На ОУ1 больше 2,2V?
	MOV		SFRPAGE,	#0x00
	MOV		AMX0SL,		#00000000b				; Считываем значение с ОУ1 (AIN0.0).
	
	ACALL	Get_data_from_ADC
	
	MOV		COUNTER_R1,		#255
	Compare_r1:
		MOV		A,		R4		; Перенесим в аккумулятор полученное с ОУ1 значение, при выключенном делителе.
		CJNE	A,		COUNTER_R1,		Change_counter_r1
	; Значит на ОУ1 напряг больше 2.2В. Значит он явно переполнен, и нужно обработать 3 диапазон.
		LJMP	Process_3_range
	
	Change_counter_r1:
		DEC		COUNTER_R1
		MOV		A,		COUNTER_R1
		CJNE	A,		#234,		Compare_r1
		; Значит на ОУ1 напряжение меньше или равено 2.2В. Значит нам нужно обработать 2 или 1 диапазон.

			; На ОУ2 больше 2,2V?
			MOV		AMX0SL,		#00000001b				; Считываем значение с ОУ2 (AIN0.1).
		
			ACALL	Wait_ADC
			ACALL	Wait_ADC
	
			ACALL	Get_data_from_ADC
	
			MOV		COUNTER_R1,		#255
			Compare_r2:
				MOV		A,		R4		; Перенесим в аккумулятор полученное с ОУ2 значение, при выключенном делителе.
				CJNE	A,		COUNTER_R1,		Change_counter_r2
			; Значит на ОУ2 напряг больше 2.2В. Значит он явно переполнен, и нужно обработать 2 диапазон.
				LJMP	Process_2_range
	
			Change_counter_r2:
				DEC		COUNTER_R1
				MOV		A,		COUNTER_R1
				CJNE	A,		#234,		Compare_r2
			; Значит на ОУ2 напряжение меньше или равено 2.2В. Значит нам нужно обработать 1 диапазон.
				LJMP	Process_1_range


Process_3_range:
	CLR		P0.7	; Включаем делитель.
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC

	MOV		AMX0SL,		#00000000b		; Считываем значение с ОУ1.

	ACALL	Get_data_from_ADC_1
		
; Сравнить данные с предыдущими.
;	MOV		A,		R3
;	CJNE	A,		R3_LAST,		 Save_new_data		; Если не равно, запомнить новые данные.
;		INC		COUNTER_R2
		
;		MOV		A,		COUNTER_R2
;		CJNE	A,		#3,		End_ADC

; Если в третьем диапазоне на передачу встречается число меньше 0.22B
			MOV		COUNTER_R1,		#255
			Compare_r4:
				MOV		A,		R3
				CJNE	A,		COUNTER_R1,		Change_counter_r4
			
				LJMP	Next
	
			Change_counter_r4:
				DEC		COUNTER_R1
				MOV		A,		COUNTER_R1
				CJNE	A,		#22,		Compare_r4
				
					;ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	
				LJMP	Process_2_range
				
		; Если пришло 3 одинаковых значени подряд, передаем данные на ПК.
		Next:
		; Тут нужно еще раз сравнить:
		
		; Если напряг 5V, т.е на ОУ1 будет 0,5V, 50-55.
		
		MOV		COUNTER_R1,		#51
			Compare_r5V:
				MOV		A,		R3
				CJNE	A,		COUNTER_R1,		Change_counter_r5V
			
				; индикация 3 диапазон*
						CLR		P1.0
						SETB	P1.2
						SETB	P1.1
						
						SETB	P0.7
;						SETB	P1.0

						MOV		SFRPAGE,	#0x01
						MOV		SBUF1,		R3
							ACALL	Wait_ADC
							ACALL	Wait_ADC
							ACALL	Wait_ADC
							ACALL	Wait_ADC
						MOV		SBUF1,		#3
						SETB	P1.0
						
						MOV		COUNTER_R2,		#0
						
						LJMP	End_ADC
	
			Change_counter_r5V:
				DEC		COUNTER_R1
				MOV		A,		COUNTER_R1
				CJNE	A,		#49,		Compare_r5V
		
		
		; Если напряг 2.5V, т.е на ОУ1 будет 0,33V, 33-41.
		
		
			MOV		COUNTER_R1,		#34
			Compare_r33V:
				MOV		A,		R3
				CJNE	A,		COUNTER_R1,		Change_counter_r33V
			
				; индикация 2 диапазон*
						CLR		P1.1
						SETB	P1.2
						SETB	P1.0
						
						SETB	P0.7
;						SETB	P1.1

						MOV		SFRPAGE,	#0x01
						MOV		SBUF1,		R3
							ACALL	Wait_ADC
							ACALL	Wait_ADC
							ACALL	Wait_ADC
							ACALL	Wait_ADC
						MOV		SBUF1,		#3
						
						MOV		COUNTER_R2,		#0
						SETB	P1.1
						
						LJMP	End_ADC
	
			Change_counter_r33V:
				DEC		COUNTER_R1
				MOV		A,		COUNTER_R1
				CJNE	A,		#32,		Compare_r33V
		
		
		; Если напряг 2.5V, т.е на ОУ1 будет 0,25V, 23-31.
		
		
		MOV		COUNTER_R1,		#25
			Compare_r25V:
				MOV		A,		R3
				CJNE	A,		COUNTER_R1,		Change_counter_r25V
			
				; индикация 1 диапазон*
						CLR		P1.2
						SETB	P1.1
						SETB	P1.0
						
						SETB	P0.7
;						SETB	P1.2

						MOV		SFRPAGE,	#0x01
						MOV		SBUF1,		R3
							ACALL	Wait_ADC
							ACALL	Wait_ADC
							ACALL	Wait_ADC
							ACALL	Wait_ADC
						MOV		SBUF1,		#3
						
						MOV		COUNTER_R2,		#0
						SETB	P1.2
						
						LJMP	End_ADC
	
			Change_counter_r25V:
				DEC		COUNTER_R1
				MOV		A,		COUNTER_R1
				CJNE	A,		#23,		Compare_r25V
		
		
		
		
		
		
		
		
			MOV		SFRPAGE,	#0x01
			MOV		SBUF1,		R3
				ACALL	Wait_ADC
				ACALL	Wait_ADC
				ACALL	Wait_ADC
				ACALL	Wait_ADC
			MOV		SBUF1,		#3
			
			MOV		COUNTER_R2,		#0
			
			; Световая индикация 3 диапазона.
			CLR		P1.0
			SETB	P1.2
			SETB	P1.1
			
			SETB	P0.7
			
			LJMP	End_ADC
		


Process_2_range:
	MOV		AMX0SL,		#00000000b		; Считываем значение с ОУ1.

	ACALL	Get_data_from_ADC_1
		
; Сравнить данные с предыдущими.
;	MOV		A,		R3
;	CJNE	A,		R3_LAST,		 Save_new_data		; Если не равно, запомнить новые данные.
;		INC		COUNTER_R2
		
;		MOV		A,		COUNTER_R2
;		CJNE	A,		#3,		End_ADC

; Если во втором диапазоне на передачу встречается число больше 2,2В, то (начинаем заново) или переходим в 3 диапазон.
			MOV		COUNTER_R1,		#255
			Compare_r3:
				MOV		A,		R3
				CJNE	A,		COUNTER_R1,		Change_counter_r3
			
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	
				LJMP	End_ADC
	
			Change_counter_r3:
				DEC		COUNTER_R1
				MOV		A,		COUNTER_R1
				CJNE	A,		#235,		Compare_r3
			
		; Если пришло 3 одинаковых значени подряд, передаем данные на ПК.
			MOV		SFRPAGE,	#0x01
			MOV		SBUF1,		R3
				ACALL	Wait_ADC
				ACALL	Wait_ADC
				ACALL	Wait_ADC
				ACALL	Wait_ADC
			MOV		SBUF1,		#2
			
			MOV		COUNTER_R2,		#0
			
			; Световая индикация 2 диапазона.
				CLR		P1.1
				SETB	P1.2
				SETB	P1.0
				
			LJMP	End_ADC


Process_1_range:
	MOV		AMX0SL,		#00000001b		; Считываем значение с ОУ2.

	ACALL	Get_data_from_ADC_1
		
; Сравнить данные с предыдущими.
;	MOV		A,		R3
;	CJNE	A,		R3_LAST,		 Save_new_data		; Если не равно, запомнить новые данные.
;		INC		COUNTER_R2
		
;		MOV		A,		COUNTER_R2
;		CJNE	A,		#3,		End_ADC
		; Если пришло 3 одинаковых значени подряд, передаем данные на ПК.
			MOV		SFRPAGE,	#0x01
			MOV		SBUF1,		R3
				ACALL	Wait_ADC
				ACALL	Wait_ADC
				ACALL	Wait_ADC
				ACALL	Wait_ADC
			MOV		SBUF1,		#1
			
			MOV		COUNTER_R2,		#0
			
			; Световая индикация 1 диапазона.
				CLR		P1.2
				SETB	P1.1
				SETB	P1.0
			
			LJMP	End_ADC


Save_new_data:
	MOV		R3_LAST,	R3
	MOV		COUNTER_R2,		#0

End_ADC:
	SETB	P0.7
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
	ACALL	Wait_ADC
RET	





CODE_BYTE_1		EQU		0x20
CODE_BYTE_2		EQU		0x21
CODE_BYTE_3		EQU		0x22
COUNTER_I		EQU		0x23
COUNTER_J		EQU		0x24
FLAG_1			EQU		0x25
FLAG_2			EQU		0x26
RANGE			EQU		0x27
	
COUNTER_R1		EQU		0x28
COUNTER_R2		EQU		0x29
R3_LAST			EQU		0x30

CSEG	at	0x0110

Send_code_to_PC_1:
	MOV		SFRPAGE,	#0x01
	MOV		A,		CODE_BYTE_1
	MOV		SBUF1,		A
	Poll_SCON1_b1_1:
		JNB		TI1,	Poll_SCON1_b1_1
		CLR		TI1

	MOV		A,		CODE_BYTE_2
	MOV		SBUF1,		A
	Poll_SCON1_b1_2:
		JNB		TI1,	Poll_SCON1_b1_2
		CLR		TI1

	MOV		A,		CODE_BYTE_3
	MOV		SBUF1,		A
	Poll_SCON1_b1_3:
		JNB		TI1,	Poll_SCON1_b1_3
		CLR		TI1		
RET

; ВАЖНО! Когда прога находится не в прерывании, при установлении флагов прерывания их бесполезно опрашиать. Прога сама перейдет в обработчик.
; Когда прога уже в прерывании, и нам нужно получить еще одно прерывание от какого-нибудь модуля, имеет смысл опрашивать флаги (т.е. ручками их проверять).


Get_data_from_ADC:
	ACALL	Wait_ADC
	ACALL	Wait_ADC

	MOV		SFRPAGE,	#0x00
	CLR		AD0INT
	SETB	AD0BUSY
	
	ACALL	Wait_ADC
	ACALL	Wait_ADC

	Poll_AD0INT:
		JNB		 AD0INT,	Poll_AD0INT
	
		ACALL	Wait_ADC
		ACALL	Wait_ADC
		
	MOV		R4,		ADC0H

RET

Get_data_from_ADC_1:
	ACALL	Wait_ADC
	ACALL	Wait_ADC

	MOV		SFRPAGE,	#0x00
	CLR		AD0INT
	SETB	AD0BUSY
	
	ACALL	Wait_ADC
	ACALL	Wait_ADC

	Poll_AD0INT_1:
		JNB		 AD0INT,	Poll_AD0INT_1
	
		ACALL	Wait_ADC
		ACALL	Wait_ADC
		
	MOV		R3,		ADC0H

RET





Wait_ADC:
	MOV		R2,		#0
	MOV		R1,		#0
	
	Wait_ln:
		DJNZ	R2,		Wait_ln
		DJNZ	R1,		Wait_ln
RET

END	