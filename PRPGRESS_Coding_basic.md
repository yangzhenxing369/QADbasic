PRPGRESS 4GL(PROGRESS基础)
=========================

PROGRESS语言是一种非可视化的编程语言，符合4GL规范，具有高级语言的优点，语法简单，但同时又具有很强的灵活性。

***


#### 1 常用数据类型

 数据名 | 初始格式 | 默认值
 --- | --- | --- |
 CHARACTER(C) | x(8) | “”（空值）
 DATE(DA) | 99/99/99 | ？(未知值，显示时为空)
 DECIMAL(D) | ->>,>>9.99 | 0
 HANDLE | >>>>>>9 | ?(未知值)
 INTERGER(I) | ->,>>>,>>9 | 0
 LOGICAL(L) | yes/no | no


注：未知值不能与空值比较，否则出错。简写：DEF, VAR, C, DA, D, I, L。
PROGRESS不区分大小写。在每条语句结束时要跟上句号，对于列表(list)，每个清单跟上逗号。



#### 2 比较操作符

[EQ =], [NE <>], [GT >], [LT <], [GE >=], [LE <=]
BEGINS, MATCHES (* | .), CONTAINS.
3 定义变量
3.1 DEFINE VARIABLE variable-name AS data-type | LIKE variable [INITIAL constant] [label string] [VIEW-AS widget-type] [options].
注：widget-type: FILL-IN, TEXT, SELECTION-LIST, COMBO-BOX, RADIO-SET, TOGGLE-BOX, EDITOR, SLIDER.
3.2 DEFINE BUTTON button-name LABEL string.
3.3 DEFINE RECTANGLE rectangle-name SIZE width BY height [NO-FILL] [EDGE-CHARS width]
注：SIZE-BY指定大小，适用于RECTANGLE，FRAME，EDITOR等可定义大小的widget，另外
3.4 DEFINE FRAME frame-name
form-item…
[WITH [SIDES-LABELS] [NO-BOX] [CENTERED]]
注：FRAME 默认显示为有边框，标签显示在值上方，单行显示。
4 激活
ENABLE {ALL | SKIP(N) | widget-list} [frame-phrase]
注：frame-phrase: WITH [SIDE-LABELS] [NO-BOXS] [n COLUMNS] [USE-TEXT]，WITH是从整个框架定义格式，也可以在DISPLAY中单独指定某个field的显示属性，如跟上NO-LABEL，但WITH里定义的是SIDE-LABELS，那么该field不显示label。
 
5 显示
DISPLAY {[ALL (EXPECT fields)] | widgets-list}[format-phrase] [frame-phrase]
注：format-phrase: {AT | AT ROW n COLUMN m | TO | COLON} {LABEL string | NO-LABEL} [FORMAT string] [VIEW-AS] [VALIDATE (condition, msg-expression)]. 其中AT 表示以哪为开始，TO 表示到哪结束，COLON 以冒号对齐。在fields后可以单独指定显示的格式，如可以在某field后加NO-LABEL，那么即使WITH后是SIDE-LABELS也不会显示LABEL。另外在frame-pause和format-phrase中的定义有些可通用，视情况而定。VALIDATE用法：当输入满足condition时，允许输入，不满足时提示一个警告express。
 
6 定义事件
ON event-lists OF widget-list [OR event-list OF widget-list]
注：event: ENTRY, LEAVE, GO, CHOOSE, VALUE-CHANGED, DEFAULT-ACTION(双击事件).
7 退出程序
WAIT-FOR RETURN OF widget-list [WAIT-FOR后面也跟其他事件]
注：WAIT-FOR表示当后面跟的事件发生时退出，而且只有退出后才执行WAIT-FOR后的代码。
例子：DEFINE VARIABLE months AS INTERGER EXTENT 12 LABEL
“Jan”, ”Feb”, ”Mar”, “Apr”, “May”, “June”, “July”, “Aug”, “Sep”,
“Oct”, “Nov”, “Dec” INITIAL [31,28,31,30,31,30,31,30,31,31,30,31].
DEFINE BUTTON btn-exit LABEL “Exit”.
DEFINE FRAME frame1
Months colon 11 SKIP(1)
btn-exit
WITH SIDE-LABELS NO-BOX CENTERED.
ON ENTRY OF months
DO: MESSAGE SELF:LABEL “has” SELF:SCREEN-VALUE “day” “The
cursor is in array element number” SELF:INDEX.
END.
DISPLAY months WITH FRAME frame1.
ENABLE ALL WITH FRAME frame1.
WAIT-FOR CHOOSE OF btn-exit.
注：INDEX, SCREEN-VALUE, LABEL为属性，常用属性还有CHECKED, MODIFIED, ROW, COL, WIDTH, HEIGHT，VISIBLE。EXTENT为数组，假如所给的值的个数不足时，后面的将补上与所给最后那个相同的值；MESSAGE为一函数，功能为以所给字符串为提示显示在显示器左下角。
 
8 激活与隐藏
ENABLE {[ALL | SKIP(n) | SPACE(n) | widget-list]} [frame-phrase]
DISABLE {ALL | widget-list} [frame-phrase]
VIEW {FRAME frame-name | widget-list IN FRAME frame-name}
HIDE {widget-list | MESSAGE | ALL} [NO-PAUSE]
注：NO-PAUSE表示不等待程序处理其他事务直接隐藏；在ENABLE中可以用SKIP,SPACE,但DISABLE中不能，因为ENABLE同事有显示功能。
9 程序一般格式
步骤
一般格式
带FRAME的格式
1
Define widgets
Define field-level widgets
2
Display widgets
Define frames
3
Enable widgets
Define triggers
4
Define triggers
Display widgets
5
Block execution
Enable widgets
6
 	
Block execution
7
 	
Disable user interface (end the procedure)
10 流程控制
10.1 IF expression THEN block. [ELSE block].
10.2 CASE expression:
{WHEN value [OR WHEN value] THEN [block | statement]….
[OTHERWISE [block | statement]].
END [CASE].
10.3 [label:] DO [variable=expression to expression] [WHILE expression]
[frame-phrase]:
block.
END.
10.4 [label:] REPEAT [variable=expression to expression] [WHILE expression]
[frame-phrase]:
block. [or IF expression THEN LEAVE [label].]
END.
10.5 [label:] FOR EACH [record-phrase] [variable=expression to expression] [WHILE expression] [frame-phrase]:
block.
END.
注：DO 一般用来把一组代码组在一起，类似与其他编程工具大括号{}的作用，FOR EACH自动遍历表，并自动控制，REPEAT介于DO和FOR EACH之间，能自动重复，但不能自动退出，但带了更多的自由。CASE中可比较的有字符，数字和日期。
11 调用程序
程序调用又分内部程序调用和外部程序调用，其语法格式为：
RUN procedure-name {(INPUT | OUTPUT | INPUT-OUTPUT) expression, …}
DEFINE {(INPUT | OUTPUT | INPUT-OUTPUT)} PARAMETER parameter {AS data-type | LIKE field} [format-phrase]。
被调用程序的声明有所差异：
11.1 内部调用
PRODUCE produce-name:
DEFINE INPUT PARAMETER var.
statements.
END [PRODUCE].
11.2 外部调用
name.p
DEFINE INPUT PARAMETER var.
statements.
注：调用函数如没有参数时就不用带上参数，有的时候参数的顺序和个数必须与被调用函数中一致。例：RUN proc.p (INPUT-OUTPUT var1, INPUT “constant”, OUTPUT var2)。
12 全局变量和局部变量
在PROGRESS中全局变量和局部变量同其他语言一样，这里只介绍PROGESS特有的：SHARED（作用之一是可以代替INPUT-OUTPUT功能）
DEFINE [[NEW] SHARED] VARIABLE var-name [AS | LIKE].
注：NEW定义在调用函数中，被调用函数中无，且变量名相同，例：
调用：DEFINE NEW SHARED VARIABLE field1 AS CHARACTER.
被调用：DEFINE SHARED VARIABLE field1 AS CHARACTER.
13 确认变量的输入
ASSIGN statement.如：
IF field:MODIFIED THEN ASSIGN field.
或者先定义一个变量再赋值
field = INTEGER(var1:SCREEN-VALUE) + 200.
注：运算符前后要用空格隔开
14 几个常用VIEW-AS
14.1 VIEW-AS FILL-IN [SIZE-CHARS width BY height]
14.2 VIEW-AS RADIO-SET [HORIZONTAL | VERTICAL] [size-phrase] RADIO-BUTTONS label, value [, label, value]…
14.3 VIEW-AS SELECTION-LIST [SINGLE | MULTIPLE] LIST-ITEMS item-list [DELIMITER character] [SCROLLBAR-HORIZONTAL] [SCROLLBAR-VERTICAL] {size-phrase | INNER-CHARS cols INNER-LINES rows} [SORT].
14.4 VIEW-AS EDITOR {size-phrase} [BUFFER-CHARS chars] [BUFFER-LINES lines] [MAX-CHARS chars] [SCROLLBAR-VERTICAL] [NO-WORD-WRAP [SCROLLBAR-HORIZONTAL]]
14.5 VIEW-AS COMBO-BOX [LIST-ITEMS item-list] [INNER-LINNER lines] [size-phrase] [SORT].
14.6 VIEW-AS TOGGLE-BOX [INITIAL no | yes]
注：Size-phrase: SIZE-CHARS width BY height | INNER-CHARS cols INNER-LINES rows。其中CHARS可以去掉。
注：field in FRAME frame-name | FRAME frame-name field








#### Tables

A simple table looks like this:

First Header | Second Header | Third Header
------------ | ------------- | ------------
Content Cell | Content Cell  | Content Cell
Content Cell | Content Cell  | Content Cell

