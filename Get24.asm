DATA SEGMENT
    PLAYTIME DW 0               ;记录玩家输入的游戏时间
    TIMEINPUT DB 5,?,5 DUP(0)   ;输入倒计时秒数，限制字符串长度为4，和1个回车符
    STARTTIME DB 3 DUP(0)       ;记录开始游戏时的系统时间（时：分：秒）
    NOWTIME DB 3 DUP(0)         ;记录当前系统时间
    TIMEPROMPT DB 0AH,0DH,0AH,0DH,'Please input a number(<3600 seconds) to set the play time, input "0" to exit:',0AH,0DH,'$' 
    STARTPROMPT DB 0AH,0DH,'Game is on! Here are four numbers ','$'
    
    CURRENTITEM DB 16 DUP(?)    ;当前的数字组合及答案内容，比如‘1118(1+(1+1))*8$’
    CURRENTNUM DB 4 DUP(?),'$'
    NUMBUFFER DB 4 DUP(?),'$'
    FILEPATH DB 'ANSWERS.TXT'
    ANSWERS DB 7920 DUP(?)      ;共有495条数据，每条数据占16字节
    
    INPUTPROMPT DB 0AH,0DH,'Input your solution, input "0" means no answer: ',0AH,0DH,'$'
    EXPRESSION DB 20,?,20 DUP(0)    ;存储玩家输入的表达式
    SUFFIXEXP DB 20 DUP(0),'$'          ;存储转换后的后缀表达式
    
    WRONGANSWER DB 0AH,0DH,'Wrong Solution!','$'
    ILLEGALFORMAT DB 0AH,0DH,'The format of your expression is illegal :-(','$'
    ILLEGALDIGIT DB 0AH,0DH,'Can not use numbers like this :-(','$'
    WINPROMPT DB 0AH,0DH,'Yeah! You win the game!',0AH,0DH,'$'
    
    LOSTPROMPT DB 0AH,0DH,'Sorry, you lost the game!','$'
    NOANSWERPROMPT DB 0AH,0DH,'There is no answer for this question.','$'
    ANSWERPROMPT DB 0AH,0DH,'A reference answer of this question is:','$'
DATA ENDS

STACK SEGMENT
    DB 100 DUP(0)
STACK ENDS

CODE SEGMENT
    ASSUME CS:CODE,DS:DATA,SS:STACK
    
START:  MOV AX, DATA
        MOV DS, AX
        MOV ES, AX
        MOV AX, STACK
        MOV SS, AX
        
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
        
        CALL CLEARTIME      ;清理玩家输入的时间缓存区
        
        LEA DX, TIMEINPUT   ;获取玩家输入的秒数（字符串）
        MOV AH, 0AH
        INT 21H
        
        MOV CL, (TIMEINPUT + 1) ;字符串长度，即循环次数
        LEA DI, (TIMEINPUT + 2) ;存放数据的字符串首地址
        MOV AX, 0
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
        
        CMP AX, 0               ;输入倒计时秒数如果为0，则退出游戏
        JE EXIT
        CMP AX, 3600
        JG GETTIME
        
        CALL RAND               ;获取一个0~494的随机数，存放在BX
        MOV AX, 16              ;每个数据占16字节
        MUL BX                  ;随机数乘以16得到某一条随机结果的首地址
        LEA DI, CURRENTITEM     ;将目标偏移地址送DI
        ADD AX, OFFSET ANSWERS  ;将存放所有题目答案的偏移地址加上随机产生的偏移地址，送AX
        MOV SI, AX              ;将源地址送SI
        MOV CX, 16              ;每条数据16字节，所以重复16次
        CLD
        REP MOVSB               ;将随机抽取的题目字符串存放到CURRENTITEM
        LEA DI, CURRENTNUM      ;将数字部分放到CURRENTNUM
        LEA SI, CURRENTITEM
        MOV CX, 4
        CLD
        REP MOVSB
        
        LEA DX, STARTPROMPT     ;游戏开始，输出提示
        MOV AH, 09H
        INT 21H
        LEA DX, CURRENTNUM      ;输出游戏的四个数字
        MOV AH, 09H
        INT 21H
        
        CALL SETSTARTTIME       ;记录游戏开始时的系统时间
        
TRY:    MOV AX, 0
        MOV BX, 0
        LEA DX, INPUTPROMPT     ;提示玩家输入表达式
        MOV AH, 09H
        INT 21H
        
        CALL CLEAREXP           ;清理缓冲区
       
        LEA DX, EXPRESSION      ;获取玩家输入的表达式
        MOV AH, 0AH
        INT 21H
        
        CALL ISINTIME
        CMP BX, 1
        JNE LOST
        
        MOV AL, (EXPRESSION + 2)
        CMP AL, '0'                 ;如果输入的表达式第一个字符是‘0’，则认为玩家回答“无解”
        JNE CHECK                   ;如果不是‘0’，则认为玩家输入了四则表达式
        MOV AL, (CURRENTITEM + 4)   ;获取当前题目的答案的第一个字符送AL
        CMP AL, '0'                 ;与‘0’比较，如果相等，则表示回答正确，答案是‘无解’
        JE WIN                      ;赢了则可以直接跳转胜利，否则输出错误并跳转到TRY
        LEA DX, WRONGANSWER         ;提示玩家回答错误
        MOV AH, 09H
        INT 21H
        JMP TRY
        
LOST:   LEA DX, LOSTPROMPT
        MOV AH, 09H
        INT 21H
        CALL SHOWANSWER 
        JMP GETTIME

CHECK:  CALL CHECKEXP               ;先检查是否有连续数字或运算符，比如23+3或者2+-4等情况
        CMP BX, 1                   ;根据返回值，如果CHECKEXP正确，则继续格式化，即FORMAT
        JE FORMAT
        LEA DX, ILLEGALFORMAT       ;提示玩家表达式格式错误
        MOV AH, 09H
        INT 21H
        JMP TRY
        
FORMAT: CALL TOSUFFIX               ;返回值BX 存1或0，0表示表达式不符合规范
        CMP BX, 1                   ;根据返回值，如果转换后缀表达式结果正确，则匹配数字是否符合要求
        JE MATCH
        LEA DX, ILLEGALFORMAT       ;提示玩家表达式格式错误
        MOV AH, 09H
        INT 21H
        JMP TRY

MATCH:  CALL ISMATCH                ;检测玩家输入的表达式中数字是否与题目完全匹配
        CMP BX, 1                   ;根据返回值，如果数字匹配，则表达式合法，开始计算
        JE CALC
        LEA DX, ILLEGALDIGIT        ;提示玩家表达式中的数字非法
        MOV AH, 09H
        INT 21H
        JMP TRY
        
        
CALC:   CALL CALCULATE              ;计算玩家输入的表达式
        CMP BX, 24                  ;如果结果正确是24，则表示输入正确，赢得比赛
        JE WIN
        LEA DX, WRONGANSWER         ;提示玩家回答错误
        MOV AH, 09H
        INT 21H
        JMP TRY
        
WIN:    LEA DX, WINPROMPT
        MOV AH, 09H
        INT 21H
        JMP GETTIME
        
        
EXIT:   MOV AX, 4C00H   ;返回到DOS
        INT 21H


    
RAND PROC               ;随机数子程序，虽然一共有65536个数字，除以495的余数概率并不完全相等，但差异小于0.1%，忽略不计
        PUSH CX
        PUSH DX
        PUSH AX
        STI
        MOV AX, 0       ;读时钟滴答数
        INT 1AH
        MOV AX, DX            
        MOV CX, 495     ;除495，产生0~494余数
        MOV DX, 0
        DIV CX
        MOV BX, DX      ;余数存BX，作随机数
           
        POP AX
        POP DX
        POP CX
        RET
RAND ENDP

CHECKEXP PROC       ;这个子程序用来检测表达式是否有连续数字或运算符，通过置AH为1或0来记录状态，更详细的检测在TOSUFFIX中
        PUSH AX
        PUSH CX
        MOV AX, 0
        MOV BX, 0
        LEA DI, (EXPRESSION + 2)
        MOV CL, (EXPRESSION + 1)
CNEXT:  MOV AL, [DI]
        INC DI
        CMP AL, '9'
        JG COP
        CMP AL, '0'
        JG CNUM
        CMP AL, '+'
        JE COP
        CMP AL, '-'
        JE COP
        CMP AL, '*'
        JE COP
        CMP AL, '/'
        JE COP
        CMP AL, '('
        JE LOOPNEXT
        CMP AL, ')'
        JE LOOPNEXT
        JMP CWRONG
LOOPNEXT:LOOP CNEXT
        JMP CRIGHT
        
COP:    CMP AH, 0
        JE CWRONG
        MOV AH, 0
        DEC CL
        CMP CL, 0
        JE CWRONG
        JMP CNEXT
        
CNUM:   CMP AH, 1
        JE CWRONG
        MOV AH, 1
        DEC CL
        CMP CL, 0
        JE CRIGHT
        JMP CNEXT
 
CWRONG: POP CX
        POP AX
        MOV BX, 0
        RET
        
CRIGHT: POP CX
        POP AX
        MOV BX, 1
        RET
CHECKEXP ENDP

TOSUFFIX PROC
        PUSH AX
        PUSH CX
        MOV AX, 0
        MOV BX, 0
        MOV CX, 0
        LEA DI, (EXPRESSION + 2)
        LEA SI, SUFFIXEXP
        
READ:   MOV AL, [DI]
        CMP AL, 0DH
        JE POPALL
        INC DI
        CMP AL, '9'
        JG FAIL
        CMP AL, '0'
        JG PUSHNUM
        CMP AL, '('
        JE LPRENTH
        CMP AL, ')'
        JE RPRENTH
        
OP:     MOV BP, SP
        CMP AL, '+'
        JE L1
        CMP AL, '-'
        JE L1
        CMP AL, '/'
        JE L2
        CMP AL, '*'
        JE L2
        JMP FAIL
 
PUSHOP: PUSH AX
        INC CX
        JMP READ
        
PUSHNUM:SUB AL, 30H
        MOV [SI], AL
        INC SI
        JMP READ
        
LPRENTH:PUSH AX
        INC CX
        JMP READ

RPRENTH:CMP CX, 0       ;如果栈已经空了，则说明括号匹配不正确，退出
        JE FAIL
        POP BX
        DEC CX
        CMP BL, '('     ;如果是弹出左括号，则完成，继续读取下一个，否则继续循环
        JE READ
        MOV [SI], BL
        INC SI
        JMP RPRENTH
        
L1:     CMP BYTE PTR [BP], '+'      ;L1表示优先级1，如果是乘除将直接跳过和L1的比较
        JE POPOP
        CMP BYTE PTR [BP], '-'
        JE POPOP
L2:     CMP BYTE PTR [BP], '*'
        JE POPOP
        CMP BYTE PTR [BP], '/'
        JE POPOP
        JMP PUSHOP

POPOP:  POP BX
        DEC CX
        MOV[SI], BL
        INC SI
        JMP OP
        
POPALL: CMP CL, 0       ;如果玩家捣乱输入的表达式只有一个数字，没有可以pop的，所以加一个判断
        JE DONE
        POP AX
        MOV [SI], AL
        INC SI
        LOOP POPALL
        
        LEA DI, (SUFFIXEXP) ;遍历后缀表达式
        MOV BX, DI
        MOV CX, 20
        MOV AL, '('         ;如果发现还有左括号，则说明表达式不合法
        CLD
        REPNZ SCASB
        JZ FAIL
        
        
DONE:   POP CX          
        POP AX
        MOV BX, 1       ;转换成功则返回1
        RET
FAIL:   POP CX
        POP AX
        MOV BX, 0       ;转换失败则返回0
        RET
TOSUFFIX ENDP

ISMATCH PROC
        MOV AX, 0
        MOV BX, 0
        
        LEA DI, NUMBUFFER       ;将数字部分放到NUMBUFFER 以供后面用来MATCH数字
        LEA SI, CURRENTITEM
        MOV CX, 4
        CLD
        REP MOVSB
        
        LEA DI, SUFFIXEXP
MTLP:   MOV DL, [DI]            ;外层循环，遍历后缀表达式
        CMP DL, 0
        JE MTRIGHT
        INC DI
        CMP DL, 9
        JG MTLP
        LEA SI, NUMBUFFER
BFLP:   MOV AL, [SI]            ;内层循环，和NUMBUFFER比较
        CMP AL, '$'             ;如果扫描到了'$'，说明使用了未提供的数字，返回错误
        JE MTWRONG
        INC SI
        SUB AL, 30H             ;将ASCII转为数值，方便比较
        CMP AL, 0               ;如果为0，则跳过
        JE BFLP
        CMP AL, DL
        JNE BFLP
        MOV CL, 0               ;如果匹配到了则将NUMBUFER中对应的数置为0
        MOV [SI] - 1, CL
        JMP MTLP
        
MTWRONG:MOV BX, 0        
        RET
        
MTRIGHT:MOV BX, 1
        RET
ISMATCH ENDP

CALCULATE PROC
        MOV AX, 0
        MOV BX, 0
        MOV DX, 0
        
        LEA DI, SUFFIXEXP
CCLP:   MOV DL, [DI]
        CMP DL, 0
        JE CCDONE
        INC DI 
        CMP DL, '+'
        JE CCPLUS
        CMP DL, '-'
        JE CCMINUS
        CMP DL, '*'
        JE CCMUL
        CMP DL, '/'
        JE CCDIV
        CMP DL, 9
        JNG CCNUM
        JMP CCLP
        
CCPLUS: POP BX
        POP AX
        ADD BL, AL
        PUSH BX
        JMP CCLP

CCMINUS:POP BX
        POP AX
        SUB AL, BL
        PUSH AX
        JMP CCLP

CCMUL:  POP BX
        POP AX
        MUL BL
        MOV AH, 0
        PUSH AX
        JMP CCLP

CCDIV:  POP BX
        POP AX
        DIV BL
        MOV AH, 0
        PUSH AX
        JMP CCLP

CCNUM:  PUSH DX
        JMP CCLP
        
CCDONE: POP BX
        RET
CALCULATE ENDP

CLEAREXP PROC
        PUSH AX
        PUSH CX
        LEA DI, EXPRESSION + 2  ;将EXPRESSION缓冲区第二位以后清零
        MOV CX, 20
        CLD
        MOV AX, 0
        REP STOSB
        
        LEA DI, SUFFIXEXP       ;将SUFFIXEXP全部清零
        MOV CX, 20
        CLD
        MOV AX, 0
        REP STOSB
        
        POP CX
        POP AX
        RET
CLEAREXP ENDP

CLEARTIME PROC
        PUSH AX
        PUSH CX
        LEA DI, TIMEINPUT + 2  ;将EXPRESSION缓冲区第二位以后清零
        MOV CX, 5
        CLD
        MOV AX, 0
        REP STOSB
        
        POP CX
        POP AX
        RET
CLEARTIME ENDP

SETSTARTTIME PROC
        PUSH AX
        PUSH CX
        PUSH DX
        
        MOV AH, 02H
        INT 1AH
        LEA DI, STARTTIME
        MOV [DI], CH        ;小时的BCD码
        MOV [DI] + 1, CL    ;分钟
        MOV [DI] + 2, DH    ;秒
        
        POP DX
        POP CX
        POP AX
        RET
SETSTARTTIME ENDP

ISINTIME PROC
        PUSH AX
        PUSH CX
        PUSH DX
        
        MOV AX, 0   ;清零
        MOV BX, 0
        MOV DX, 0
        
        MOV AH, 02H
        INT 1AH
        LEA DI, NOWTIME
        MOV [DI], CH        ;小时的BCD码
        MOV [DI] + 1, CL    ;分钟
        MOV [DI] + 2, DH    ;秒

        MOV BX, 0
        POP DX
        POP CX
        POP AX
        RET        
ISINTIME ENDP

SHOWANSWER PROC
        PUSH AX

        LEA DI, CURRENTITEM + 4
        MOV AL, [DI]
        CMP AL, '0'
        JE SHOWNO
        
        LEA DX, ANSWERPROMPT    ;显示答案提示
        MOV AH, 09H
        INT 21H
        
        LEA DX, CURRENTITEM + 4 ;显示参考答案
        MOV AH, 09H
        INT 21H
        JMP SHOWDONE
        
SHOWNO: LEA DX, NOANSWERPROMPT  ;输出答案：无解
        MOV AH, 09H
        INT 21H
        JMP SHOWDONE
        
SHOWDONE:POP AX
        RET
SHOWANSWER ENDP

CODE ENDS
    END START