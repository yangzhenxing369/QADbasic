#!/bin/ksh
. jset 1.6

#设置环境变量，当前目录加入 PYTHONPATH 环境变量。
export  PYTHONPATH=$PYTHONPATH:.

#变量定义
FILE="$HOME/ca.init"
FOLD="costaccounting/sprintSummary/sprint1Summary/CRMFG31/"
OUTPUT="output.txt"

# 变量FILE的值 是否表示一个文件 "$"+变量名，引用变量
if [ -f $FILE ];
then
	#读取文件中的每行数据
    cat $FILE | while read LINE
    do
        FOLD=$LINE
    done
fi

echo "Current run path: $FOLD, use it?(Y/n)"

#从标准输入中 读入用户输入的一行，并赋值到一个变量
read USE_DEFAULT
if [[ $USE_DEFAULT = 'N'  || $USE_DEFAULT = 'n' ]];
then
    echo "Pls input the path:"

    #从标准输入中 读入用户输入的一行，并赋值到一个变量
    read FOLD
fi


#将变量$FOLD的值 写入到 $FILE 代表的文件，覆盖式。
echo $FOLD > $FILE


if [ -f $OUTPUT ];
then
    rm $OUTPUT
fi

# 后三个是参数
python concordion_folder_runner -o output/$FOLD specs/$FOLD

if [ -f batch.txt ];
then
    rm batch.txt
fi
