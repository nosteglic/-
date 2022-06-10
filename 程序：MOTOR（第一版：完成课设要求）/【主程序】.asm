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
.STACK 100
.DATA
    BITCODE   	    DB      ?                       ;存放位码值
    SEGTAB          DB      0C0H,0F9H,0A4H,0B0H,99H,92H,82H,0F8H,80H,90H, 88H,83H,0C6H,0A1H,86H,8EH,40H,3FH         ;段码->LED灯编码（0~F+"0."+"-."）
    KEYVALUE        DB      00H,01H,02H,03H,04H,05H,06H,07H,08H,09H,0AH,0BH,0CH,0DH,0EH,0FH                         ;键值表 +【10H -> "0."】+【11H -> "-."】
    KEYCODE         DW      0FE02H,0FD02H,0FB02H,0F702H,0EF02H,0DF02H,0BF02H,7F02H,0FE01H,0FD01H,0FB01H,0F701H,0EF01H,0DF01H,0BF01H,7F01H   ;键盘列行码
    BUFFER          DB      8 DUP(?)                ;数码管上显示内容缓存区
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
    CALL INTERRUPT_VECTOR       ;中断向量表初始化
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