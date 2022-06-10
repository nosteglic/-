;-------------------------------------------------------------------
;子程序名：【TRANSLATE】
;功能：列行码转换为键值
;入口参数：AX=扫描到的按键的列行码
;         KEYVALUE=键值表
;         KEYCODE=列行码表
;影响寄存器：CX,SI,DI
TRANSLATE PROC NEAR
	PUSH CX
	PUSH SI
	PUSH DI             ;保护寄存器
	MOV CX,16		    ;16个按键，设置循环次数
	LEA SI,KEYVALUE-1	;初始化键值表地址
	LEA DI,KEYCODE-2	;初始化列行码表地址
SCANTAB:
    INC SI			    ;用SCANKEY子程序返回的列行码查表
	ADD DI,2		    ;修改指针
	CMP AX,[DI]		    ;比较查找按键
	LOOPNZ SCANTAB		;ZF=1 或 CX=0则退出循环
	JNZ QUIT		    ;ZF=0则结束
	MOV AL,[SI]		    ;得到键值
QUIT:
    POP DI              ;恢复寄存器
	POP SI
	POP CX
	RET
TRANSLATE ENDP