;-------------------------------------------------------------------
;子程序名：StepControlSet
;功能：判断电机转动方式，并送下一次送入StepControl的值
;入口参数：ControlStyle转动方式数组，以及偏移量DI（StyleMove）
;出口参数：StepControl
;影响寄存器：BX,AX
;问题修改：顺时针-->右移,逆时针-->左移
StepControlSet PROC NEAR
    PUSH BX
    PUSH AX
    XOR BX,BX
    MOV BL,StyleMove          ;将偏移量送入StyleMove
    MOV AL,[ControlStyle+BX]  ;将转动方式的相位值送给StepControl
    MOV StepControl,AL
    CMP BX,2                  ;是否是单双8拍的转动方式
    JNB DanShuang8            ;如果是单双8拍，则跳转到DanShuang8
    CMP bClockwise,1          ;否则，判断电机转动方向
    JZ  ControlClockwise      ;如果是正转，跳转到ControlClockwise
ControlAntiClockwise:         ;如果是反转，顺势左移1位
    ROL [ControlStyle+BX],1
    JMP SCNEXT
ControlClockwise:             ;如果是正转，顺势右移1位
    ROR [ControlStyle+BX],1
    JMP SCNEXT
DanShuang8:                   ;单双8拍的转动方式
    CMP bClockwise,1          ;判断电机转动方向
    JZ DSClockwise            ;如果是正转，跳转到DSClockwise
DSAntiClockwise:              ;如果是反转，选择数组下一个值送入StepControl
    DEC BX
    CMP BX,10                 ;相位值循环(偏移量DI增加)
    JNZ SCNEXT
    MOV BX,9
    JNZ SCNEXT
DSClockwise:                  ;如果是正转，选择数组上一个值送入StepControl
    INC BX
    CMP BX,1                  ;相位值循环(偏移量DI减少)
    JNZ SCNEXT
    MOV BX,2
    JNZ SCNEXT
SCNEXT:
    MOV StyleMove,BL          ;保存此时的偏移量值进StyleMove
    MOV AL,[ControlStyle+BX]
    MOV StepControl,AL        ;将下一步相位值给到StepControl
    POP AX
    POP BX
    RET
StepControlSet ENDP