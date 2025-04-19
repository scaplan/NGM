#!/usr/bin/python
# -*- coding: utf-8 -*-

#
#  Spencer Caplan
#

import sys, math
import numpy as np
reload(sys)
sys.setdefaultencoding('utf-8')
import unicodedata
from unicodedata import normalize

def checkEffectDirection(filePathInput):
	SD = 0.15
	singleProp = ''
	sequentialProp = ''
	parallelProp = ''
	wellFormedInput = False
	print filePathInput + ',',
	with open(settingStatsFileName, 'r') as inputFile:
		for currLine in inputFile:
			currLineTokens = currLine.split(',')
			if len(currLineTokens) == 8:
				selectionType = currLineTokens[0]
				if selectionType == '1_BASIC':
					singleProp = float(currLineTokens[1])
					sequentialProp = float(currLineTokens[2])
					parallelProp = float(currLineTokens[5])
					wellFormedInput = True
					print str(singleProp) + ',' + str(sequentialProp) + ',' + str(parallelProp) + ',',

	if wellFormedInput:
		sequentialGap = abs(sequentialProp - parallelProp)
		parallelGap = abs(parallelProp - singleProp)
		print str(sequentialGap) + ',' + str(parallelGap) + ',',
		if sequentialGap > SD:
			print '0'
			return False
		elif parallelGap < SD:
			print '0'
			return False
		else:
			print '1'
			return True
	else:
		print 'Illformed input'



##
## Main method block
##
if __name__=="__main__":
	if (len(sys.argv) < 2):
		print('incorrect number of arguments, got ' + str(len(sys.argv)))
		exit(0)

	settingStatsFileName = sys.argv[1]

	# read in "1_BASIC" selection numbers:
		# Single, Sub_seq, Sub_par
		# is 3-par more than SD less thsan Single
		# is 3-seq less than SD different from Single
	expectedEffect = checkEffectDirection(settingStatsFileName)