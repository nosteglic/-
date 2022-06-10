;-------------------------------------------------------------------
;子程序名：AlterStep
;功能：步进电机的步数调整
;入口参数：步数（buffer低4位）数组首地址BX，步数位数CX
;出口参数：buffer低4位
;影响寄存器：BX,CX
;问题修改：处理特殊数字跳转及设置9999反转
AlterStep PROC
    PUSH CX                          ;保护现场
    PUSH BX
    CALL StepCountSet                ;获取显示屏当前步数
    MOV CX,4                         ;设置步数位数
    LEA BX,buffer                    ;数组首地址
    CMP bClockwise,1                 ;判断正/反转
    JZ ClockwiseSet
AntiClockwiseSet:                    ;反转设置
    CMP BYTE PTR[BX+4],11H           ;判断步数是正是负
    JZ AddStep                       ;步数为负，+1
    CMP StepCount,0                  ;步数为0.0000
    JNZ AntiClockwiseSet1
    MOV BYTE PTR[BX+4],11H
    INC BYTE PTR[BX]                 ;则步数变为-.0001
    JMP AlterStep1
AntiClockwiseSet1:
    JMP SubStep                      ;步数为正，-1
ClockwiseSet:                        ;正转设置
    CMP BYTE PTR[BX+4],10H           ;判断步数是正是负
    JZ AddStep                       ;步数为正，+1
    CMP StepCount,1                  ;步数是否为-.0001
    JNZ ClockwiseSet1
    MOV BYTE PTR[BX+4],10H
    DEC BYTE PTR[BX]                 ;步数变为0.0000
    JMP AlterStep1
ClockwiseSet1:
    JMP SubStep                      ;步数为负，-1
AddStep:
    INC BYTE PTR [BX]                ;步数+1
    CMP BYTE PTR [BX],0AH            ;低位是否产生进位
    JNZ AlterStep1                   ;无进位，则退出
    MOV BYTE PTR [BX],0              ;有进位，处理进位
    INC BX
    LOOP AddStep
    SUB BX,4
    MOV CX,4                         ;四位都有进位则达到最大值
AddStep1:                            ;设置最大值0.9999
    MOV BYTE PTR [BX],9
    INC BX
    LOOP AddStep1
    XOR bClockwise,1        ;步数>9999,使电机反转
    CMP BUFFER+7,0BH        ;同时修改转动方式
    JZ BD_fanzhuan
    CMP BUFFER+7,0DH
    JZ BD_fanzhuan
    DEC BUFFER+7
    JMP AlterStep1
BD_fanzhuan:
    INC BUFFER+7 
    JMP AlterStep1
SubStep:
    DEC BYTE PTR [BX]       ;步数-1
    CMP BYTE PTR [BX],0FFH  ;低位是否产生借位
    JNZ AlterStep1          ;无借位，则退出
    MOV BYTE PTR [BX],9     ;有借位，处理借位
    INC BX
    LOOP SubStep
AlterStep1:
    POP BX                  ;恢复现场
    POP CX
    RET
AlterStep ENDP