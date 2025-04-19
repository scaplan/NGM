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

def computeDistance(filePathInput, filePathGoldStd):
	inputCurrLine = ''
	gsCurrLine = ''

	differenceTotal = 0.0
	differenceTrainingOnly = 0.0
	# Single,Sub_seq,Basic_seq,Super_seq,Sub_par,Basic_par,Super_par
	diffArray = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

	with open(filePathInput, 'r') as inputFile:
		with open(filePathGoldStd, 'r') as gsFile:
			inputFile.readline()
			gsFile.readline()
			for inputCurrLine, gsCurrLine in zip(inputFile, gsFile):
				inputTokens = inputCurrLine.rstrip().split(',')
				gsTokens = gsCurrLine.rstrip().split(',')
				itrCount = 1
				while (itrCount < len(inputTokens)):
					inputValue = inputTokens[itrCount]
					gsValue = gsTokens[itrCount]
					currDiff = abs(float(inputValue) - float(gsValue))

					#diffArray[itrCount] = diffArray[itrCount] + currDiff
					diffArray[itrCount-1] = diffArray[itrCount-1] + currDiff
					differenceTotal += currDiff
					if (itrCount == 1 or itrCount == 3 or itrCount == 6):
						differenceTrainingOnly += currDiff
					itrCount += 1
				
	return diffArray, differenceTrainingOnly, differenceTotal


##
## Main method block
##
if __name__=="__main__":
	if (len(sys.argv) < 3):
		print('incorrect number of arguments, got ' + str(len(sys.argv)))
		exit(0)

	# $OUTPUT_FILE_STATS $GOLD_STANDARD_FILE >> $OUTPUT_COMPARISON_FILE
	settingStatsFileName = sys.argv[1]
	goldStdFileName = sys.argv[2]

	diffArray, diffTrain, diffTotal = computeDistance(settingStatsFileName, goldStdFileName)
	print settingStatsFileName + ",",
	for diffForTest in diffArray:
		print str(diffForTest) + ',',
	print str(diffTrain) + ",",
	print diffTotal
