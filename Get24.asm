DATA SEGMENT
    PLAYTIME DW 0               ;记录用户输入的游戏时间
    TIMEINPUT DB 6,?,6 DUP(?)   ;输入倒计时秒数，限制字符串长度为5，和1个回车符
    STARTTIME DB 0              ;记录开始游戏时的系统时间
    TIMEPROMPT DB 0AH,0DH,'Please input a number(<65535 seconds) to set the game timeout,input "0" to exit:','$' 
    STARTPROMPT DB 0AH,0DH,'Game is on!','$'
    
    CURRENTITEM DB 16 DUP(?)                ;当前的数字组合及答案内容，比如‘1118(1+(1+1))*8$’
    FILEPATH DB 'C:\PROJECT\ANSWERS.TXT'    ;TODO: 改为相对路径
    ANSWERS DB 7920 DUP(?)                  ;共有495条数据，每条数据占16字节
DATA ENDS

STACK SEGMENT
    DB 20H DUP(0)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE,DS:DATA,SS:STACK
    
START:  MOV AX, DATA
        MOV DS, AX
        MOV ES, AX
        
        MOV AH, 3DH         ;读取磁盘文件，获得所有的数字组合和答案
        LEA DX, FILEPATH
        MOV AL, 2
        INT 21H
        
        LEA DX, ANSWERS
        MOV BX, AX
        MOV CX, 7920
        MOV AH, 3FH
        INT 21H

GETTIME:LEA DX, TIMEPROMPT  ;提示输入游戏时间
        MOV AH, 09H
        INT 21H
        CALL CRLF           ;回车换行
        
        LEA DX, TIMEINPUT   ;获取用户输入的秒数（字符串）
        MOV AH, 0AH
        INT 21H
        
        MOV CL, (TIMEINPUT + 1) ;字符串长度，即循环次数
        LEA DI, (TIMEINPUT + 2) ;存放数据的字符串首地址
        MOV AH, 0
        MOV BX, 0
TRANS:  MOV AX, 10
        MOV DL, [DI]    ;得到数字的ASCII码
        SUB DL, 30H     ;得到数值
        CMP DL, 9       ;如果转成的数字大于9或小于0跳转到开始的地方（利用无符号减法溢出，不需判断是否小于0）
        JA GETTIME
        ADD BL, DL
        CMP CL, 1       ;如果是最后一个数字，则不再运行下面的乘10运算，直接结束转换
        JE SETTIME
        MUL BX
        MOV BX, AX
        INC DI
        LOOP TRANS
        
SETTIME:MOV AX, BX
        LEA BX, PLAYTIME
        MOV [BX], AX
        
        CMP AX, 0       ;输入倒计时秒数如果为0，则退出游戏
        JE EXIT
        
        CALL RAND               ;获取一个0~494的随机数，存放在BX
        MOV AX, 16              ;每个数据占16字节
        MUL BX                  ;随机数乘以16得到某一条随机结果的首地址
        LEA DI, CURRENTITEM     ;将目标偏移地址送DI
        ADD AX, OFFSET ANSWERS  ;将存放所有题目答案的偏移地址加上随机产生的偏移地址，送AX
        MOV SI, AX              ;将源地址送SI
        MOV CX, 16              ;每条数据16字节，所以重复16次
        CLD
        REP MOVSB               ;将随机抽取的题目字符串存放到CURRENTITEM
        
        
        
        
EXIT:   MOV AX, 4C00H   ;返回到DOS
        INT 21H

        
CRLF PROC               ;打印回车换行的子程序
    PUSH DX
    PUSH AX
    MOV DL, 0AH
    MOV AH, 02H
    INT 21H
    MOV DL, 0DH
    MOV AH, 02H
    INT 21H
    POP AX
    POP DX
    RET
CRLF ENDP
    
RAND PROC               ;随机数子程序，虽然一共有65536个数字，除以495的余数概率并不相等，但差异小于0.1%，忽略不计
    PUSH CX
    PUSH DX
    PUSH AX
    STI
    MOV AX, 0           ;读时钟计数器值
    INT 1AH
    MOV AX, DX            
    MOV CX, 495         ;除495，产生0~494余数
    MOV DX, 0
    DIV CX
    MOV BX, DX          ;余数存BX，作随机数
       
    POP AX
    POP DX
    POP CX
    RET
RAND ENDP
CODE ENDS
    END START