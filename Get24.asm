DATA SEGMENT
COUNTDOWN DW 0
TIMEINPUT DB 6,?,6 DUP(?);输入倒计时秒数，限制字符串长度为3，和1个回车符
STARTTIME DB 0
TIMEPROMPT DB 0AH,0DH,'Please input a number(<65535 seconds) to set the game timeout,input "0" to exit:','$'
RANDOMNUM DB 0,0,0,0
STARTPROMPT DB 0AH,0DH,'Game is on!','$'
DATA ENDS

STACK SEGMENT
    DB 20H DUP(0)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE,DS:DATA,SS:STACK
    
START:  MOV AX, DATA
        MOV DS, AX
        
        MOV DX, OFFSET TIMEPROMPT ;提示输入游戏时间
        MOV AH, 09H
        INT 21H
        CALL CRLF ;回车换行
        
        MOV DX, OFFSET TIMEINPUT ;获取用户输入的秒数（字符串）
        MOV AH, 0AH
        INT 21H
        
        MOV CL, (TIMEINPUT + 1) ;字符串长度，即循环次数
        MOV DI, OFFSET (TIMEINPUT + 2) ;存放数据的字符串首地址
        MOV AH, 0
TRANS:  MOV AX, 10
        MOV DL, [DI] ;得到数字的ASCII码
        SUB DL, 30H ;得到数值
        CMP DL, 9 ;如果转成的数字大于9或小于0跳转到开始的地方（利用无符号减法溢出，不需判断是否小于0）
        JA START
        ADD BL, DL
        CMP CL, 1 ;如果是最后一个数字，则不再运行下面的乘10运算，直接结束转换
        JE SETCOUNT
        MUL BX
        MOV BX, AX
        INC DI
        LOOP TRANS
        
SETCOUNT:MOV AX, BX
        MOV BX, OFFSET COUNTDOWN
        MOV [BX], AX
        
        CMP [COUNTDOWN], 0 ;输入倒计时秒数如果为0，则退出游戏
        JE EXIT
        
        
        
        
        
EXIT:   MOV AX, 4C00H ;返回到DOS
        INT 21H

        
CRLF PROC NEAR ;打印回车换行的子程序
    MOV DL, 0AH
    MOV AH, 02H
    INT 21H
    MOV DL, 0DH
    MOV AH, 02H
    INT 21H
    RET
CRLF ENDP
    


CODE ENDS
    END START