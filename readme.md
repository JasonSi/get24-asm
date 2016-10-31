# 微机原理课程设计

## 程序设计要求

汇编实现24点游戏。

提示用户输入计算的秒数playtime，系统生成4个随机数，显示: “Here are four numbers：1 2 3 4”。游戏开始倒计时：
评估用户输入的一个表达式，比如：（3+5）\*（2+1）

并解析表达式，计算数值，如果等于24 并且游戏时间 < playtime

显示：“Great！ You win the game!”

否则： 如果表达式不正确，显示：“Wrong Solution”！， 如果游戏时间< playtime, 则提示用户继续输入表达式

如果游戏时间> playtime， 程序结束，显示：“Sorry, you lost the game！”

## 设计思路

### 出题方式

如果采用随机生成四个数字，可能会得到无解的题目，而如果要判断是否无解，需要跑遍所有的可能计算组合情况，算法本身并不是很复杂，但用汇编写起来比较头疼，而且每次都要跑一遍，效率也不是很好。所以我计算了一下所有的组合，发现一共有495种情况：

1. 四个数字都不相同（比如1234）：C9(4) = 126
2. 四个数字都相同（比如1111）：C9(1) = 9
3. 四个数字中，只有两个不同数字（比如1222，1122）： C9(2)\*C2(1) + C9(2) = 108
4. 四个数字中，只有三个不同的数字（比如1233）：C9(3) * C3(1) = 252

于是打算采用牺牲空间换取时间的策略，使用查表的方式出题，这样即可避免过于复杂的判断逻辑。

从网上找到了一个1~10四个数字计算的所有组合以及答案，即[origin_answers.txt](origin_answers.txt)，但其中包含10这个数字的题目不是我需要的，所以要排除所有含10的题目。而且为了更方便汇编解析以及节省内存，就用Ruby语言写了一个小脚本处理文件，即[transfer.rb](transfer.rb)。运行后得到[answers.txt](answers.txt)文件，其中包含了495个题目和参考答案，每个题目占16个字节，分别由题目4个字节和答案11个字节，以及一个“$”结尾组成。这样设计格式的原因有：

1. 刚好每个题目有16个字节，设计程序和debug的时候更方便。
2. 固定格式，保证前4个字节是题目，方便提取。
3. 第5个字节到第11个字节是答案，刚好两对括号，四个数字和三个运算符。
4. 如果无解，答案部分全部存为0，程序判断的时候只需要判断答案部分第一个字符是否为“0”即可。
5. 最后以“$”结尾，可以在给玩家输出参考答案的时候直接输出。

出题的方式就是产生一个0~494的随机数，乘以16字节，加上存放该部分的偏移地址，即可找到目标题目的首地址。

### 随机数生成原理

从时钟滴答中获取一个16位数，直接除以495，将余数放到BX后返回到主函数。

实际上直接除以495是产生了不完全公平的随机数，因为一共有65536个数字，并不是495的整倍数。根据计算得知，产生的随机数，在0~194范围内的概率要略大于在195~494中的概率。不过再进一步计算，可以得知它们的概率极差仅有1/65536，用1/65536除以概率132/65536得到相对误差为1/132，不到1%，几乎是可以忽略的，所以这里就没有再精确地纠正它。

### 计时原理

1. 游戏开始的时候获取当时的系统时间，格式为时分秒，三个字节的BCD码，通过转码将其转为二进制存入内存。
2. 玩家每次输入他的解法后，再次获取当时系统时间，存入另一个变量。
3. 将两个时间相减，得到已经用的时间，和游戏开始前玩家设定的PLAYTIME进行比较，如果大于则超时，显示玩家失败以及题目参考答案，否则继续判断表达式等正常流程。

时间并不能直接相减，具体算法思路如下：

1. 将HOUR相减，得到的数如果大于24则表示溢出，可能跨过了午夜，手动加上24，得到真实的HOUR差值。
2. 如果HOUR差值为0，则DX为0，继续判断分钟；如果HOUR差值为1，则DX为3600，继续判断分钟；否则直接判定超时（因为游戏时间规定了不能超过3600秒）。
3. 计算MINUTE差值，结果乘以60，加上DX，结果存入DX。
4. 计算SECOND差值，结果加上DX，存入DX。
5. 最后得到的DX即为玩家已游戏的时间，单位是秒。

### 游戏逻辑

1. 载入题目到内存
2. 询问玩家设定游戏时间，如果为0则退出，如果含有非数字字符则要求重新输入，其他则继续
3. 玩家设定游戏时间后，产生一个随机数，抽取一道题目
4. 将题目显示出来，并记录当前系统时间
5. 提示玩家输入计算方案，如果为0表示无解，否则进一步判断
6. 将其转换为后缀表达式，如果格式错误，则提示重新输入，否则进一步判断
7. 将其中的数字抽取出来和题目所给数字匹配，如果不是完全匹配，则提示重新输入，否则进一步判断
8. 将后缀表达式进行计算，得到结果如果不是24，则提示答案错误，要求重新输入，否则游戏胜利
9. 游戏时间结束导致失败或者回答正确游戏胜利后跳转到第2步

其中答题期间每次输出提示信息前都会判断是否超时，超时则直接给出提示并跳转到第2步。


## 核心代码

参考[Get24.asm](Get24.asm)

## 体会与收获

真的学会了中缀表达式和后缀表达式的转换逻辑。
