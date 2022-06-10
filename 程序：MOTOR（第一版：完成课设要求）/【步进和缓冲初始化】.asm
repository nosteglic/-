;-------------------------------------------------------------------
;子程序名：INITMOTOR
;功能：步进电机模块初始化+BUFFER初始化
INITMOTOR PROC NEAR
    MOV bFirst,1                        ;初始步进电机初始停止状态
    MOV BL,StyleMove                    ;将偏移量送入StyleMove
    MOV AL,[ControlStyle+BX]
    MOV StepControl,AL                  ;初始下一次送给步进电机的值
    MOV buffer,0                        ;初始化显示D990.0000
    MOV buffer+1,0
    MOV buffer+2,0
    MOV buffer+3,0                      ;初始显示步数为0.0000
    MOV buffer+4,10H
    MOV buffer+5,9                      ;初始步数为990
    MOV buffer+6,9
    MOV buffer+7,0DH                    ;初始为D##
    CMP buffer+7,0BH                    ;根据buffer+7的命令初始化电机转动方向
    JZ BDinit
    CMP buffer+7,0DH
    JZ BDinit
    MOV bClockwise,0
BDinit:
    MOV bClockwise,1
    RET
INITMOTOR ENDP