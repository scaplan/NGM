
#########################
#########################
## Spencer Caplan
## University of Pennsylvania
## spcaplan@sas.upenn.edu
#########################
#########################

#########################
#########################
## Import (packages)
#########################
#########################
suppressMessages(library(scales))
suppressMessages(library(ggplot2))
suppressMessages(library(Hmisc))
suppressMessages(library(lme4))
suppressMessages(library(plyr))
suppressMessages(library(dplyr))
suppressMessages(library(cowplot))
suppressMessages(library(tidyr))
suppressMessages(library(forcats))
suppressMessages(library(lmerTest))

## Comment below to turn warning messages back on
options(warn=-1)


#########################
#########################
## Define auxiliary functions
#########################
#########################
dsubset <- function (...) { return(droplevels(subset(...))) }


#########################
#########################
## Read in data
#########################
#########################
sourceDir = '' # Fill this in with path to directory containing LF data (example\\NaiveGeneralizationModel\\input\\)
outputDir = '' # Fill this in with path to desired output directory (example\\NaiveGeneralizationModel\\output\\)
LF_metadata_file <- "LF_experiment_key.csv" 
# We want to read in this file rather than 'all_data_munged_A.csv' in order to exclude duplicate participants
inputFile = 'LF_no_dups_data_munged_A.csv'


## Parse input args
args = commandArgs(trailingOnly=TRUE)
if (length(args)>3) {
  sourceDir = args[1]
  outputDir = args[2]
  LF_metadata_file = args[3]
  inputFile = args[4]
}


setwd(sourceDir)

origLFdata=read.table(inputFile,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE)
LF_metadata=read.table(LF_metadata_file,header=TRUE,sep=",", quote = "", skipNul = TRUE,fill = TRUE)

# Read in experiment number key
exp_key <- LF_metadata %>% 
  mutate(order = gsub("\"", "", order), 
    exp = as.character(exp)) %>%
    mutate_if(is.character, as.factor) 

# Combine disjoint condition names (since LF data uses '3sub' sometimes but 'three_subordinate' others)
# And join experiment key with main data
data_clean <- origLFdata %>%
  mutate(exp = as.character(exp),
         condition = fct_recode(condition, three_subordinate = "3sub"),
         condition = fct_recode(condition, three_superordinate = "3sup"),
         condition = fct_recode(condition, three_basic = "3bas")) %>%
  mutate_if(is.character, as_factor)  %>%
  select(exp, everything()) %>%
  left_join(exp_key %>% select(exp, order, timing))


#########################
#########################
## Rename columns from LF to be consistent with my terminology
#########################
#########################
colnames(data_clean)[colnames(data_clean)=="category"] <- "stim_category"
colnames(data_clean)[colnames(data_clean)=="condition"] <- "training_number"
colnames(data_clean)[colnames(data_clean)=="timing"] <- "presentation_style"

# Double check training_number names (Should be 1560 trials for each when run)
table(data_clean$training_number)
# Check proportions of basic generalization
table(data_clean$prop_bas)

# There are 12 different experiments reported in LF
# With several hundred trials per experiment
table(data_clean$exp)
# However a number of those manipulations are not of primary interest here and don't have a large effect on behavior (e.g. same vs. different labels across words)
# So I'll be grouping primarily by training number and presentation-style rather than experiment

# Ignore training_numbers that aren't either one exemplar training or three_subordinate training
# Compute mean proportion basic-level generalization -- dropping columns other than:
# experiment number, subjectID, trial number, stimulus category, training number, presentation-style, and block-order
data_clean_basicMeans <- data_clean %>%
  filter(training_number == "one" | training_number == "three_subordinate")  %>%
  gather(variable, value, c(prop_sub, prop_bas, prop_sup)) %>%
  filter(variable == "prop_bas") %>%
  group_by(exp, subids, trial_num, stim_category, training_number, order, presentation_style) %>% 
  summarize(prop_bas = mean(value)) 

#########################
#########################
## Analyzing all data
#########################
#########################

data_clean_basicMeans <- droplevels(data_clean_basicMeans)

# Use rbind to center presentation_style and training_number for proper deviation coding (rather than dummy coding)
contrasts(data_clean_basicMeans$presentation_style) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans$presentation_style)) <- levels(contrasts(data_clean_basicMeans$presentation_style))[2]
contrasts(data_clean_basicMeans$training_number) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans$training_number)) <- levels(contrasts(data_clean_basicMeans$training_number))[2]
contrasts(data_clean_basicMeans$order) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans$order)) <- levels(contrasts(data_clean_basicMeans$order))[2]

# treating basic-generalization as gradient outcome
summary(lmer(prop_bas ~ presentation_style * training_number * order + (1|subids) + (1|stim_category), data=data_clean_basicMeans))

# treating basic-generalization as binary outcome
data_clean_basicMeans_binary = subset(data_clean_basicMeans, prop_bas != 0.5)
summary(glmer(prop_bas ~ presentation_style * training_number * order + (1|subids) + (1|stim_category), data=data_clean_basicMeans_binary, family=binomial))
summary(glmer(prop_bas ~ presentation_style * training_number * order + (1|stim_category), data=data_clean_basicMeans_binary, family=binomial))


#########################
#########################
## Looking at only the second-block trials
#########################
#########################

data_clean_basicMeans_secondBlock <- data_clean_basicMeans %>% as.data.frame %>%
  filter((training_number == "three_subordinate" & order == "1-3") | (training_number == "one" & order == "3-1"))

# Use rbind to center presentation_style and training_number for proper deviation coding (rather than dummy coding)
data_clean_basicMeans_secondBlock <- droplevels(data_clean_basicMeans_secondBlock)
contrasts(data_clean_basicMeans_secondBlock$presentation_style) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans_secondBlock$presentation_style)) <- levels(contrasts(data_clean_basicMeans_secondBlock$presentation_style))[2]
contrasts(data_clean_basicMeans_secondBlock$training_number) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans_secondBlock$training_number)) <- levels(contrasts(data_clean_basicMeans_secondBlock$training_number))[2]
# Linear mixed model

summary(lmer(prop_bas ~ presentation_style * training_number + (1|subids) + (1|stim_category), data=data_clean_basicMeans_secondBlock))
# Nothing, not even training number has an effect on generalization in the second-block
# It is important to only consider the first-block trials, since all major effects disappear in the second-block


#########################
#########################
## Filter to keep only first-block trials
#########################
#########################
data_clean_basicMeans_firstBlock <- data_clean_basicMeans %>% as.data.frame %>%
  filter((training_number == "three_subordinate" & order == "3-1") |
           (training_number == "one" & order == "1-3"))

# Filter to keep only three_subordinate first-block trials with simultaneous-presentation
parallel_sub_data <- data_clean_basicMeans_firstBlock %>% as.data.frame %>%
  filter((presentation_style == "simultaneous" & training_number == "three_subordinate"))

# Filter to keep only three_subordinate first-block trials with sequential-presentation
sequential_sub_data <- data_clean_basicMeans_firstBlock %>% as.data.frame %>%
  filter((presentation_style == "sequential" & training_number == "three_subordinate"))

# Basic t-test for effect of presentation style
# This holds constant training number (3_sub) and block (first)
# This is to verify the significant difference for the main bar plot
t.test(parallel_sub_data$prop_bas,sequential_sub_data$prop_bas)


## Check PSE for each training number individually
parallel_one_data <- data_clean_basicMeans_firstBlock %>% as.data.frame %>% filter((presentation_style == "simultaneous" & training_number == "one"))
sequential_one_data <- data_clean_basicMeans_firstBlock %>% as.data.frame %>% filter((presentation_style == "sequential" & training_number == "one"))
t.test(parallel_one_data$prop_bas,sequential_one_data$prop_bas)
one_data <- data_clean_basicMeans_firstBlock %>% as.data.frame %>% filter((training_number == "one"))
summary(lmer(prop_bas ~ presentation_style + (1|subids) + (1|stim_category), data=one_data))
summary(lm(prop_bas ~ presentation_style, data=one_data))
three_data <- data_clean_basicMeans_firstBlock %>% as.data.frame %>% filter((training_number == "three_subordinate"))
summary(lmer(prop_bas ~ presentation_style + (1|subids) + (1|stim_category), data=three_data))
summary(lm(prop_bas ~ presentation_style, data=three_data))

# Use rbind to center presentation_style and training_number for proper deviation coding (rather than dummy coding)
data_clean_basicMeans_firstBlock_devCoded <- data_clean_basicMeans_firstBlock
data_clean_basicMeans_firstBlock_devCoded <- droplevels(data_clean_basicMeans_firstBlock_devCoded)
contrasts(data_clean_basicMeans_firstBlock_devCoded$presentation_style) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans_firstBlock_devCoded$presentation_style)) <- levels(contrasts(data_clean_basicMeans_firstBlock_devCoded$presentation_style))[2]
contrasts(data_clean_basicMeans_firstBlock_devCoded$training_number) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans_firstBlock_devCoded$training_number)) <- levels(contrasts(data_clean_basicMeans_firstBlock_devCoded$training_number))[2]

# Linear mixed model
summary(lmer(prop_bas ~ presentation_style * training_number + (1|subids) + (presentation_style * training_number|stim_category), data=data_clean_basicMeans_firstBlock_devCoded))
summary(lmer(prop_bas ~ presentation_style * training_number + (1|subids) + (1|stim_category), data=data_clean_basicMeans_firstBlock_devCoded))


# There is no benefit to including the interaction term between presentation-style and training number
fullModelWithInteraction <- lmer(prop_bas ~ presentation_style * training_number + (1|subids) + (presentation_style * training_number|stim_category), data=data_clean_basicMeans_firstBlock_devCoded)
fullModelWithoutInteraction <- lmer(prop_bas ~ presentation_style + training_number + (1|subids) + (presentation_style * training_number|stim_category), data=data_clean_basicMeans_firstBlock_devCoded)
anova(fullModelWithInteraction,fullModelWithoutInteraction)


#########################
#########################
## Repeat first-block trials analysis but with binarized scoring
#########################
#########################
# Drop the 6.7% (104 out of 1560) of trials with mixed test selections
# And treat prop basic-level generalization as a binary variable
data_clean_basicMeans_firstBlock_binScoring <- data_clean_basicMeans_firstBlock
data_clean_basicMeans_firstBlock_binScoring <- data_clean_basicMeans_firstBlock_binScoring %>% as.data.frame %>%
  filter((prop_bas == 0 | prop_bas == 1))
data_clean_basicMeans_firstBlock_binScoring$prop_bas <- as.factor(data_clean_basicMeans_firstBlock_binScoring$prop_bas)
table(data_clean_basicMeans_firstBlock_binScoring$prop_bas)

data_clean_basicMeans_firstBlock_binScoring <- droplevels(data_clean_basicMeans_firstBlock_binScoring)
contrasts(data_clean_basicMeans_firstBlock_binScoring$presentation_style) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans_firstBlock_binScoring$presentation_style)) <- levels(contrasts(data_clean_basicMeans_firstBlock_binScoring$presentation_style))[2]
contrasts(data_clean_basicMeans_firstBlock_binScoring$training_number) <- rbind(-0.5, 0.5)
colnames(contrasts(data_clean_basicMeans_firstBlock_binScoring$training_number)) <- levels(contrasts(data_clean_basicMeans_firstBlock_binScoring$training_number))[2]

summary(glmer(prop_bas ~ presentation_style * training_number + (1|subids) + (1|stim_category), data=data_clean_basicMeans_firstBlock_binScoring, family=binomial))


#########################
#########################
## Generating Plots for Presentation-Style Effect
#########################
#########################
onlyMultipleItems<- data_clean_basicMeans_firstBlock %>% as.data.frame %>% filter((training_number == "three_subordinate"))
# Make bar plot of prop_bas split by presentation_style
onlyMultipleItems %>%
  group_by(presentation_style)%>%
  mutate(prop_bas = as.numeric(prop_bas),
         sd = sd(prop_bas),
         se = sd(prop_bas)/sqrt(length(prop_bas))) %>%
  count(prop_bas, sd, se) %>%
  ungroup() %>%
  group_by(presentation_style) %>%
  mutate(prop = n/sum(n)) -> onlyMultipleItems_dat2

MultipleOnly_ByTiming_PlotForJoint <- ggplot(dsubset(onlyMultipleItems_dat2, prop_bas==1),aes(x=presentation_style, y=prop, fill=presentation_style))+
  stat_summary(fun.y=mean,geom='bar',pos='dodge',width = 0.6)+
  theme(plot.title = element_text(size=30,face = "bold",hjust = 0.5),                            # plot title 
        legend.title = element_text(size=26, face="bold"),                                       # legend title 
        axis.title.x = element_text(size=26,angle=0,hjust=.5,vjust=0,face="bold"),               # x-axis title
        axis.title.y = element_text(size=26,angle=90,hjust=.5,vjust=.5,face="bold"),             # y-axis title
        legend.text = element_text(size = 26, face = "plain"),                                   # legend text
        axis.text.x = element_text(size=26,angle = 40,colour="grey20",hjust=1,face="plain"),
        legend.position="none")+    # x-axis text
  scale_fill_manual(values=c("orange3","grey31"),name="Lewis and Frank (2018)",labels=c("sequential","simultaneous"))+  # fill colour and text
  geom_hline(aes(yintercept = mean(prop)), color="blue")+                           
  geom_errorbar(aes(ymin=prop-se, ymax=prop+se), width=.3, size=.5,position=position_dodge(.9))+
  ylim(0.0, 0.65)+
  labs(y="Proportion Basic Level Generalization",x="Lewis and Frank (2018)", title = "") 


### Numbers from Spencer et al. (2011) SPSS ###
firstBlock_multiple_sequential_prop_bas = 0.533305
firstBlock_multiple_simultaneous_prop_bas = 0.1666473684
firstBlock_multiple_sequential_se = 0.08075002965
firstBlock_multiple_simultaneous_se = 0.05840054642

SPSS_presentationData <- data.frame("presentation_style" = c("sequential","simultaneous"), "prop_bas" = c(1,1), se = c(firstBlock_multiple_sequential_se,firstBlock_multiple_simultaneous_se), prop = c(firstBlock_multiple_sequential_prop_bas,firstBlock_multiple_simultaneous_prop_bas))
SPSS_presentationData %>% group_by(presentation_style) -> SPSS_presentation_dat2

MultipleOnly_ByTiming_Plot_SPSS <- ggplot(dsubset(SPSS_presentation_dat2, prop_bas==1),aes(x=presentation_style, y=prop, fill=presentation_style))+
  stat_summary(fun.y=mean,geom='bar',pos='dodge',width = 0.6)+
  theme(plot.title = element_text(size=30,face = "bold",hjust = 0.5),                            # plot title 
        legend.title = element_text(size=26, face="bold"),                                       # legend title 
        axis.title.x = element_text(size=26,angle=0,hjust=.5,vjust=0,face="bold"),               # x-axis title
        axis.title.y = element_text(size=26, color="White",face="bold"),               # y-axis title
        legend.text = element_text(size = 26, face = "plain"),                                   # legend text
        axis.text.x = element_text(size=26,angle = 40,colour="grey20",hjust=1,face="plain"),
        legend.position="none")+    # x-axis text
  scale_fill_manual(values=c("orange3","grey31"),name="Spencer et al. (2011)",labels=c("sequential","simultaneous"))+  # fill colour and text
  geom_hline(aes(yintercept = mean(prop)), color="blue")+                           
  geom_errorbar(aes(ymin=prop-se, ymax=prop+se), width=.3, size=.5,position=position_dodge(.9))+
  ylim(0.0, 0.65)+
  labs(y="Proportion Basic Level Generalization",x="Spencer et al. (2011)", title = "") 

## Combined Plot
combined_SpencerAndLF_plot = paste(outputDir,'combined-SpencerAndLF-presentationStyle.png',sep="")
combinedPlotObject = plot_grid(MultipleOnly_ByTiming_PlotForJoint,
                               MultipleOnly_ByTiming_Plot_SPSS,
                               ncol = 2,
                               align = 'h',
                               hjust = 4)
jointTitle <- ggdraw() + draw_label("Presentation-Style Effect in Different Papers", fontface='bold',size = 26)
combinedPlotObject = plot_grid(jointTitle, combinedPlotObject, ncol=1, rel_heights=c(0.1, 1))
ggsave(filename=print(combined_SpencerAndLF_plot), width = 16, height = 9, units = "in")


### Make LF plot by stimulus stim_category
onlyMultipleItems<- data_clean_basicMeans_firstBlock %>% as.data.frame %>% filter((training_number == "three_subordinate"))
# Make bar plot of prop_bas split by presentation_style
onlyMultipleItems %>% as.data.frame %>% 
  group_by(presentation_style,stim_category)%>%
  mutate(prop_bas = as.numeric(prop_bas),
         sd = sd(prop_bas),
         se = sd(prop_bas)/sqrt(length(prop_bas))) %>%
  count(prop_bas, sd, se) %>%
  ungroup() %>%
  group_by(presentation_style,stim_category) %>%
  mutate(prop = n/sum(n)) -> onlyMultipleItems_dat3

output_onlyMultipleItems_firstBlock_byTimingAndStimCategory = paste(outputDir,'firstBlock-multipleItems-byTiming-andStim.png',sep="")
MultipleOnly_ByTiming_andStim_Plot <- ggplot(dsubset(onlyMultipleItems_dat3, prop_bas==1),aes(x=stim_category, y=prop, fill=presentation_style))+
  stat_summary(fun.y=mean,geom='bar',pos='dodge',width = 0.8)+
  theme(plot.title = element_text(size=30,face = "bold",hjust = 0.5),                            # plot title 
        legend.title = element_text(size=26, face="bold"),                                       # legend title 
        axis.title.x = element_text(size=26,angle=0,hjust=.5,vjust=0,face="bold"),               # x-axis title
        axis.title.y = element_text(size=26,angle=90,hjust=.5,vjust=.5,face="bold"),             # y-axis title
        legend.text = element_text(size = 26, face = "plain"),                                   # legend text
        axis.text.x = element_text(size=26,angle = 40,colour="grey20",hjust=1,face="plain"),
        legend.position=c(0.7, 0.8))+    # x-axis text
  scale_fill_manual(values=c("orange3","grey31"),name="Presentation Style",labels=c("sequential","simultaneous"))+  # fill colour and text
  geom_errorbar(aes(ymin=prop-se, ymax=prop+se), width=.3, size=.5,position=position_dodge(.8))+
  ylim(0.0, 0.65)+
  labs(y="Proportion Basic-Level Generalization",x="Lewis and Frank (2018)", title = "Presention-Style Effect by Stimulus Category") 
ggsave(output_onlyMultipleItems_firstBlock_byTimingAndStimCategory, width=13.5, height=9, units="in")


## Finished

