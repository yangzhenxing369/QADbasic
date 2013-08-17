PROGRESS编程 02
==============

## PROGRESS程序架构。

    PROGRESS 启动应用程序，通常都是先启动一个主程序，比如mf.p，这个mf.p做一些全局变量设置，并初始化应用程序菜单。

    当用户执行菜单功能时，实际上是运行菜单所指定的程序！在这种模式下，PROGRESS的程序一般都不大，结构明了可读性很强，每个程序目的非常明确，但是也要遵循一定的准则，方便以后的阅读和修改。
***


##### 一、程序扩展名的设定。

    * .p 主程序（可直接运行，或者编译以后挂主菜单被调用）
    * .i 子程序（经常使用的执行某一特定功能，或者为了使主程序易于阅读脱离出来）
    * .v 验证程序
    * .w Windows的程序（Windows版的Progress支持可视化的组件编程，组件拉一拉放一放，就自动生成.w的文件了）
    * .r 编译后的程序（菜单调用时，实际上是执行.r的程序）


##### 二、程序的命名规则。

1. 主程序命名格式： aa + bb + cc + dd.p

其中：
    aa — 系统模块ID
    bb — 系统功能
    cc — 程序类型（__mt__ -维护、__iq__ -查询或者 __rp__ -报表等）
    dd — 序列号

2. 子程序格式：通常是 主程序a.i    主程序b.i   这样子

    关于程序的命名，个人觉得也没必要一定要遵循特定格式，一家公司有自己固定的命名方式，容易区分即可；如果是咨询公司或者系统集成公司，则要先了解客户的命名习惯和规则；同理，下面的“程序头”。


##### 三、程序头。

以 注释的形式，标明尽可能多的程序相关的信息，比如：程序名（路径，不过路径一般都是企业自己规定好了）、作者、菜单号、功能（菜单标题）、创建日期、修改日志等。至于格式，也就是POSE，爱怎么摆怎么摆，清楚明了即可。但是，在同一家公司，风格应该统一。另外，关于修改日志，个人觉得最好在程序头和程序体，都明显说明一下修改的日期和原因，要点。（注释不记入程序长度，所以不要担心程序太长，:p ）
四、维护类程序模板。
注意：为方便说明，注释暂时用“//”，但是在PORGRESS程序里是错误的哈！
define variables.
{mfdtitle.i} //程序头，全局变量定义等，是标准QAD的菜单程序就请加上这个，不要问为什么
form with frame a. //定义格局（包含输入输出）
Mainloop:
repeat:
          prompt-for …  editing: //通常这里输入主要字段（如果比如订单号，料件名称等）
       {mfnp.i} //前后记录显示功能，常用
         end.
        /* ADD/MODI/DELETE */
        assign global…
        find …
        if not available … //新记录
            {mfmsg.i 1 1} //类似mfmsg的子程序，都是信息提示类
            create …
            assign …
        end.
        Status = stline{2}.
        update go-on (F5 or Ctrl-D)  //继续维护剩余字段
        if F5 or CTRL-D then do: //判断是否按了删除键，一般定义是F5或者Ctrl + D
            del-yn = yes.
            {mfmsg01.i 11 1 del-yn}
        end.
End.
Status input.
五、报表类程序的模板。
{mfdtitle.i}
form definition [selection criteria]
part colon 15 part1 colon 40 label {t001.i}
effdate colon 15 effdate1 colon 40 label {t001.i}
with frame a side-labels width 80.
//以上4行定义用户输入“限制报表输出”的条件，比如生效日期啊什么的
repeat:
    if part1 = hi_char then part1 = “”. //如果用户不输任何东西，则默认最大字符或者最小字符，以下类似
    if effdate = low_date then effdate = ?.
    if effdate1 = hi_date then effdate1 = ?.
    data statements [selection criteria]
    bcdparm = “”.
    {mfquoter.i  part } //BATCH专用，至今没用过，体会不到好处，哪位帮忙解释一下？
    {mfquoter.i  part1 }
    {mfquoter.i  effdate}
    {mfquoter.i  effdate1 }
    {mfselbpr.i  “printer” 132} //选择打印机的子程序
    if part1 = “” then part1 = hi_char.
    if effdate = ? Then effdate = low_date.
    if effdate1 = ? Then effdate1 = hi_date.
    {mfphead.i or mfphead2.i} //报表头
    for each…
         display 
         {mfrpchk.i} or {mfrpexit..i} //报表结束
    end.
   {mfrtrail.i} or {mftr0801.i} or {mfreset.i} //报表结束、打印结束等
end.
六、查询类程序模板。
这个比报表来得要简单些了：
{mfdtitle.i}
form definition [selection criteria]
with frame a side-labels width 80.
repeat:
      data statement [selection criteria]  with frame a.
      {mfselprt.i “terminal” 80 }
       for each [selection criteria]
            display …
            {mfrpchk.i} (max page)
       end.
       {mfreset.i} (scroll output)
       {mfmsg.i 8 1}
end.