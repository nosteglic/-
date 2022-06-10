;-------------------------------------------------------------------！！！！！！
;子程序名：SetJiShu
;功能：设置8253计数值得到不同的频率
;入口参数：SetCount
;出口参数：JuShu，SpeedNumber
;影响寄存器：AX,BX
SetJiShu PROC NEAR
    PUSH AX             ;保护现场
    PUSH BX
    INC SetCount        ;输入0对应1级速度，以此类推
    MOV AL,SetCount     ;保存速度级数到SpeedNumber
    MOV SpeedNumber,AL
    MOV AL,101          ;根据速度级数通过5000+100*(101-级数)计算8253计数值
    SUB AL,SetCount
    MOV BL,100
    MUL BL
    ADD AX,5000
    MOV JiShu,AX        ;将计数值传给JiShu
    POP BX              ;恢复现场
    POP AX  
    RET
SetJiShu ENDP