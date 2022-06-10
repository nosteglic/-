;-------------------------------------------------------------------
;子程序名：StepCountSet
;功能：把buffer0-3（当前步数值）送入StepCount
;入口参数：buffer0-3
;出口参数：StepCount
;影响寄存器：AX,BX
StepCountSet PROC NEAR
    PUSH AX
    PUSH BX                             ;保护现场
    MOV AL,buffer+3                     ;（buffer+3）-->AL    
    MOV BX,10
    MUL BL
    ADD AL,buffer+2                     ;AL*10+（buffer+2）-->AL
    MUL BL
    ADD AL,buffer+1                     ;AL*10+（buffer+1）-->AL
    ADC AH,0
    MUL BX
    ADD AL,buffer                       ;AL*10+（buffer）-->AL
    ADC AH,0
    MOV StepCount,AX                    ;转动步数送入StepCount
    POP BX                              ;恢复现场
    POP AX
    RET
StepCountSet ENDP