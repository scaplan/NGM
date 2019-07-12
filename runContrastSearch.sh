#!/bin/bash
# Initialization script for LocalWordLearner

#########################
#########################
## Author: Spencer Caplan
## Contact: spcaplan@sas.upenn.edu
## University of Pennsylvania, Department of Linguistics
#########################
#########################



#########################
#########################
## Define parameter list fuction
#########################
#########################
function createParameterList()
{
	START_ENTRY=$(echo ${SEED_LIST[0]}*$MULT | bc) 
	for ENTRY in "${SEED_LIST[@]}"; do
		SCALED=$(echo "$MULT*$ENTRY" | bc)
		CURR_DIFF=$(echo "$SCALED-$START_ENTRY" | bc)
		INT_DIFF=${CURR_DIFF%.*}
		if [[ $((INT_DIFF % $MOD)) == 0 ]]; then
			#Add to list
			TEMP_PARAMETER_LIST=("${TEMP_PARAMETER_LIST[@]}" $ENTRY)
		fi
	done
}



#########################
#########################
## Set and read input arguments
#########################
#########################
MULT=100
MOD=10

echo "Reading in $# arguments to runContrastSearch.sh"
if [ $# -ne 5 ]
  then
    echo "Incorrect number of  arguments supplied"
    exit 0
fi

OUTPUT_DIR="$1"
WORLD_FILE_SOURCE="$2"
TEST_FILE_SOURCE="$3"
PARAM_SET="$4"
NUM_NGM_PARTICIPANTS="$5"


#########################
#########################
## Declare and compile Java source
#########################
#########################
declare -a javaSource
javaSource=("LocalWordLearner" "Feature" "WordRepresentation" "WorldItem")
for currFile in "${javaSource[@]}"; do
	javac $currFile.java
done



#########################
#########################
## Create Parameter List
#########################
#########################
SEED_LIST=(0.{0..9})
createParameterList
CONTRAST_LIST=("${TEMP_PARAMETER_LIST[@]}")
TEMP_PARAMETER_LIST=()

OTHER_PROMINENCE=$(echo $PARAM_SET | cut -d "_" -f 1 )
BASIC_PROMINENCE=$(echo $PARAM_SET | cut -d "_" -f 2 )
LOWER_BLOCKING_THRESHOLD=$(echo $PARAM_SET | cut -d "_" -f 3 )
DISTANCE_THESHOLD=$(echo $PARAM_SET | cut -d "_" -f 4 )
SALIENCE_STDDEV=$(echo $PARAM_SET | cut -d "_" -f 5 )


#########################
#########################
## Execute grid search for NGM
#########################
#########################

echo "Running" ${javaSource[0]} "with" $NUM_NGM_PARTICIPANTS "participants..."
for CONTRAST in "${CONTRAST_LIST[@]}"; do

	PARAM_STRING=$OTHER_PROMINENCE"_basic"$BASIC_PROMINENCE"_block"$LOWER_BLOCKING_THRESHOLD"_distance"$DISTANCE_THESHOLD"_stdDev"$SALIENCE_STDDEV
	OUTPUT_FILE_STATS="${OUTPUT_DIR}word_learning_raw_output_sub"$PARAM_STRING"_contrast"$CONTRAST".txt"

	java ${javaSource[0]} $WORLD_FILE_SOURCE $TEST_FILE_SOURCE $NUM_NGM_PARTICIPANTS $OTHER_PROMINENCE $BASIC_PROMINENCE $LOWER_BLOCKING_THRESHOLD $DISTANCE_THESHOLD $SALIENCE_STDDEV $OUTPUT_FILE_STATS $CONTRAST
	CURR_BASIC_GEN=$(sed '3q;d' $OUTPUT_FILE_STATS | cut -d ',' -f 3)
	echo "Contrast Comparison Parameter: $CONTRAST -- Sequential Basic Generalization: $CURR_BASIC_GEN"
	
done


#########################
#########################
## Remove compiled Java files
#########################
#########################
echo "Cleaning up compiled Java..."
rm ./*.class
