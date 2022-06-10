.MODEL TINY
PORT8255_A  EQU 270H        ;CS1
PORT8255_B  EQU 271H
PORT8255_C  EQU 272H
PORT8255_K  EQU 273H
PORT8253_0  EQU 260H        ;CS2
PORT8253_1  EQU 261H
PORT8253_2  EQU 262H 
PORT8253_K  EQU 263H
PORT8259_0  EQU 250H        ;CS3
PORT8259_1  EQU 251H
PORT8251_0  EQU 240H
PORT8251_1  EQU 241H	     ;CS4
.STACK 100
.DATA
    BITCODE   	    DB      ?                       ;存放位码值
    SEGTAB          DB      0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H,80H,90H, 88H,83H,0C6H,0A1H,86H,8EH,40H,3FH         ;段码->LED灯编码（0~F+"0."+"-."）
    KEYVALUE        DB      00H,01H,02H,03H,04H,05H,06H,07H,08H,09H,0AH,0BH,0CH,0DH,0EH,0FH                         ;键值表 +【10H -> "0."】+【11H -> "-."】
    KEYCODE         DW      0FE02H,0FD02H,0FB02H,0F702H,0EF02H,0DF02H,0BF02H,7F02H,0FE01H,0FD01H,0FB01H,0F701H,0EF01H,0DF01H,0BF01H,7F01H   ;键盘列行码
    BUFFER          DB      8 DUP(?)                ;数码管上显示内容缓存区 / 接收数据缓冲区
    bFirst          DB      0                       ;启停步进电机（0：启动；1：停止）
    bClockwise      DB      0                       ;电机转动方向（1：顺时针；0：逆时针）
    bNeedDisplay    DB      0                       ;已转动一步，需要显示新的步数
    StepControl     DB      0                       ;给步进电机下一步的相位值
    SetCount        DB      0                       ;步进电机的步数/转速
    StepCount       DW      0                       ;数码管显示的步数值
    StepDec         DW      0                       ;D,E设置的步数
    SpeedNumber     DB      0                       ;B,C设置的转速
    JiShu           DW      5000	                ;8253计数初值5000，0.005秒/步
    StyleMove       DB      0                       ;方式
    ControlStyle    DB      11H,33H,10H,30H,20H,60H,40H,0C0H,80H,90H        ;拍值
    DONE            DB      0			            ;设置的步数已走完及中断完成标志位
.CODE
START:                      
    MOV AX,@DATA
    MOV DS,AX		            ;装载DS
    ;-------------初始化部分
    CALL INIT8253               ;8253初始化
    CALL INIT8255               ;8255初始化
    CALL INIT8259               ;8259初始化
    CALL INIT8251               ;8251初始化
    CALL INTERRUPT_VECTOR       ;中断向量表初始化
    CALL RECEIVE8251            ;调用子程序获取初始化数据
    CALL INITMOTOR              ;步进电机模块初始化
    ;-------------等待设置步进电机节拍方式
WaitingSet:
    CALL SetStyleMove           ;调用子程序对设置的节拍方式进行读取判断
    CMP StyleMove,3             ;判断是否设置了节拍方式        
    JZ WaitingSet               ;还未设置节拍方式继续等待
    ;-------------开始显示并扫描按键
START_1:
    CALL LED_DISPLAY            ;调用数码管显示子程序
WAITEKEY:
    CALL SCANKEY	            ;调用扫描键盘子程序
    CMP AL,-1		            ;判断是否有按键按下
    JNZ START_2                 ;有按键按下，则跳转开始判断按键
    CMP bNeedDisplay,0          ;无按键，则判断电机有没有转动
    JZ  WAITEKEY                ;无按键，电机没有转动，则继续等待按键
    MOV bNeedDisplay,0          ;清零为下一次转动做准备
    CMP bFirst,0                ;电机转动了一步，且此时没有按键按下，判断电机此时的状态           
    JZ  Exec1	    	        ;电机处于启动状态-->则开中断启动
    JMP StopNEXT                ;电机处于停机状态-->则关中断停止
    ;-------------判断按键+设置参数
START_2:                        ;开始判断按键
    CMP AL,0AH                  ;如果输入A
    JNZ START_OTHER             ;若果不是A跳转到执行
    XOR bFirst,1                ;启停步进电机
    CMP bFirst,0                ;判断是启动还是停止步进电机
    JNZ StopNEXT                ;bFirst=1，跳转到StopNEXT
StartNEXT:                      ;bFirst=0，启动步进电机
    CALL Getbuffer65            ;设置SetCount
    CMP buffer+7,0BH            ;如果是功能B
    JZ BC                       ;跳转到BC，设置步速
    CMP buffer+7,0CH            ;如果是功能C
    JZ BC                       ;跳转到BC，设置步速
DE:                             ;功能DE，设置步数	
    MOV AL,SetCount             ;AL <-- SetCount
    MOV BL,10                   ;BL <-- 10
    MUL BL                      ;设置步数为10*SetCount
    MOV StepDec,AX              ;再将步数送给StepDec(即输入99，设置步数为990步)
    CMP StepDec,0               ;若初始设置为0
    JZ  START_1                 ;跳转到开始继续等待按键
    JMP Exec1                   ;否则开中断
BC:                             ;功能BC，设置步速
    MOV StepDec,-1              ;清除步数
    CALL SetJiShu               ;调用子程序设置8253计数值
    CALL INIT8253               ;设置新的速度         
Exec1:                          ;开始启动步进电机 
    MOV DONE,0                  ;D,E功能下，中断结束标志位清零
    STI                         ;开中断
    CMP DONE,1                  ;判断中断是否结束
    JNZ START_1                 ;没有结束跳转到开始继续扫描按键等待
StopNEXT:                       ;bFirst=1，停止步进电机
    CLI                         ;关中断  
    MOV bFirst,1                ;再赋给bFirst一次值
    JMP START_1                 ;跳转到开始继续扫描按键
START_OTHER:                    ;如果输入0~9或B~F 
    CMP AL,0FH                  ;如果输入F
    JZ F                        ;跳转到F使步进电机停机
    CMP bFirst,1		        ;判断电机当前状态
    JZ SHURU                    ;电机处于停机状态，则跳转设置0~9，B~E
    JMP Exec1			        ;电机处于启动状态，则除A,F按键外其他按键不能进行操作
SHURU:
    CMP AL,9                    ;如果输入0~9
    JA START_BCDE               ;将键值送入buffer+6和buffer+5，即步数/步速
    MOV AH,buffer+5             ;根据输入的键值从右到左进行步速/步数更新
    MOV buffer+6,AH
    MOV buffer+5,AL
    CALL DELAY1                 ;调用延时子程序：防止按键输入过快
    JMP START_1                 ;否则跳转显示刚才设置的数据或命令,然后继续等待按键
START_BCDE:                     ;如果输入B,C,D,E
    MOV buffer+7,AL             ;将B,C,D,E的功能键值送入buffer+7
    CMP AL,0BH                  ;如果输入B
    JZ BD                       ;跳转到BD，设置转动方向（顺时针）
    CMP AL,0DH                  ;如果输入D
    JZ BD                       ;跳转到BD，设置转动方向（顺时针） 
    MOV bClockwise,0            ;否则为功能CE，设置转动方向为逆时针
    JMP START_1
BD:                             ;功能BD，设置为顺时针
    MOV bClockwise,1
    JMP START_1                 ;跳转到开始继续扫描按键等待
F:                              ;F--->程序结束
    CLI                         ;关中断
    CALL HltFunction            ;调用停机显示‘F’子程序
    HLT                         ;停机
;------------------------------------------------------------------
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
;------------------------------------------------------------------
;子程序名：SetJiShu
;功能：设置8253计数值得到不同的频率
;入口参数：SetCount
;出口参数：JuShu，SpeedNumber
;影响寄存器：AX,BX
SetJiShu PROC NEAR
    PUSH AX                     ;保护现场
    PUSH BX
    INC SetCount                ;输入0对应1级速度，以此类推
    MOV AL,SetCount             ;保存速度级数到SpeedNumber
    MOV SpeedNumber,AL
    MOV AL,101                  ;根据速度级数通过5000+100*(101-级数)计算8253计数值
    SUB AL,SetCount
    MOV BL,100
    MUL BL
    ADD AX,5000
    MOV JiShu,AX                ;将计数值传给JiShu
    POP BX                      ;恢复现场
    POP AX  
    RET
SetJiShu ENDP
;------------------------------------------------------------------
;子程序名：INITMOTOR
;功能：步进电机模块初始化+BUFFER初始化
INITMOTOR PROC NEAR
    MOV bFirst,1                ;初始步进电机初始停止状态
    MOV BL,StyleMove            ;将偏移量送入StyleMove
    MOV AL,[ControlStyle+BX]
    MOV StepControl,AL          ;初始下一次送给步进电机的值
    ;MOV buffer,0                ;初始化显示D990.0000
    ;MOV buffer+1,0
    ;MOV buffer+2,0
    ;MOV buffer+3,0              ;初始显示步数为0.0000
    ;MOV buffer+4,10H
    ;MOV buffer+5,9              ;初始步数为990
    ;MOV buffer+6,9
    ;MOV buffer+7,0DH            ;初始为D##
    CMP buffer+7,0BH            ;根据buffer+7的命令初始化电机转动方向
    JZ BDinit
    CMP buffer+7,0DH
    JZ BDinit
    MOV bClockwise,0
BDinit:
    MOV bClockwise,1
    RET
INITMOTOR ENDP
;------------------------------------------------------------------
;子程序名：AlterStep
;功能：步进电机的步数调整
;入口参数：步数（buffer低4位）数组首地址BX，步数位数CX
;出口参数：buffer低4位
;影响寄存器：BX,CX
;问题修改：处理特殊数字跳转及设置9999反转
AlterStep PROC
    PUSH CX                         ;保护现场
    PUSH BX
    CALL StepCountSet               ;获取显示屏当前步数
    MOV CX,4                        ;设置步数位数
    LEA BX,buffer                   ;数组首地址
    CMP bClockwise,1                ;判断正/反转
    JZ ClockwiseSet
AntiClockwiseSet:                   ;反转设置
    CMP BYTE PTR[BX+4],11H          ;判断步数是正是负
    JZ AddStep                      ;步数为负，+1
    CMP StepCount,0                 ;步数为0.0000
    JNZ AntiClockwiseSet1
    MOV BYTE PTR[BX+4],11H
    INC BYTE PTR[BX]                ;则步数变为-.0001
    JMP AlterStep1
AntiClockwiseSet1:
    JMP SubStep                     ;步数为正，-1
ClockwiseSet:                       ;正转设置
    CMP BYTE PTR[BX+4],10H          ;判断步数是正是负
    JZ AddStep                      ;步数为正，+1
    CMP StepCount,1                 ;步数是否为-.0001
    JNZ ClockwiseSet1
    MOV BYTE PTR[BX+4],10H
    DEC BYTE PTR[BX]                ;步数变为0.0000
    JMP AlterStep1
ClockwiseSet1:
    JMP SubStep                     ;步数为负，-1
AddStep:
    INC BYTE PTR [BX]               ;步数+1
    CMP BYTE PTR [BX],0AH           ;低位是否产生进位
    JNZ AlterStep1                  ;无进位，则退出
    MOV BYTE PTR [BX],0             ;有进位，处理进位
    INC BX
    LOOP AddStep
    SUB BX,4
    MOV CX,4                        ;四位都有进位则达到最大值
AddStep1:                           ;设置最大值0.9999
    MOV BYTE PTR [BX],9
    INC BX
    LOOP AddStep1
    XOR bClockwise,1                ;步数>9999,使电机反转
    CMP BUFFER+7,0BH                ;同时修改转动方式
    JZ BD_fanzhuan
    CMP BUFFER+7,0DH
    JZ BD_fanzhuan
    DEC BUFFER+7
    JMP AlterStep1
BD_fanzhuan:
    INC BUFFER+7 
    JMP AlterStep1
SubStep:
    DEC BYTE PTR [BX]               ;步数-1
    CMP BYTE PTR [BX],0FFH          ;低位是否产生借位
    JNZ AlterStep1                  ;无借位，则退出
    MOV BYTE PTR [BX],9             ;有借位，处理借位
    INC BX
    LOOP SubStep
AlterStep1:
    POP BX                          ;恢复现场
    POP CX
    RET
AlterStep ENDP
;------------------------------------------------------------------
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
    INC BX
    CMP BX,10                 ;相位值循环(偏移量DI增加)
    JNZ SCNEXT
    MOV BX,9
    JNZ SCNEXT
DSClockwise:                  ;如果是正转，选择数组上一个值送入StepControl
    DEC BX
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
;-----------------------------------------------------------------
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
;------------------------------------------------------------------
;子程序名：INIT8253
;功能：8253初始化
INIT8253 PROC NEAR
    MOV DX,PORT8253_K
    MOV AL,34H              ;00110100计数器0，方式2，二进制计数
    OUT DX,AL
    MOV DX,PORT8253_0
    MOV AX,JiShu            ;10000+50*(101-n)
    OUT DX,AL
    MOV AL,AH
    OUT DX,AL
    RET
INIT8253 ENDP
;------------------------------------------------------------------
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
;-------------------------------------------------------------------
;子程序名：[INIT8251]
;功能：8251初始化
INIT8251 PROC NEAR
    ;--------软复位----------
    MOV CX,3                ;
    XOR AL,AL               ;
    MOV DX,PORT8251_1       ;
AGA:OUT DX,AL               ;连续写入3个00H
    CALL DELAY0              ;每次写入后延时一定的时间
    LOOP AGA                ;
    MOV AL,40H              ;
    OUT DX,AL               ;写入40H
    CALL DELAY0      
    ;------8251初始化--------
    MOV AL,4EH              ;01001110B设置方式字【异步×16，数据位8位，不带奇偶校验位，1位停止位】
    OUT DX,AL               ;
    CALL DELAY0
    MOV AL,16H              ;00010110H设置控制字【清除错误标志，允许接收，数据终端准备好】
    OUT DX,AL               ;
    RET
INIT8251 ENDP
;------------------------------------------------------------------
;子程序名：[INTERRUPT_VECTOR]
;功能：中断向量表初始化
;入口参数：子程序TIMERO
;影响寄存器：ES,AX,BX
INTERRUPT_VECTOR PROC NEAR
	PUSH ES
	PUSH AX
	PUSH BX
	MOV AX,0
	MOV ES,AX
	MOV BX,08H*4		    ;BX<-中断向量地址
	MOV AX,OFFSET TIMERO        ;中断子程序地址
	MOV ES:[BX],AX		    ;存放偏移地址
	MOV AX,SEG TIMERO
	MOV ES:[BX+2],AX	    ;存放段地址
	POP BX
	POP AX
	POP ES
	RET
INTERRUPT_VECTOR ENDP
;------------------------------------------------------------------
;子程序名：DELAY0
;功能：延时子程序：延时使多位数码管同时显示
;影响寄存器：CX
DELAY0 PROC NEAR
	PUSH CX
	MOV CX,500
        LOOP $
 	POP CX
 	RET
DELAY0 ENDP
;------------------------------------------------------------------
;子程序名：DELAY1
;功能：延时子程序：延时用于防止输入数字时过快
;影响寄存器：CX
DELAY1 PROC NEAR
	PUSH CX
	MOV CX,25000
    LOOP $
 	POP CX
	RET
DELAY1 ENDP
;------------------------------------------------------------------
;子程序名：DELAY2
;功能：延时子程序：用于扫描按键时按键消抖
;影响寄存器：CX
DELAY2 PROC NEAR
	PUSH CX
	MOV CX,10
	LOOP $
	POP CX
	RET
DELAY2 ENDP
;------------------------------------------------------------------
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
;------------------------------------------------------------------
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
;------------------------------------------------------------------
;子程序名：[LED_DISPLAY]
;功能：数码管显示子程序
;入口参数： BITCODE=位码值
;          SEGTAB=段码值
;          BUFFER=需显示数据缓存区
;影响寄存器：AX,CX,DX,SI
;调用子程序：DELAY0
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
;------------------------------------------------------------------
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
;------------------------------------------------------------------
;子程序名：【TRANSLATE】
;功能：列行码转换为键值
;入口参数：AX=扫描到的按键的列行码
;         KEYVALUE=键值表
;         KEYCODE=列行码表
;影响寄存器：CX,SI,DI
TRANSLATE PROC NEAR
	PUSH CX
	PUSH SI
	PUSH DI             ;保护寄存器
	MOV CX,16		    ;16个按键，设置循环次数
	LEA SI,KEYVALUE-1	;初始化键值表地址
	LEA DI,KEYCODE-2	;初始化列行码表地址
SCANTAB:
    INC SI			    ;用SCANKEY子程序返回的列行码查表
	ADD DI,2		    ;修改指针
	CMP AX,[DI]		    ;比较查找按键
	LOOPNZ SCANTAB		;ZF=1 或 CX=0则退出循环
	JNZ QUIT		    ;ZF=0则结束
	MOV AL,[SI]		    ;得到键值
QUIT:
    POP DI              ;恢复寄存器
	POP SI
	POP CX
	RET
TRANSLATE ENDP
;------------------------------------------------------------------
;子程序名：【SetStyleMove】
;功能：设置电机转动方式
;入口参数：开关量
;出口参数：StyleMove=电机转动方式
;影响寄存器：CX,SI,DI
SetStyleMove PROC
	PUSH AX
	PUSH DX
	MOV DX,PORT8255_C	
	IN AL,DX		    ;读取8255C端口
	SHR AL,1
	SHR AL,1            ;逻辑右移两位
	AND AL,3            ;使PC3PC2有效即得到输入的开关量
	MOV StyleMove,AL    ;开关量存入表示电机转动方式的变量StyleMove
	POP DX
	POP AX
	RET
SetStyleMove ENDP
;-------------------------------------------------------------------
;子程序名：RECEIVE8251
;功能：接收初始数据子程序
;影响变量：BUFFER
;影响寄存器：BX,AX,DX
RECEIVE8251 PROC
    PUSH BX
    PUSH AX
    PUSH DX
    LEA BX,BUFFER            ;设置接收数据块地址指针
    MOV CX,8                ;设置计数器初值
    ;------接收数据----------
RECEIVE:
    MOV DX,PORT8251_1       ;
    IN AL,DX                ;
    TEST AL,02H             ;查询RxRDY有效否？
    JZ RECEIVE              ;RxRDY=0，无效则等待
    MOV DX,PORT8251_0       ;
    IN AL,DX                ;RxRDY=1，读入数据
    MOV [BX],AL             ;保存数据
    INC BX                  ;修改地址指针
    LOOP RECEIVE            ;循环
    POP DX
    POP AX
    POP BX
    RET
RECEIVE8251 ENDP
    END START