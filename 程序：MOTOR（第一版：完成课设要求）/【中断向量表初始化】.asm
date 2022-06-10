;-------------------------------------------------------------------
;子程序名：[INTERRUPT_VECTOR]
;功能：中断向量表初始化
;影响寄存器：ES,AX,BX
INTERRUPT_VECTOR PROC NEAR
	PUSH ES
	PUSH AX
	PUSH BX
	MOV AX,0
	MOV ES,AX
	MOV BX,08H*4		    ;BX<-中断向量地址
	MOV AX,OFFSET TIMERO    ;中断子程序地址
	MOV ES:[BX],AX		    ;存放偏移地址
	MOV AX,SEG TIMERO
	MOV ES:[BX+2],AX	    ;存放段地址
	POP BX
	POP AX
	POP ES
	RET
INTERRUPT_VECTOR ENDP
