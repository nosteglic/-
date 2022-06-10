;-------------------------------------------------------------------
;子程序名：【SCANKEY】
;功能：列扫描按键得到键值
;出口参数：AL=键值
;影响寄存器：CX,DX
;调用子程序：TRANSLATE   \    DELAY2
SCANKEY PROC NEAR
	PUSH CX
	PUSH DX             ;保护寄存器
	MOV DX,PORT8255_B	;B【列线】
	MOV AL,0
	OUT DX,AL		    ;列输出全0
	MOV DX,PORT8255_C	;C【行线】
	IN AL,DX		    ;读取C端口（行端口）
	AND AL,3
	CMP AL,03H		    ;检测行信息(2行->03H)是否全为1，判断有无按键
	JZ NO_KEY		    ;无按键时，转移后返回-1
	CALL DELAY2		    ;调用延时子程序延时消抖
	IN AL,DX		    ;读取行端口
	AND AL,03H
	CMP AL,03H		    ;检测行信息是否全为1，判断有无按键
	JZ NO_KEY		    ;无按键时，转移后返回-1
	MOV AH,0FEH		    ;指定列码，从PB0列开始扫描
	MOV CX,8		    ;最多扫描8列
NEXT:MOV AL,AH	        ;列码->AL
	ROL AH,1		    ;形成下一列的列码，为扫描下一列做准备
	MOV DX,PORT8255_B
	OUT DX,AL		    ;输出列码
	MOV DX,PORT8255_C
	IN AL,DX		    ;读取行码
	AND AL,03H
	CMP AL,03H		    ;ZF=0 或 CX=0则退出循环
	LOOPZ NEXT
	JZ NO_KEY		    ;ZF=1,无按键，转移后返回-1
	ROR AH,1		    ;存放形成的列行码->AX（恢复刚才的列码）
    CALL TRANSLATE		;列行码转换为键值->AL
	JMP EXIT
NO_KEY:
    MOV AL,-1           ;没有按键AL=-1
EXIT:
    CALL LED_DISPLAY    ;显示LED（防止显示乱码）
    POP DX
	POP CX
	RET
SCANKEY ENDP