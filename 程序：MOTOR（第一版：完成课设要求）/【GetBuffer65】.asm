;-------------------------------------------------------------------
;子程序名：Getbuffer65
;功能：设置步进电机的步数/速度
;入口参数：十位buffer+6，个位buffer+5
;出口参数：步数/速度值SetCount
;影响寄存器：AX,BX
Getbuffer65 PROC
    PUSH AX
    PUSH BX                             ;保护现场
    MOV AL,buffer+6                     ;转动步数送入SetCount
    MOV BX,10
    MUL BL
    ADD AL,buffer+5
    MOV SetCount,AL
    POP BX                              ;恢复现场
    POP AX
    RET
Getbuffer65 ENDP