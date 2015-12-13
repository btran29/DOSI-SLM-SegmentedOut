# Ver 12-6-15 Brian
# Main Method for data analysis


# Input
hasExeData = FALSE
keyWords = "Brain"  # e.g. "PFC|VL|Muscle|Brain"
seg.it = 10


# Load required packages
library(segmented)


# Source functions for piecewise-linear regression analysis of DOS data
# Assumes scripts are in the working directory. Manually source if need be
source('exeEquivCSV.r') # Includes exeEquivCSV
source('dosSegmented.r') # Includes DOSI.segmented, linearize
source('collectBPdata.r') # Includes collectBPdata, writeBPData, bpFigures 
source('collectExeData.r') # Includes collectExeData, writeExeData


# Organizing output into folders via labels (use for later output)
breakpointDataFolder		<- "breakpoint data"
percentExerciseDataFolder	<- "percent exercise data"
segmentedFiguresFolder		<- "segmented figures"
dir.create(breakpointDataFolder, showWarnings=FALSE)
dir.create(percentExerciseDataFolder, showWarnings=FALSE)
dir.create(segmentedFiguresFolder,showWarnings=FALSE)


# List studies of interest
csv			<- dir(pattern="*csv")
csv			<- csv[grepl("Ramp",csv)]
dosStudies	<- csv[grep(keyWords,csv)]


# Obtain study-specific breakpoint guess inputs for segmented function
setwd("batch files")
	table <- read.csv("segmentedBatchFile.csv")
setwd("..")


# Loop for each optical data file
for(study in 1:length(dosStudies)){

	# Filename for output
	outputFileName	<- gsub(".csv", "", dosStudies[study])
	
	if(hasExeData){
	# Locate equivalent exercise study
	equivExeStudy	<- exeEquivCSV(dosStudies[study],csv,
					locEXO=1,locVisit=3,locDate=4)	
	}

	# Read csv files into data tables
	dosData	<-	read.csv(dosStudies[study])
	
	if(hasExeData){
	exeData	<-	read.csv(csv[equivExeStudy])
	}
	
	# Assign data in files to data frames #
	
	
	# Assign DOS or EXE-specific time axes, normalizing DOS to begin at 0
	Time     <- dosData$time
	normTime <- Time-min(Time)
	
	if(hasExeData){
	exeTime  <- exeData$time
	}
	
	# Make data frames from variables of interest
		HbO2  <- data.frame(x=normTime, y=dosData$HbO2)
		HbR   <- data.frame(x=normTime, y=dosData$HbR)
		THb   <- data.frame(x=normTime, y=dosData$THb)
		stO2  <- data.frame(x=normTime, y=dosData$stO2)
		
		if(hasExeData){
		  VEO <- data.frame(x=exeTime, y=exeData$VEO)
		  VEC <- data.frame(x=exeTime, y=exeData$VEC)
		  PO  <- data.frame(x=exeTime, y=exeData$PO)
		  PC  <- data.frame(x=exeTime, y=exeData$PC)
		  VO  <- data.frame(x=exeTime, y=exeData$VO2)
		  VOK <- data.frame(x=exeTime, y=exeData$VOK)
		  VC  <- data.frame(x=exeTime, y=exeData$VCO2)
		  VE  <- data.frame(x=exeTime, y=exeData$VE)
		  HR  <- data.frame(x=exeTime, y=exeData$HR)
		  RR  <- data.frame(x=exeTime, y=exeData$RR)
		  RPM <- data.frame(x=exeTime, y=exeData$RPM)
		  W   <- data.frame(x=exeTime, y=exeData$Work)
		}

	
	# Conver data to linear models (without any transformations), 
	# using a dos or exe-specific time axis
	lin	<- list(
	  "HbO2"  = lm.BO  <- lm(y~x,data=HbO2),
	  "HbR"  = lm.BR  <- lm(y~x,data=HbR),
	  "THb"  = lm.BT  <- lm(y~x,data=THb),
	  "stO2"  = lm.BS  <- lm(y~x,data=stO2)
	)

	if(hasExeData){
	  lm.EXEdata <- list(
	    "VEO" = lm.VEO <- lm(y~x,data=VEO),
	    "VEC" = lm.VC  <- lm(y~x,data=VEC),
	    "PO"  = lm.PO  <- lm(y~x,data=PO),
	    "PC"  = lm.PC  <- lm(y~x,data=PC),
	    "VO"  = lm.VO  <- lm(y~x,data=VO),
	    "VC"  = lm.VC  <- lm(y~x,data=VC),
	    "VE"  = lm.VE  <- lm(y~x,data=VE),
	    "HR"  = lm.HR  <- lm(y~x,data=HR),
	    "RR"  = lm.RR  <- lm(y~x,data=RR),
	    "RPM" = lm.RPM <- lm(y~x,data=RPM)
	  )
	}
	
	# Combine to run segmented
	if(hasExeData){
		lin <- c(lin,lm.EXEdata)
	}	
		
	# Run segmented #
	
	
	# Obtain breakpoints input for segmented function
	segmentedMethod	<- table$SpecifSegmentedBPs[study]
	segmentedBP1	<- table$FirstGuess[study]
	segmentedBP2	<- table$SecondGuess[study]
	
	# Run segmented
	bpOutput	<- sapply(lin,DOSI.segmented,
				segmentedMethod,segmentedBP1,segmentedBP2,
				simplify=FALSE,USE.NAMES=TRUE)
		
		
	# Compare BP data with exe data
	if(hasExeData){
	
	# Set span over which to mean exercise data for each breakpoint
	span = (5/60) # Mean +/- 5 seconds, assuming data in minutes
	
	
	# Output BP data using span and collectBPdata function
	bpOutput2<-sapply(bpOutput,collectBPdata,span,simplify=FALSE,USE.NAMES=TRUE)
	
	
	# Collect and output exercise data
	setwd(percentExerciseDataFolder)
		writeExeData(collectExeData(0,span=0),"MinWR",outputFileName)
		writeExeData(collectExeData(0.2,span=0),"E20",outputFileName)
		writeExeData(collectExeData(0.4,span=0),"E40",outputFileName)
		writeExeData(collectExeData(0.6,span=0),"E60",outputFileName)
		writeExeData(collectExeData(0.8,span=0),"E80",outputFileName)
		writeExeData(collectExeData(1,span=0),"MaxWR",outputFileName)
	setwd("..")
	} else {
		  bpOutput2 <-sapply(bpOutput,collectBPdata,span,hasExeData=FALSE,simplify=FALSE,USE.NAMES=TRUE)
		}	
	
	
	# Write segmented data into a csv file
	setwd(breakpointDataFolder)
		writeBPdata(bpOutput,bpOutput2,outputFileName)
	setwd("..")
	
	
	# Figures #

	# Plot figures - Used try statements as some data is known to be too 
	# noisy to all have breakpoints or successful
	setwd(segmentedFiguresFolder)
	
		tiffoutput <- function(VarName){
  		  tiff(paste(VarName,outputFileName,"Figure.tiff",sep=" "), units = "px", width = 600, height = 600, res = NA, compression = "lzw")
  		}

  		tiffoutput("HbR")
  		try({bpFigures(bpOutput$HbR,"Time (min)","[HbR] (uM)","PFC HbR")})
  		dev.off()

  		tiffoutput("stO2")
  		try({bpFigures(bpOutput$stO2,"Time (min)","stO2 (uM)","PFC stO2")})
  		dev.off()

  		tiffoutput("HbO2")
  		try({bpFigures(bpOutput$HbO2,"Time (min)","HbO2 (uM)","PFC HbO2")})
  		dev.off()

  		tiffoutput("THb")
  		try({bpFigures(bpOutput$THb,"Time (min)","THb (uM)","PFC THb")})
  		dev.off()

  		if(hasExeData){
  			try({bpFigures(bpOutput$VE,"Time (min)","VE (L/min)","VE")})
  			try({bpFigures(bpOutput$PC,"Time (min)","PETCO2 mmHg","PETCO2")})
  			}
  			
	setwd("..")
	
	
	# Remove data for each study after output to tables and figures to prevent writing
	# previous study's data to the next study
	remove(bpOutput)
	remove(bpOutput2)
}
