关于数据库
==========

#### costaccounting
* 私有的costaccounting
* 公共的costaccounting 供QA使用
* costaccounting-dev


#### acceptance Test debug
* ./run_single.sh
* 在 .p 文件里加一些message。
* tail -f acceptanceTest.log。
* Ctrl+z 退出 tail。


#### 数据库恢复
* costaccounting-dev 上的 db
* private环境下的 /qad/local/sandbox/backups/zdy/costaccounting 作为数据库 backup 的中转仓库。dbadmin会自动在该目录内 备份和恢复 backup文件。

* 公共环境下的db文件 /qad/local/sandbox/backups/devel 目录中，在 costaccounting-dev 目录下是 costaccounting-dev 的db文件。
	* backup_history 最近五天的备份
	* daily_backup 当天的

* 从公共环境下载数据到本地的数据 是： cp -r /qad/local/sandbox/backups/devel/costaccounting-dev/daily_backup  /qad/local/sandbox/backups/zdy/costaccounting/daily_backup

* ssh私有环境， 在coli21上跑，cd $ROOT 上。
* 执行恢复 dbadmin restore --tag "daily_backup" --force
	* --tag 代表 /qad/local/sandbox/backups/devel/costaccounting-dev/ 下的文件夹。

	* --force 代表强制运行，取消交互式操作。
* ssh coli21 

