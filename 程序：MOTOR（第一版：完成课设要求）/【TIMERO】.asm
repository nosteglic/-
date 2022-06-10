;-------------------------------------------------------------------
;子程序名：TIMERO
;功能：中断子程序
;影响变量：StepDec,StepControl,bNeedDisplay
;影响寄存器：AX,DX
TIMERO PROC NEAR
    PUSH AX
    PUSH DX
    MOV AL,StepControl          ;将下一次要送给步进电机的值送给AL
    MOV DX,PORT8255_C           ;将StepControl通过8255C口输出
    OUT DX,AL
    CALL StepControlSet         ;设置下一步相位值
    MOV bNeedDisplay,1          ;设置需要显示新步数
    CALL AlterStep              ;调用步数调整子程序对显示屏显示的步数进行调整
    CMP StepDec,-1              ;判断是否设置步数
    JZ TIMERO_1                 ;没有设置步数即B,C模式下，直接发结束中断EOI
    DEC StepDec                 ;设置步数，中断一次步数-1
    CMP StepDec,0               ;判断D,E功能下设置的步数StepDec有没有走完
    JNZ TIMERO_1                ;如果走完了需要关中断停止，并使bFirst为1
    MOV DONE,1                  ;中断完成，标志位置'1'
    CLI                         ;关中断
    MOV bFIRST,1                ;电机-->停机状态
TIMERO_1:
    MOV DX,PORT8259_0           ; 发结束中断EOI
    MOV AL,20H
    OUT DX,AL
    POP DX
    POP AX
    IRET
TIMERO ENDP