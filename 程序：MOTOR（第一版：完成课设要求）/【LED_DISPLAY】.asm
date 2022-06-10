;-------------------------------------------------------------------
;子程序名：[LED_DISPLAY]
;功能：数码管显示子程序
;入口参数： BITCODE=位码值
;          SEGTAB=段码值
;          BUFFER=需显示数据缓存区
;影响寄存器：AX,CX,DX,SI
;调用子程序：DELAY
LED_DISPLAY PROC NEAR
    PUSH AX
    PUSH CX
    PUSH DX
    PUSH SI                     ;保护现场
    LEA  BX,SEGTAB              ;BX为段码表首址
    MOV BITCODE,0FEH            ;
    MOV  SI, 0                  ;SI用作缓冲区指针，初值为0
    MOV  CX, 8                  ;CX用作循环计数器，初值为8
ONE:
    MOV  AL, 0FFH              ;位码=0FFH
    MOV  DX, PORT8255_B
    OUT  DX, AL                 ;熄灭所有数码管
    MOV  AL, BUFFER[SI]         ;从缓存区得到待查元素在表中的序号
    XLAT                        ;查表转换
    MOV  DX, PORT8255_A
    OUT  DX, AL                 ;送出一位信息的字形码（段码）
    MOV  AL,BITCODE             ;位码
    MOV  DX, PORT8255_B
    OUT  DX, AL                 ;送出位码，选中某位数码管显示段码
    ROL  BITCODE, 1             ;循环左移有效“0”--->形成下一个位码
    INC   SI                    ;修改输出缓冲区指针
    CALL DELAY0                  ;进行适当的延时使多位数码管同时显示
    LOOP   ONE                  ;循环，显示下一位信息
    POP SI                      ;恢复现场
    POP DX
    POP CX
    POP AX
    RET
LED_DISPLAY ENDP