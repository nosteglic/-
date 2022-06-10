;-------------------------------------------------------------------
;子程序名：DELAY0
;功能：延时子程序：延时使多位数码管同时显示
;影响寄存器：CX
DELAY0 PROC NEAR
	PUSH CX
	MOV CX,500
        LOOP $
 	POP CX
 	RET
DELAY0 ENDP
;-------------------------------------------------------------------
;子程序名：DELAY1
;功能：延时子程序：延时用于防止输入数字时过快
;影响寄存器：CX
DELAY1 PROC NEAR
	PUSH CX
	MOV CX,25000
    LOOP $
 	POP CX
	RET
DELAY1 ENDP
;-------------------------------------------------------------------
;子程序名：DELAY2
;功能：延时子程序：用于扫描按键时按键消抖
;影响寄存器：CX
DELAY2 PROC NEAR
	PUSH CX
	MOV CX,10
	LOOP $
	POP CX
	RET
DELAY2 ENDP