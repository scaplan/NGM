
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
suppressMessages(library(ggplot2))
suppressMessages(library(dplyr))
suppressMessages(library(tidyr))
suppressMessages(library(forcats))

#########################
#########################
## Define auxiliary functions
#########################
#########################
makePlot <- function(currData,outputname,currtitle) {
  currPlot <- ggplot(currData,aes(x=GeneralizationLevel, y=Prop, fill=source))+
    stat_summary(fun.y=mean, geom='bar',pos='dodge', width = 0.6)+
    theme(plot.title = element_text(size=30,face = "bold"),                                        # plot title 
          legend.title = element_text(size=26, face="bold"),                                       # legend title 
          axis.title.x = element_text(size=26,angle=0,hjust=.5,vjust=0,face="bold"),               # x-axis title
          axis.title.y = element_text(size=26,angle=90,hjust=.5,vjust=.5,face="bold"),             # y-axis title
          legend.text = element_text(size = 26, face = "plain"),                                   # legend text
          axis.text.x = element_text(size=26,angle = 40,colour="grey20",hjust=1,face="plain"),
          legend.position="none")+    # x-axis text
    scale_fill_manual(values=c("orange3","grey31"),name="Source",labels=c("Human","NGM"))+  # fill colour and text
    geom_errorbar(aes(ymin=lowerError, ymax=upperError), width=.3, size=.5,position=position_dodge(.6))+
    ylim(0.0, 1.0)+
    labs(y="Mean Selections",x="Generalization Set", title = currtitle) 
  ggsave(outputname, width=13.5, height=9, units="in")
}


#########################
#########################
## Read in data
#########################
#########################
workingDir = '' 
outputDir = ''
ngmOutputFile = ''
spssMeansFile = 'SPSS_Results_Means.csv'
spssStdDevFile = 'SPSS_Results_StdDev.csv'


## Parse input args
args = commandArgs(trailingOnly=TRUE)
if (length(args)>4) {
  workingDir = args[1]
  outputDir = args[2]
  ngmOutputFile = args[3]
  spssMeansFile = args[4]
  spssStdDevFile = args[5]
}

setwd(workingDir)
ngmOutputDataRaw = read.csv(ngmOutputFile,header=T,stringsAsFactors=FALSE)
spssMeansData = read.csv(spssMeansFile,header=T,stringsAsFactors=FALSE)
spssStdDevData = read.csv(spssStdDevFile,header=T,stringsAsFactors=FALSE)

ngmOutputMean <- aggregate(cbind(Single, Sub_seq, Basic_seq, Super_seq, Sub_par, Basic_par, Super_par) ~ Proportion, ngmOutputDataRaw, mean)
ngmOutputSD <- aggregate(cbind(Single, Sub_seq, Basic_seq, Super_seq, Sub_par, Basic_par, Super_par) ~ Proportion, ngmOutputDataRaw, sd)

# Convert SPSS from wide to long
spssDataMeanLong <- gather(spssMeansData, ExpType, Prop, Single:Super_par, factor_key=TRUE)
spssDataSDLong <- gather(spssStdDevData, ExpType, Prop, Single:Super_par, factor_key=TRUE)
spssDataMeanLong <- spssDataMeanLong[c("ExpType", "Proportion", "Prop")]
spssDataSDLong <- spssDataSDLong[c("ExpType", "StdDev", "Prop")]
names(spssDataMeanLong)[names(spssDataMeanLong) == 'Proportion'] <- 'GeneralizationLevel'
names(spssDataSDLong)[names(spssDataSDLong) == 'StdDev'] <- 'GeneralizationLevel'
names(spssDataSDLong)[names(spssDataSDLong) == 'Prop'] <- 'SD'
# Merge SPSS means and SD data
spssDataMeanLong$SD <- spssDataSDLong$SD
spssDataMeanLong$source <- 'Human'

# Convert NGM output from wide to long
ngmOutputMeanLong <- gather(ngmOutputMean, ExpType, Prop, Single:Super_par, factor_key=TRUE)
ngmOutputSDLong <- gather(ngmOutputSD, ExpType, Prop, Single:Super_par, factor_key=TRUE)
ngmOutputMeanLong <- ngmOutputMeanLong[c("ExpType", "Proportion", "Prop")]
ngmOutputSDLong <- ngmOutputSDLong[c("ExpType", "Proportion", "Prop")]
names(ngmOutputMeanLong)[names(ngmOutputMeanLong) == 'Proportion'] <- 'GeneralizationLevel'
names(ngmOutputSDLong)[names(ngmOutputSDLong) == 'Proportion'] <- 'GeneralizationLevel'
names(ngmOutputSDLong)[names(ngmOutputSDLong) == 'Prop'] <- 'SD'
# Merge NGM means and SD data
ngmOutputMeanLong$SD <- ngmOutputSDLong$SD
ngmOutputMeanLong$source <- 'NGM'

# Cat NGM and human data
combinedData <- rbind(spssDataMeanLong, ngmOutputMeanLong)

combinedData <- combinedData %>%
  mutate(
    GeneralizationLevel = fct_recode(GeneralizationLevel, Subordinate = "0_SUBORDINATE"),
    GeneralizationLevel = fct_recode(GeneralizationLevel, Basic = "1_BASIC"),
    GeneralizationLevel = fct_recode(GeneralizationLevel, Superordinate = "2_SUPERORDINATE"))

combinedData$source <- as.character(combinedData$source)

# Add columns for upper and lower error bars
combinedData$lowerError <- combinedData$Prop - combinedData$SD
combinedData$upperError <- combinedData$Prop + combinedData$SD
combinedData$lowerError[combinedData$lowerError < 0.0] <- 0.0
combinedData$upperError[combinedData$upperError > 1.0] <- 1.0

# Filter to only just those to plot
singleData <- combinedData %>% filter((ExpType == "Single"))
subSeqData <- combinedData %>% filter((ExpType == "Sub_seq"))
basicSeqData <- combinedData %>% filter((ExpType == "Basic_seq"))
superSeqData <- combinedData %>% filter((ExpType == "Super_seq"))
subParData <- combinedData %>% filter((ExpType == "Sub_par"))
basicParData <- combinedData %>% filter((ExpType == "Basic_par"))
superParData <- combinedData %>% filter((ExpType == "Super_par"))


#########################
#########################
## Call plotting function
#########################
#########################
outputname = paste(outputDir,'singleDataPlot.png',sep="")
plottitle = 'Single Item Training'
makePlot(singleData,outputname,plottitle)

outputname = paste(outputDir,'subSeqDataPlot.png',sep="")
plottitle = 'Sequential Subortinate Training'
makePlot(subSeqData,outputname,plottitle)

outputname = paste(outputDir,'basicSeqDataPlot.png',sep="")
plottitle = 'Sequential Basic Training'
makePlot(basicSeqData,outputname,plottitle)

outputname = paste(outputDir,'superSeqDataPlot.png',sep="")
plottitle = 'Sequential Superordinate Training'
makePlot(superSeqData,outputname,plottitle)

outputname = paste(outputDir,'subParDataPlot.png',sep="")
plottitle = 'Simultaneous Subortinate Training'
makePlot(subParData,outputname,plottitle)

outputname = paste(outputDir,'basicParDataPlot.png',sep="")
plottitle = 'Simultaneous Basic Training'
makePlot(basicParData,outputname,plottitle)

outputname = paste(outputDir,'superParDataPlot.png',sep="")
plottitle = 'Simultaneous Superordinate Training'
makePlot(superParData,outputname,plottitle)


## Finished
