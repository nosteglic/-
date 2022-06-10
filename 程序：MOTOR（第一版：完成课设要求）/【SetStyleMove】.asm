;------------------------------------------------------------------
;子程序名：【SetStyleMove】
;功能：设置电机转动方式
;入口参数：开关量
;出口参数：StyleMove=电机转动方式
;影响寄存器：CX,SI,DI
SetStyleMove PROC
	PUSH AX
	PUSH DX
	MOV DX,PORT8255_C	
	IN AL,DX		    ;读取8255C端口
	SHR AL,1
	SHR AL,1            ;逻辑右移两位
	AND AL,3            ;使PC3PC2有效即得到输入的开关量
	MOV StyleMove,AL    ;开关量存入表示电机转动方式的变量StyleMove
	POP DX
	POP AX
	RET
SetStyleMove ENDP