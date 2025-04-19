#!/bin/bash
# Initialization script for LocalWordLearner

#########################
#########################
## Author: Spencer Caplan
## Contact: scaplan@gc.cuny.edu
## CUNY Graduate Center
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

function computeProgressBar()
{
	CURR_PROGRESS_PERCENT=$(echo "$counter/$TOTAL_PARAM_GRID_LENGTH" | bc)
	CURR_PROGRESS_PERCENT=$(bc <<< "scale=3;$counter/$TOTAL_PARAM_GRID_LENGTH")
	CURR_PROGRESS_BARS=$(bc <<< "scale=3;$CURR_PROGRESS_PERCENT*60")
	CURR_PROGRESS_BARS=$(echo "($CURR_PROGRESS_BARS+0.5)/1" | bc)
}



#########################
#########################
## Set and read input arguments
#########################
#########################
MULT=100
MOD=10

echo "Reading in $# arguments to runNGM.sh"
if [ $# -ne 7 ]
  then
    echo "Incorrect number of  arguments supplied"
    exit 0
fi

OUTPUT_DIR="$1"
WORLD_FILE_SOURCE="$2"
TEST_FILE_SOURCE="$3"
GOLD_STANDARD_FILE="$4"
OUTPUT_COMPARISON_FILE="$5"
OUTPUT_EFFECT_FILE="$6"
NUM_NGM_PARTICIPANTS="$7"
echo "File,Single,Sub_seq,Basic_seq,Super_seq,Sub_par,Basic_par,Super_par,TrainingDiff,TotalDiff" > $OUTPUT_COMPARISON_FILE
echo "File,Single,Sequantial,Parallel,SeqGap,ParGap,ExpectedDirection" > $OUTPUT_EFFECT_FILE



#########################
#########################
## Declare and compile Java source
#########################
#########################
declare -a javaSource
javaSource=("LocalWordLearner" "Feature" "WordRepresentation" "WorldItem")
echo "Compiling Java source..."
for currFile in "${javaSource[@]}"; do
	javac $currFile.java
done



#########################
#########################
## Create Parameter List
#########################
#########################
SEED_LIST=(0.{20..50})
createParameterList
OTHER_PROMINENCE_LIST=("${TEMP_PARAMETER_LIST[@]}")
TEMP_PARAMETER_LIST=()

SEED_LIST=(0.{50..80})
createParameterList
BASIC_PROMINENCE_LIST=("${TEMP_PARAMETER_LIST[@]}")
TEMP_PARAMETER_LIST=()

SEED_LIST=(0.{00..30})
createParameterList
LOWER_BLOCKING_THRESHOLD_LIST=("${TEMP_PARAMETER_LIST[@]}")
TEMP_PARAMETER_LIST=()

SEED_LIST=(0.{30..60})
createParameterList
DISTANCE_THESHOLD_LIST=("${TEMP_PARAMETER_LIST[@]}")
TEMP_PARAMETER_LIST=()

SEED_LIST=(0.{15..45})
createParameterList
SALIENCE_STDDEV_LIST=("${TEMP_PARAMETER_LIST[@]}")
TEMP_PARAMETER_LIST=()

TOTAL_PARAM_GRID_LENGTH=$(echo "${#OTHER_PROMINENCE_LIST[@]}*${#BASIC_PROMINENCE_LIST[@]}*${#LOWER_BLOCKING_THRESHOLD_LIST[@]}*${#DISTANCE_THESHOLD_LIST[@]}*${#SALIENCE_STDDEV_LIST[@]}" | bc)

#########################
#########################
## Execute grid search for NGM
#########################
#########################

counter=0
BAR='[##########################################################]'   # 60 character bar
BAR_BOUNDING='[                                                          ]'

echo "Running" ${javaSource[0]} "with" $NUM_NGM_PARTICIPANTS "participants..."
echo "With $TOTAL_PARAM_GRID_LENGTH parameter combinations..."
for BASIC_PROMINENCE in "${BASIC_PROMINENCE_LIST[@]}"; do
	for OTHER_PROMINENCE in "${OTHER_PROMINENCE_LIST[@]}"; do
		for LOWER_BLOCKING_THRESHOLD in "${LOWER_BLOCKING_THRESHOLD_LIST[@]}"; do
			for DISTANCE_THESHOLD in "${DISTANCE_THESHOLD_LIST[@]}"; do
				for SALIENCE_STDDEV in "${SALIENCE_STDDEV_LIST[@]}"; do

					PARAM_STRING=$OTHER_PROMINENCE"_basic"$BASIC_PROMINENCE"_block"$LOWER_BLOCKING_THRESHOLD"_distance"$DISTANCE_THESHOLD"_stdDev"$SALIENCE_STDDEV
					OUTPUT_FILE_STATS="${OUTPUT_DIR}word_learning_raw_output_sub"$PARAM_STRING".txt"

					counter=$((counter+1))
					if [[ $((counter % 10)) == 0 ]]; then
						for background_PID in "${background_PID_list[@]}"; do
							wait $background_PID
						done

						computeProgressBar
						echo -ne "\r${BAR:0:$CURR_PROGRESS_BARS}${BAR_BOUNDING:$CURR_PROGRESS_BARS:60} NGM grid search progress: $CURR_PROGRESS_PERCENT"
					fi

					java ${javaSource[0]} $WORLD_FILE_SOURCE $TEST_FILE_SOURCE $NUM_NGM_PARTICIPANTS $OTHER_PROMINENCE $BASIC_PROMINENCE $LOWER_BLOCKING_THRESHOLD $DISTANCE_THESHOLD $SALIENCE_STDDEV $OUTPUT_FILE_STATS &
					
					LAST_PID=$!
					background_PID_list+=($LAST_PID)

				done
			done
		done
	done
done

printf '\n\n'
counter=0


for BASIC_PROMINENCE in "${BASIC_PROMINENCE_LIST[@]}"; do
	for OTHER_PROMINENCE in "${OTHER_PROMINENCE_LIST[@]}"; do
		for LOWER_BLOCKING_THRESHOLD in "${LOWER_BLOCKING_THRESHOLD_LIST[@]}"; do
			for DISTANCE_THESHOLD in "${DISTANCE_THESHOLD_LIST[@]}"; do
				for SALIENCE_STDDEV in "${SALIENCE_STDDEV_LIST[@]}"; do

					counter=$((counter+1))
					PARAM_STRING=$OTHER_PROMINENCE"_basic"$BASIC_PROMINENCE"_block"$LOWER_BLOCKING_THRESHOLD"_distance"$DISTANCE_THESHOLD"_stdDev"$SALIENCE_STDDEV
					OUTPUT_FILE_STATS="${OUTPUT_DIR}word_learning_raw_output_sub"$PARAM_STRING".txt"

					python wl-parameter-compare.py $OUTPUT_FILE_STATS $GOLD_STANDARD_FILE >> $OUTPUT_COMPARISON_FILE
					python wl-parameter-effectDirectionCheck.py $OUTPUT_FILE_STATS >> $OUTPUT_EFFECT_FILE

					if [[ $((counter % 10)) == 0 ]]; then
						computeProgressBar
						echo -ne "\r${BAR:0:$CURR_PROGRESS_BARS}${BAR_BOUNDING:$CURR_PROGRESS_BARS:60} NGM computing effect directions progress: $CURR_PROGRESS_PERCENT"
					fi

				done
			done
		done
	done
done

printf '\n\n'


#########################
#########################
## Remove compiled Java files
#########################
#########################
echo "Cleaning up compiled Java..."
rm ./*.class
