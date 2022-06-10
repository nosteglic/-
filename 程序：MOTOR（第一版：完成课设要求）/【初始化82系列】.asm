;------------------------------------------------------------------
;子程序名：[INIT8255]
;功能：8255初始化
INIT8255 PROC NEAR
    MOV DX,PORT8255_K
    MOV AL,81H              ;A方式0输出，B方式0输出，C低4位输入，高4位输出
    OUT DX,AL
    MOV  DX, PORT8255_B
    MOV AL,0FFH             ;位码全1，初始数码管全部熄灭
    OUT DX,AL
    RET
INIT8255 ENDP
;-------------------------------------------------------------------
;子程序名：INIT8253
;功能：8253初始化
INIT8253 PROC NEAR
    MOV DX,PORT8253_K
    MOV AL,34H              ;00110100计数器0，方式2，二进制计数
    OUT DX,AL
    MOV DX,PORT8253_0
    MOV AX,JiShu           ;10000+50*(101-n)
    OUT DX,AL
    MOV AL,AH
    OUT DX,AL
    RET
INIT8253 ENDP
;-------------------------------------------------------------------
;子程序名：[INIT8259]
;功能：8259初始化
INIT8259 PROC NEAR
    MOV DX,PORT8259_0
    MOV AL,13H              ;[ICW1]00010011,边沿触发，单片方式，使用ICW4
    OUT DX,AL
    MOV DX,PORT8259_1
    MOV AL,08H              ;[ICW2]00001000,中断类型号从08H开始
    OUT DX,AL
    MOV AL,09H              ;[ICW4]00001001,一般全嵌套，缓冲方式，非自动结束中断
    OUT DX,AL
    MOV AL,0FEH             ;[OCW1]11111110,开放IR0中断请求
    OUT DX,AL
    RET
INIT8259 ENDP