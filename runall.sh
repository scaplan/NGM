#!/bin/bash
# Initialization script for "Word Learning as Category Formation" (Naive Generalization Model)

#########################
#########################
## Author: Spencer Caplan
## Contact: spcaplan@sas.upenn.edu
## University of Pennsylvania, Department of Linguistics
#########################
#########################



#########################
#########################
## Set working variables
#########################
#########################
NUM_NGM_PARTICIPANTS=1000

SOURCE_DIR="$(pwd)/input/"
OUTPUT_HEAD_DIR="$(pwd)/output/"
OUTPUT_PARTICIPANTS_DIR="$(pwd)/output/NGM_participants/"
WORKING_DIR=$(pwd)
LF_OUTPUT_STATS_FILE="${OUTPUT_HEAD_DIR}/LF_analysis_output_stats.txt"
SPSS_MEANS_FILE="${SOURCE_DIR}SPSS_Results_Means.csv"
SPSS_STDDEV_FILE="${SOURCE_DIR}SPSS_Results_StdDev.csv"

OBJECT_TRAIN_FILE="${SOURCE_DIR}ObjectTrainingStimuli.txt"
OBJECT_TEST_FILE="${SOURCE_DIR}ObjectTestStimuli.txt"

OUTPUT_COMPARISON_FILE="${OUTPUT_HEAD_DIR}NGM_parameter_search.csv"
if [ -f $OUTPUT_COMPARISON_FILE ] ; then
    rm $OUTPUT_COMPARISON_FILE
fi

OUTPUT_EFFECT_FILE="${OUTPUT_HEAD_DIR}NGM_effect_direction_output.csv"
if [ -f $OUTPUT_EFFECT_FILE ] ; then
    rm $OUTPUT_EFFECT_FILE
fi

# Splash art
printf '\n\n'
base64 -d <<<"H4sIAG20KF0AA5WSTQqDMBBG957ikyy6ackVCoWuhCy7CUigQQR1IBFKwcM3UbFWExpfSGDgZSY/
w1gSGcODzBOFVqaruwrK4qZ6XZF5406mVX1NHZyXmC9Dkgfn4T9hr5koJyJeeS4Xc0Qu3rxphLsp
d+KST87agKsbw1b81pUXDwnhVkF0WcPX55NNDP57j5jIt/cNizz8LpyvIykj7zwMCIU7TwiEwkP/
m9YvBxqL+dKF7k8Wje9rWGo1Xq7PbZ7nviw7UBgfd1BVh0sDAAA=" | gunzip
printf '\n\n'


#########################
#########################
## NGM simulations
#########################
#########################
bash ./runNGM.sh $OUTPUT_PARTICIPANTS_DIR $OBJECT_TRAIN_FILE $OBJECT_TEST_FILE $SPSS_MEANS_FILE $OUTPUT_COMPARISON_FILE $OUTPUT_EFFECT_FILE $NUM_NGM_PARTICIPANTS
printf '\n\n'

TOP_TRAINING_NGM_OUTPUT=$(sort -t, -nk9 $OUTPUT_COMPARISON_FILE | head -n 2 | cut -d "," -f 1 | tail -n 1)
TOP_TRAINING_NGM_OUTPUT_BY_PARTICIPANT="${TOP_TRAINING_NGM_OUTPUT}_byIndividual.txt"
echo "Top tuning parameters: $TOP_TRAINING_NGM_OUTPUT"

ORACLE_NGM_OUTPUT=$(sort -t, -nk10 $OUTPUT_COMPARISON_FILE | head -n 2 | cut -d "," -f 1 | tail -n 1)
TOP_TRAINING_NGM_TOTALDIFF=$(sort -t, -nk9 $OUTPUT_COMPARISON_FILE | head -n 2 | cut -d "," -f 10 | tail -n 1)
ORACLE_NGM_TOTALDIFF=$(sort -t, -nk10 $OUTPUT_COMPARISON_FILE | head -n 2 | cut -d "," -f 10 | tail -n 1)

TOP_TRAINING_NGM_MEANDIFF_PERTRIAL=$(bc <<< "scale=3;$TOP_TRAINING_NGM_TOTALDIFF/21")
ORACLE_NGM_MEANDIFF_PERTRIAL=$(bc <<< "scale=3;$ORACLE_NGM_TOTALDIFF/21")
ORACLE_GAP_PER_TRIAL=$(bc <<< "scale=3;$TOP_TRAINING_NGM_MEANDIFF_PERTRIAL-$ORACLE_NGM_MEANDIFF_PERTRIAL")
echo "Oracle performance gap per trial: $ORACLE_GAP_PER_TRIAL"
echo "Limited tuning per trial diff: $TOP_TRAINING_NGM_MEANDIFF_PERTRIAL"

PLACEMENT_OF_TUNING_RESULT_IN_ORACLE_SORTING=$(sort -t, -nk10 $OUTPUT_COMPARISON_FILE | grep -n $TOP_TRAINING_NGM_OUTPUT | cut -d ":" -f 1)
PLACEMENT_OF_TUNING_RESULT_IN_ORACLE_SORTING=$(bc <<< $PLACEMENT_OF_TUNING_RESULT_IN_ORACLE_SORTING-1) # To remove counting file header
TOTAL_GRID_SEARCH_SIZE=$(wc -l $OUTPUT_COMPARISON_FILE | awk '{print $1}')
TOTAL_GRID_SEARCH_SIZE=$(bc <<< "$TOTAL_GRID_SEARCH_SIZE - 1")
TUNING_ORACLE_PERCENTILE=$(bc <<< "scale=3;$PLACEMENT_OF_TUNING_RESULT_IN_ORACLE_SORTING / $TOTAL_GRID_SEARCH_SIZE")
echo "Rank of tuning result in Oracle list: $PLACEMENT_OF_TUNING_RESULT_IN_ORACLE_SORTING"
echo "Total grid search size: $TOTAL_GRID_SEARCH_SIZE"
echo "Tuning result percentile in Oracle list: $TUNING_ORACLE_PERCENTILE"

# Extract top tuned parameter settings to pass to contrast search
function join_by { local IFS="$1"; shift; echo "$*"; }
PARAM_SET_BUILDER=$(echo ${TOP_TRAINING_NGM_OUTPUT_BY_PARTICIPANT##*/} | sed 's/.txt//g')
SUB=$(echo $PARAM_SET_BUILDER | cut -d "_" -f 5 | sed 's/sub//g')
BASIC=$(echo $PARAM_SET_BUILDER | cut -d "_" -f 6 | sed 's/basic//g')
BLOCK=$(echo $PARAM_SET_BUILDER | cut -d "_" -f 7 | sed 's/block//g')
DISTANCE=$(echo $PARAM_SET_BUILDER | cut -d "_" -f 8 | sed 's/distance//g')
STDDEV=$(echo $PARAM_SET_BUILDER | cut -d "_" -f 9 | sed 's/stdDev//g')
PARAM_SET=$(join_by _ $SUB $BASIC $BLOCK $DISTANCE $STDDEV)

printf '\n\n'
bash ./runContrastSearch.sh $OUTPUT_PARTICIPANTS_DIR $OBJECT_TRAIN_FILE $OBJECT_TEST_FILE $PARAM_SET $NUM_NGM_PARTICIPANTS



#########################
#########################
## Make plots
#########################
#########################
echo "Generating Plots..."
Rscript makePlotsNGM.R $WORKING_DIR $OUTPUT_HEAD_DIR $TOP_TRAINING_NGM_OUTPUT_BY_PARTICIPANT $SPSS_MEANS_FILE $SPSS_STDDEV_FILE
printf '\n\n'


#########################
#########################
## Lewis and Frank (2018) Analysis
#########################
#########################
echo "Lewis and Frank analysis..."
Rscript LF_presentation_analysis.R $SOURCE_DIR $OUTPUT_HEAD_DIR "LF_experiment_key.csv" "LF_no_dups_data_munged_A.csv" > $LF_OUTPUT_STATS_FILE

base64 -d <<<"H4sIAA+4KF0AA+Nyy8zLLM5ITVHk4lImBgBVKRACUFVu+UUKhaWpxSWZ+XnFOgrJ+bm5qXklQFZq
SbIeXFVATmpicSpQNq8kMblEIbggNS85tUjBObEgJzEPrqq4IBks4FCcWKxXClSTp5eaUopuIzHu
IgIAAMcZbBIVAQAA" | gunzip
printf '\n\n'
