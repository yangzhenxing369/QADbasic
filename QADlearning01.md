QAD EE 学习 第一部分
====================

##### Business Relation
* 业务关系，包含账户的地址信息。
* 客户 和 供应商 一般都需要指定一个BR。
* 建立一个 entity 时也需指定一个 BR。
* 在创建employee，end user,也需指定一个 BR。


##### entity setup
* 可建立独立的 资产负债表(balance sheets) 与 损益表(income statements)
* 会继承domain的货币单位(domain base currency) 和 使用domain的shared set.
* entity专有的数据 包括 employees信息 和 银行账户信息。



##### journal entry
* 会计分录，也叫posting。是会计系统的最基本单位。
* 一个journal entry可以有多个posting line组成。
* 一个journal entry代表一个事务(transaction)。
* 每个posting line都与一个GL Account相关。


##### posting line
* 分为 level 1 posting line 和 level 2 posting line。
* 一个posting line一般都有GL Account，Description, Currency, Debit, Credit等字段。
* 以上字段是 level 1 posting line。这些字段也叫sub-level。
* 另外有level 2的posting line。可单击 extender查看。


##### daybook 
* 日记账，也叫journals。
* 日记账是一个用于定义对总账(GL)的专门视角。
* 日记账是对总账交易(GL transactions)的专门分类，以用于报表服务。

##### daybook type
* 由用户定义。
* 对打印book进行分类主要便于报表服务。
* 三种类型，Financial, Operational, External daybooks.
	* Financial daybook 一般接收来自与财务有关的各个模块(如总账, AP, AR)的会计分录。
	* Operational daybook 一般接收来自operational功能模块(如销售, 库存控制, 固定资产, 制造)的会计分录。

			该种daybook中的会计分录(posting)被创建时是unposted，需要人工一个post行动将这些数据更新到总账的transaction account。
						 
			该种daybook在post发票过程中会生成发票编号。

	* External daybook 作为一个借口被用在外部的系统，如工资系统。



##### GL transaction type
* 由系统定义。


##### transaction 
* 一个transaction是一个业务活动(business activity)财务结果的记录。
* 一个业务活动(business activity)会创建一个/多个会计分账(journal entry),这些journal entries会最终被post到总账中去。

* 当一个transaction被创建时，系统自动分配一个长度为14的字符序列作为id号，以在被引用时使用。

		<transaction type><yr><mm><dd><transation number>

* transaction type由创建transaction时所在的模块类别所决定。


