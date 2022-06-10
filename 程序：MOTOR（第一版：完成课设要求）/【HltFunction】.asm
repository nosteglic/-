;-------------------------------------------------------------------
;子程序名：[HltFunction]
;功能：数码管显示全F子程序
;影响寄存器：AX,DX
;调用子程序：DELAY0
HltFunction PROC NEAR
    PUSH AX
    PUSH DX                     ;保护现场
    MOV  AL, 0FFH               ;位码=0FFH
    MOV  DX, PORT8255_B
    OUT  DX, AL                 ;熄灭所有数码管
    MOV  AL,8EH                 ;F的段码
    MOV  DX, PORT8255_A
    OUT  DX, AL                 ;送出段码
    MOV  AL,0                   ;所有位都显示
    MOV  DX, PORT8255_B
    OUT  DX, AL                 ;送出位码
    CALL DELAY0                 ;进行适当的延时
    POP DX                      ;恢复现场
    POP AX
    RET
HltFunction ENDP