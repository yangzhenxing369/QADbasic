#!/bin/ksh
. jset 1.6
export  PYTHONPATH=$PYTHONPATH:.
FILE="$HOME/ca.init"
FOLD="costaccounting/sprintSummary/sprint1Summary/CRMFG31/"
OUTPUT="output.txt"

if [ -f $FILE ];
then
    cat $FILE | while read LINE
    do
        FOLD=$LINE
    done
fi

echo "Current run path: $FOLD, use it?(Y/n)"
read USE_DEFAULT
if [[ $USE_DEFAULT = 'N'  || $USE_DEFAULT = 'n' ]];
then
    echo "Pls input the path:"
    read FOLD
fi
echo $FOLD > $FILE
if [ -f $OUTPUT ];
then
    rm $OUTPUT
fi
python concordion_folder_runner -o output/$FOLD specs/$FOLD

if [ -f batch.txt ];
then
    rm batch.txt
fi
