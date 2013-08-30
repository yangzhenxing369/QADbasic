#!/usr/bin/python

import os, sys

#引入 optparse 模块，用来处理命令行参数 选项。
# OptionParser 类，处理命令行 选项。
from optparse import OptionParser

parser = OptionParser(

	#用法说明
	usage="USAGE: %prog [options] SOURCE_FOLDER",
	#版本
	version="0.10.0",
	#描述
	description="Run all the pyConcordion tests contained in SOURCE_FOL    DER and sub folders."

)

#添加一个选项 "-o"
parser.add_option("-o", "--output_folder",
	
	help="generate report in OUTPUT_FOLDER",

	#:表示显示到help中option的默认值（显示到help的时候并不是default）；
	metavar="OUTPUT_FOLDER"

)
 
#添加一个选项 "-e"
parser.add_option("-e", "--extensions",

	help="Activate concordion extensions. Value 'org.concordion.ext.Ext    ensions' activates concordion-extensions.",
	metavar="EXTENSION_NAME"

)

#若parse_args()没有参数传入,parse_args会默认将sys.argv[1:]的值作为默认参数。
(options, args) = parser.parse_args()


# python concordion_folder_runner -o output/$FOLD specs/$FOLD
if len(args) != 1:
	parser.error("Incorrect number of arguments")

real_options = {}


#
if options.output_folder is not None:
	real_options['output_folder'] = options.output_folder

# 
if options.extensions is not None:
	real_options['extensions'] = options.extensions



from concordion.runners import FolderRunner

FolderRunner().run(args[0], options=real_options)
