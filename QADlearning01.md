QAD EE 学习 财务部分
====================

##### Business Relation
* 业务关系，包含账户的地址信息。
* 客户 和 供应商 一般都需要指定一个BR。
* 建立一个 entity 时也需指定一个 BR。
* 在创建employee，end user,也需指定一个 BR。
* BR存放在DB中，并在 domain中使用。

##### Business Relation中的 address 类型
* HeadOffice 正常地址。
* ShipTO 收货地址--> Sales Order.
* Dock 用在客户日程的 收货地址。
* Remainder 用在对账单中。


##### entity setup
* 可建立独立的 资产负债表(balance sheets) 与 损益表(income statements)
* 会继承domain的货币单位(domain base currency) 和 使用domain的shared set.
* entity专有的数据 包括 employees信息 和 银行账户信息。



##### journal entry
* 会计分录，也叫posting。是会计系统的最基本单位。
* 一个journal entry可以有多个posting line组成。
* journal entry中的每项(即posting line)代表一个事务(transaction)。
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

* daybook code:
* daybook description:
* daybook type:
* layer type:
* control:
* active:

##### daybook type
* 由用户定义。
* 对daybook进行分类,主要便于报表服务
* 分类：Banking Entries, Customer, Journal entries, Periodic Costing, Supplier....
* 每种daybook类型连接着一个accounting layer，以确保记录在daybook中的transaction被自动post到相关的layer中。


##### daybook control type
* 定义transaction的来源。
* 三种控制类型，Financial, Operational, External daybooks.
	* Financial daybook 一般接收来自与财务有关的各个模块(如总账, AP, AR)的会计分录。
	* Operational daybook 一般接收来自operational功能模块(如销售, 库存控制, 固定资产, 制造)的会计分录。

			该种daybook中的会计分录(posting)被创建时是unposted，需要人工一个post行动将这些数据更新到总账的transaction account。
						 
			该种daybook在post发票过程中会生成发票编号。

	* External daybook 作为一个借口被用在外部的系统，如工资系统。




##### GL transaction type
* 由系统定义。
* IC = inventory control
* JL = 
* RA = Retroactive: 追溯事务. 被用于 对已经关闭的GL calendar years进行调整，很少被用到。


##### transaction 
* 一个transaction是一个业务活动(business activity)产生的财务结果记录。
* 一个业务活动(business activity)会创建一个/多个会计分账(journal entry/posting),这些journal entries会最终被post到总账中去。
* 当一个transaction被创建时，系统自动分配一个长度为14的字符序列作为id号，以在被引用时使用。

		<transaction type><yr><mm><dd><transation number>

* transaction type由创建transaction时所在的模块类别所决定。


##### layer (系统使用的)
* layer code:
* Description:
* type: 类型，三种类型 management, official, transient
	* management:
	* official:
	* transient:

* active: 是否已激活。

##### accouting layer
* 为满足生成的报表要求，在一个GL account提供区分事务的不同方法。
* type: 类型， 三种类型 primary layer, second layer, transient layer。
	* primary: 系统中叫official, for daily transaction posting.

			只能定义一个

	* second: 系统中叫management。

			Define one or more secondary layers to allow for adjustments required to meet different GAAP or IFRS requirements, or for management reporting.
			主要用于调整，以满足各种需求。可定义多个。

	* transient： 系统中叫transient。

			The transient layer is used to temporarily post transactions pending approval, or to simulate postings.
			用在等待审批，或模拟post。可定义多个。

##### Banking Daybook Profile
?

##### Payment Format Maintainence
* 付款方式
* 一般建立AR，AP两种类型
* 支付方式分 check(支票), Direct Debit(直接收款), Draft(汇票), Electronic Transfer(电子银行).

##### Customer Create 客户
* accounting tab
	* GL Profile(invoice) 正常的应收账款
	* GL Profile(credit note) 客户开的，用于抵消()
	* GL Profile(pre-payment) 预付款.(customer,预收; supplier,预付)
	* GL Profile(Deducation) 客户付款有尾差时,零头。


##### cost set

	