QAD EE 学习 财务部分
====================


##### cost set
* 成本集
* Standard Cost  [Type: GL]
	* 该成本集包含可以用于生成总帐会计帐务的成本。

* Current Cost     [Type: CURR] 
	* 该成本集保持跟踪平均成本及上次成本。
  
* Simulate Cost   [Type: SIM]   
	* 该成本集包含模拟成本。

##### 成本计算方法 cost calcualte method
* 标准成本法 (STD)
	* 即目标成本或预计成本,在计划期内一般下保持不变;

* 平均成本法 (AVG)
    * 简单移动平均成本法，材料及人工成本每次以移动平均成
    本计算并更新系统;

* 最新成本法（LAST）
   	* 收到零件时, 当前成本置为上次采购单或加工单的单位成本;

*（None）当前成本由手工更新；


##### cost element 
* Material 
	* 材料
* Labor
	* 人工
* Burden
	* 制造费用
* Overhead
	* 间接费用
* Subcontract
	* 外包

##### burden rate 间接费用分摊率

##### Overhead 间接费用
* Overhead, as it is used in the MFG/PRO Cost Accounting System, is split into two parts:

* Burden (Variable overhead) =可变的间接费用 制造费用:
	* 可预定其变动费用率再乘以人工时或机器小时或者人工成本.

	* Burden is the variable portion of overhead cost. In a standard cost system, standard burden per unit is usually calculated based on predetermined burden rates, typically based on labor or machine hours and/or labor cost.

	* 特点：1).Fixed amount within a relevant product output range 2). Manually calculated by dividing the annual expected overhead costs by the annual expected number of units to be produced. Because total overhead is fixed, as output increases, the cost per unit must decrease.
	3). Management-level decision on incurrence starts at executive level vs. operating supervisors

	* Depreciation, real property taxes, patent amortization, wages for production executives, watchmen, firemen, janitors, maintenance and repairs, insurance, rent

	* 资产折旧。国定资产税，专利摊销费, 租金等。

	* 可变的。 一般根据预先设定的 间接费用分摊率 计算。
	* 一般以 人工/机器的工作小时，或 人工成本 为根据。


* Overhead (Fixed overhead) =固定的间接费用 间接费用 :
	* 用人工方式指定的固定费用或是其它成本的百分比(如:可设为材料成本的百分比)

	* 需要人工的设定。
		* Item Master Maintenance (1.4.1), Item Cost Maintenance (1.4.9), Item Site Cost Maintenance (1.4.18) or as a percentage of some other cost category, Item Burden Cost Update (1.4.20) (Burden), Item Burden Cost Update (1.4.21) (Overhead)

	* Overhead is the fixed portion of overhead cost. In a standard cost system, a portion of fixed overhead cost per unit is usually allocated to each item, either manually or as a percentage of some other cost category. For example, fixed overhead may be set to a percentage of material cost.

	* 是固定的。一般被分配到具体的每个 item 上。或者以 某个cost category为基础的比例计算。如 材料成本的比例。

	* 1.Variable amount in direct proportion to output Calculated by QAD Enterprise Applications by multiplying the actual number of units produced by a pre-determined burden rate. Because total burden is variable, as output increases, cost per unit is constant.
	2.Easily assignable to operating departments 3.Incurrence decision rests at department level
	

	* Supplies, fuel, power, small tools, spoilage/salvage/reclamation expense, receiving costs, royalties, factory travel costs

	* 燃油费，电费。

