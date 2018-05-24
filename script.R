##################################################################################################
#####

## [SC] path where R source code is located
sourcepath <- ""  ## [SC] set your path here
## [SC] path where data is located
datapath <- paste0(sourcepath, "data/")

#####
##################################################################################################


## [SC] installing gplots package
if (!("gplots" %in% rownames(installed.packages()))) {
	print("Installing 'gplots' package ...")
	install.packages("gplots")
}
library("gplots")

## [SC] installing sm package
if (!("sm" %in% rownames(installed.packages()))) {
	print("Installing 'sm' package ...")
	install.packages("sm")
}
library("sm")

## [SC] installing lme4 package
if (!("lme4" %in% rownames(installed.packages()))) {
	print("Installing 'lme4' package ...")
	install.packages("lme4")
}
library("lme4")

## [SC] installing car package for the scatterplot
if (!("car" %in% rownames(installed.packages()))) {
	print("Installing 'car' package ...")
	install.packages("car")
}
library("car")

## [SC] installing pracma package for the polyarea
#if (!("pracma" %in% rownames(installed.packages()))) {
#	print("Installing 'pracma' package ...")
#	install.packages("pracma")
#}
#library("pracma")

## [SC] installing geometry package for the polyarea
if (!("geometry" %in% rownames(installed.packages()))) {
	print("Installing 'geometry' package ...")
	install.packages("geometry")
}
library("geometry")

source(paste0(sourcepath, "commonCode.R"))


modeOldEquation <<- "old" ## [TODO]
modeNewEquation <<- "new" ## [TODO]

fullLength <- 1383964
maxLength <- 700000
iterationCount <- 10

conditionOld <- "CAP"
conditionNew <- "TwoA"

samplingStepSize <- 1000

loadBaseData <- function() {
	return(read.table(paste0(datapath, "user_data.txt")
		, stringsAsFactors=FALSE, header=TRUE))
}

loadBaseRatings <- function() {
	return(read.table(paste0(datapath, "baseRatings.txt")
		, stringsAsFactors=FALSE, header=TRUE))
}

loadRatingData <- function(mode, iteration) {
	return(read.table(paste0(datapath, "ratings_", mode, "_", iteration, ".txt")
		, stringsAsFactors=FALSE, header=TRUE))
}

plotMeanRatingPerProblem <- function(){
	op <- par(mfrow=c(1,2))

	baseDF <- loadBaseData()
	
	rtMeanDF <- aggregate(RT ~ ItemID + SetLevel + MirrorID, baseDF, mean)
	colnames(rtMeanDF)[colnames(rtMeanDF)=="RT"] <- "RTMean"
	rtSEDF <- aggregate(RT ~ ItemID + SetLevel + MirrorID, baseDF, getSE)
	colnames(rtSEDF)[colnames(rtSEDF)=="RT"] <- "RTSE"

	oldDF <- NULL
	newDF <- NULL
	for(iteration in 0:(iterationCount-1)){
		tempOldDF <- loadRatingData(modeOldEquation, iteration)
		tempOldDF <- cbind(tempOldDF, Iteration=iteration)
		if(is.null(oldDF)) { oldDF <- tempOldDF }
		else { oldDF <- rbind(oldDF, tempOldDF) }

		tempNewDF <- loadRatingData(modeNewEquation, iteration)
		tempNewDF <- cbind(tempNewDF, Iteration=iteration)
		if(is.null(newDF)) { newDF <- tempNewDF }
		else { newDF <- rbind(newDF, tempNewDF) }
	}

	oldRatingMeanDF <- aggregate(Rating ~ ScenarioID + SetLevel + MirrorID, oldDF, mean)
	colnames(oldRatingMeanDF)[colnames(oldRatingMeanDF)=="Rating"] <- "OldRatingMean" 
	oldRatingSEDF <- aggregate(Rating ~ ScenarioID + SetLevel + MirrorID, oldDF, getSE)
	colnames(oldRatingSEDF)[colnames(oldRatingSEDF)=="Rating"] <- "OldRatingSE"

	newRatingMeanDF <- aggregate(Rating ~ ScenarioID + SetLevel + MirrorID, newDF, mean)
	colnames(newRatingMeanDF)[colnames(newRatingMeanDF)=="Rating"] <- "NewRatingMean" 
	newRatingSEDF <- aggregate(Rating ~ ScenarioID + SetLevel + MirrorID, newDF, getSE)
	colnames(newRatingSEDF)[colnames(newRatingSEDF)=="Rating"] <- "NewRatingSE"

	ratingMeanDF <- merge(oldRatingMeanDF, oldRatingSEDF)
	ratingMeanDF <- merge(ratingMeanDF, newRatingMeanDF)
	ratingMeanDF <- merge(ratingMeanDF, newRatingSEDF)
	colnames(ratingMeanDF)[colnames(ratingMeanDF)=="ScenarioID"] <- "ItemID"

	overallDF <- merge(rtMeanDF, rtSEDF)
	overallDF <- merge(overallDF, ratingMeanDF)

	overallDF$OldRatingMean <- round(overallDF$OldRatingMean, 4)
	overallDF$OldRatingSE <- round(overallDF$OldRatingSE, 4)
	overallDF$NewRatingMean <- round(overallDF$NewRatingMean, 4)
	overallDF$NewRatingSE <- round(overallDF$NewRatingSE, 4)
	overallDF$RTMean <- round(overallDF$RTMean, 4)
	overallDF$RTSE <- round(overallDF$RTSE, 4)

	overallDF <- overallDF[order(overallDF$RTMean),]

	par(mar=c(5.1,4.1,4.1,5.1))
	plotCI(overallDF$OldRatingMean, uiw=overallDF$OldRatingSE, type="p", lwd=2, ylim=c(-2.5, 0)
		, col=overallDF$SetLevel, pch=overallDF$SetLevel
		, xlab="Problems", ylab="Mean ratings", main="CAP")
	par(new=TRUE)
	plotCI(overallDF$RTMean, uiw=overallDF$RTSE, type="p", lwd=2, ylim=c(6000, 20000)
		, col=5, pch=5
		, xaxt="n", yaxt="n", xlab="", ylab="")
	axis(4)
	mtext("Mean RT (ms)", side=4, line=3)
	legend("bottomright", lwd=2, col=1:5, pch=1:5
		, legend=c("Rating - Set level 1"
				, "Rating - Set level 2"
				, "Rating - Set level 3"
				, "Rating - Set level 4"
				, "Response time")
	)

	op <- par(mar=c(5.1,4.1,4.1,5.1))
	plotCI(overallDF$NewRatingMean, uiw=overallDF$NewRatingSE, type="p", lwd=2, ylim=c(-2.5, 0)
		, col=overallDF$SetLevel, pch=overallDF$SetLevel
		, xlab="Problems", ylab="Mean ratings", main="TwoA")
	par(new=TRUE)
	plotCI(overallDF$RTMean, uiw=overallDF$RTSE, type="p", lwd=2, ylim=c(6000, 20000)
		, col=5, pch=5
		, xaxt="n", yaxt="n", xlab="", ylab="")
	axis(4)
	mtext("Mean RT (ms)", side=4, line=3)

	print(overallDF)

	print(cor.test(overallDF$NewRatingMean, overallDF$OldRatingMean))

	print(mean(abs(overallDF$NewRatingMean - overallDF$OldRatingMean)))
	print(getSE(abs(overallDF$NewRatingMean - overallDF$OldRatingMean)))

	print(cor.test(overallDF$RTMean, overallDF$OldRatingMean))
	print(cor.test(overallDF$NewRatingMean, overallDF$RTMean))
	par(op)
}

plotFreqDist <- function(){
	oldDF <- NULL
	newDF <- NULL
	for(iteration in 0:(iterationCount-1)){
		tempOldDF <- loadRatingData(modeOldEquation, iteration)
		tempOldDF <- cbind(tempOldDF, Iteration=iteration)
		if(is.null(oldDF)) { oldDF <- tempOldDF }
		else { oldDF <- rbind(oldDF, tempOldDF) }

		tempNewDF <- loadRatingData(modeNewEquation, iteration)
		tempNewDF <- cbind(tempNewDF, Iteration=iteration)
		if(is.null(newDF)) { newDF <- tempNewDF }
		else { newDF <- rbind(newDF, tempNewDF) }
	}

	oldDF <- cbind(oldDF, Condition=conditionOld)
	newDF <- cbind(newDF, Condition=conditionNew)
	overallDF <- rbind(oldDF, newDF)
	aggrDF <- aggregate(PlayCount ~ Condition + SetLevel + ScenarioID, overallDF, mean)

	op <- par(mfrow=c(1,1))
	boxplot(PlayCount ~ Condition + SetLevel, aggrDF
		, xlab="[Condition].[Set level]"
		, ylab="Problem frequency"
		, main="Problem frequencies at the end of the simulations"
	)
	par(op)

	for(setLevel in 1:4) {
		for(condition in unique(aggrDF$Condition)){
			print(paste0("Standard deviation for set level ", setLevel, " and condition ", condition))
			print(sd(subset(aggrDF, SetLevel == setLevel & Condition == condition)$PlayCount))
		}
	}
}

plotFreqSEDist <- function(){
	oldDF <- NULL
	newDF <- NULL
	for(iteration in 0:(iterationCount-1)){
		tempOldDF <- loadRatingData(modeOldEquation, iteration)
		tempOldDF <- cbind(tempOldDF, Iteration=iteration)
		if(is.null(oldDF)) { oldDF <- tempOldDF }
		else { oldDF <- rbind(oldDF, tempOldDF) }

		tempNewDF <- loadRatingData(modeNewEquation, iteration)
		tempNewDF <- cbind(tempNewDF, Iteration=iteration)
		if(is.null(newDF)) { newDF <- tempNewDF }
		else { newDF <- rbind(newDF, tempNewDF) }
	}

	aggrOldDF <- aggregate(PlayCount ~ SetLevel + ScenarioID, oldDF, getSE)
	aggrOldDF <- cbind(aggrOldDF, Condition=conditionOld)
	aggrNewDF <- aggregate(PlayCount ~ SetLevel + ScenarioID, newDF, getSE)
	aggrNewDF <- cbind(aggrNewDF, Condition=conditionNew)
	
	lmDF <- rbind(aggrOldDF, aggrNewDF)
	lmDF$SetLevel <- lmDF$SetLevel - 1 
	lmRes <- lmer(PlayCount ~ SetLevel * Condition + (1|ScenarioID), lmDF)
	print(summary(lmRes))
	lmRes <- lm(PlayCount ~ SetLevel * Condition, lmDF)
	print(summary(lmRes))
	
	colnames(aggrOldDF)[colnames(aggrOldDF)=="PlayCount"] <- "OrgPlayCountSE"
	colnames(aggrNewDF)[colnames(aggrNewDF)=="PlayCount"] <- "NewPlayCountSE"
	aggrDF <- merge(aggrOldDF, aggrNewDF, by=c("ScenarioID", "SetLevel"))

	aggrDF <- aggrDF[order(aggrDF$SetLevel),]

	op <- par(mfrow=c(1,1))
	plot(aggrDF$OrgPlayCountSE, type="p", lwd=2, pch=1
		, ylim=c(0, max(aggrDF$OrgPlayCountSE, aggrDF$NewPlayCountSE))
		, xlab="Problems", ylab="Standard error", main="Standard errors for problem frequencies")
	lines(aggrDF$NewPlayCountSE, type="p", lwd=2, pch=2)
	legend("topright", legend=c(conditionOld, conditionNew), pch=1:2)
	for(setLevel in 1:3) {
		abline(v=setLevel*20, lty=2)
	}
	par(op)
}

plotGameplayFreqMeans <- function(setLevel, yLim=c(0, 30000), plotSE=FALSE, maxPlotNumber=20){
	baseRatingsDF <- loadBaseRatings()
	baseRatingsDF <- baseRatingsDF[order(baseRatingsDF$SetLevel),]
	baseRatingsDF <- subset(baseRatingsDF, baseRatingsDF$SetLevel == setLevel)

	op <- par(mfrow=c(1,2))

	myYlab <- "Mean cummulative frequency"
	if (plotSE) {
		myYlab <- "SE for mean cummulative frequency"
	}

	samplingIDVC <- seq(1, fullLength, by=samplingStepSize)
	
	plot(1, 1, type="l", xlim=c(0, fullLength), ylim=yLim
		, main=paste0("Set level ", setLevel, "; ", conditionOld)
		, xlab="Matches", ylab=myYlab)
	colorIndex <- 1
	plotSECounter <- 0
	for(itemID in baseRatingsDF$itemid) {
		itemFreqMeanDF <- read.table(paste0(datapath, "scenarioFreqMeans_", modeOldEquation, "_", itemID, ".txt")
						, stringsAsFactors=FALSE, header=TRUE)

		itemFreqMeanDF <- subset(itemFreqMeanDF, ID %in% samplingIDVC)

		lineType <- 1 + floor((colorIndex-1)/8)

		if(plotSE && "FreqSE" %in% colnames(itemFreqMeanDF)){
			myColor <- c(col2rgb(colorIndex)[,1], 100, 255)
			polygon(col=rgb(myColor[1],myColor[2],myColor[3],myColor[4],max=myColor[5]), border=NA, lty=lineType
				, y=c(itemFreqMeanDF$FreqMean + itemFreqMeanDF$FreqSE
					, rev(itemFreqMeanDF$FreqMean - itemFreqMeanDF$FreqSE))
				, x=c(itemFreqMeanDF$ID, rev(itemFreqMeanDF$ID))
				)

			plotSECounter <- plotSECounter + 1
			if(plotSECounter == maxPlotNumber) {
				break
			} 
		} else {
			lines(x=itemFreqMeanDF$ID, y=itemFreqMeanDF$FreqMean, type="l", col=colorIndex, lty=lineType)
		}

		colorIndex <- colorIndex + 1
	}

	plot(1, 1, type="l", xlim=c(0, fullLength), ylim=yLim
		, main=paste0("Set level ", setLevel, "; ", conditionNew)
		, xlab="Matches", ylab=myYlab)
	colorIndex <- 1
	plotSECounter <- 0
	for(itemID in baseRatingsDF$itemid) {
		itemFreqMeanDF <- read.table(paste0(datapath, "scenarioFreqMeans_", modeNewEquation, "_", itemID, ".txt")
						, stringsAsFactors=FALSE, header=TRUE)
		
		itemFreqMeanDF <- subset(itemFreqMeanDF, ID %in% samplingIDVC)

		lineType <- 1 + floor((colorIndex-1)/8)

		if(plotSE && "FreqSE" %in% colnames(itemFreqMeanDF)){
			myColor <- c(col2rgb(colorIndex)[,1], 100, 255)
			polygon(col=rgb(myColor[1],myColor[2],myColor[3],myColor[4],max=myColor[5]), border=NA, lty=lineType
				, y=c(itemFreqMeanDF$FreqMean + itemFreqMeanDF$FreqSE
					, rev(itemFreqMeanDF$FreqMean - itemFreqMeanDF$FreqSE))
				, x=c(itemFreqMeanDF$ID, rev(itemFreqMeanDF$ID))
				)

			plotSECounter <- plotSECounter + 1
			if(plotSECounter == maxPlotNumber) {
				break
			} 
		} else {
			lines(x=itemFreqMeanDF$ID, y=itemFreqMeanDF$FreqMean, type="l", col=colorIndex, lty=lineType)
		}

		colorIndex <- colorIndex + 1
	}

	par(op)
}

plotGameplayRatingMeans <- function(setLevels, yLim=list(c(-3.0, 0)), plotSE=FALSE, maxPlotNumber=20){
	orgBaseRatingsDF <- loadBaseRatings()
	orgBaseRatingsDF <- orgBaseRatingsDF[order(orgBaseRatingsDF$SetLevel),]

	#baseRatingsDF <- baseRatingsDF[order(baseRatingsDF$SetLevel),]
	#baseRatingsDF <- subset(baseRatingsDF, baseRatingsDF$SetLevel == setLevel)

	samplingIDVC <- seq(1, fullLength, by=samplingStepSize)

	op <- par(mfrow=c(length(setLevels), 2))

	for (currIndex in 1:length(setLevels)) {

	setLevel <- setLevels[currIndex]

	baseRatingsDF <- subset(orgBaseRatingsDF, SetLevel == setLevel)

	plot(1, 1, type="l", xlim=c(0, fullLength), ylim=yLim[[currIndex]]
		, main=paste0("Set level: ", setLevel, "; ", conditionOld)
		, xlab="Matches", ylab="Rating")
	colorIndex <- 1
	plotSECounter <- 0
	for(itemID in baseRatingsDF$itemid) {
		itemMeanRatingDF <- read.table(paste0(datapath, "scenarioRatingMeans_", modeOldEquation, "_", itemID, ".txt")
						, stringsAsFactors=FALSE, header=TRUE)
		
		itemMeanRatingDF <- subset(itemMeanRatingDF, ID %in% samplingIDVC)
		
		if(plotSE && "ScenarioRatingSE" %in% colnames(itemMeanRatingDF)){
			myColor <- c(col2rgb(colorIndex)[,1], 100, 255)
			polygon(col=rgb(myColor[1],myColor[2],myColor[3],myColor[4],max=myColor[5]), border=NA
				, y=c(itemMeanRatingDF$ScenarioRatingMean + itemMeanRatingDF$ScenarioRatingSE
					, rev(itemMeanRatingDF$ScenarioRatingMean - itemMeanRatingDF$ScenarioRatingSE))
				, x=c(itemMeanRatingDF$ID, rev(itemMeanRatingDF$ID))
				)

			plotSECounter <- plotSECounter + 1
			if(plotSECounter == maxPlotNumber) {
				break
			} 
		} else {
			lines(x=itemMeanRatingDF$ID, y=itemMeanRatingDF$ScenarioRatingMean, type="l", col=colorIndex, lty=1)
		}

		colorIndex <- colorIndex + 1
	}

	plot(1, 1, type="l", xlim=c(0, fullLength), ylim=yLim[[currIndex]]
		, main=paste0("Set level: ", setLevel, "; ", conditionNew)
		, xlab="Matches", ylab="Rating")
	colorIndex <- 1
	plotSECounter <- 0
	for(itemID in baseRatingsDF$itemid) {
		itemMeanRatingDF <- read.table(paste0(datapath, "scenarioRatingMeans_", modeNewEquation, "_", itemID, ".txt")
						, stringsAsFactors=FALSE, header=TRUE)
		
		itemMeanRatingDF <- subset(itemMeanRatingDF, ID %in% samplingIDVC)
		
		if(plotSE && "ScenarioRatingSE" %in% colnames(itemMeanRatingDF)){
			myColor <- c(col2rgb(colorIndex)[,1], 100, 255)
			polygon(col=rgb(myColor[1],myColor[2],myColor[3],myColor[4],max=myColor[5]), border=NA
				, y=c(itemMeanRatingDF$ScenarioRatingMean + itemMeanRatingDF$ScenarioRatingSE
					, rev(itemMeanRatingDF$ScenarioRatingMean - itemMeanRatingDF$ScenarioRatingSE))
				, x=c(itemMeanRatingDF$ID, rev(itemMeanRatingDF$ID))
				)

			plotSECounter <- plotSECounter + 1
			if(plotSECounter == maxPlotNumber) {
				break
			} 
		} else {
			lines(x=itemMeanRatingDF$ID, y=itemMeanRatingDF$ScenarioRatingMean, type="l", col=colorIndex, lty=1)
		}

		colorIndex <- colorIndex + 1
	}

	}

	par(op)
}

plotMeanRatingStablePoints <- function(medians=TRUE){
	stablePointsDF <- read.table(paste0(datapath, "stablePointsAllItems.txt")
								, header=TRUE, stringsAsFactors=FALSE)
	colnames(stablePointsDF)[colnames(stablePointsDF)=="ItemID"] <- "itemid"

	baseRatingsDF <- loadBaseRatings()
	stablePointsDF <- merge(stablePointsDF, baseRatingsDF[,c("itemid", "SetLevel")])

	print(stablePointsDF)

	op <- par(mfrow=c(1,1), ask=TRUE)

	mediansDF <- stablePointsDF

	if (medians) {
		#### [SC] scatter plot of median stable points
		mediansDF <- aggregate(StablePointOld ~ itemid + SetLevel , stablePointsDF, median, na.rm=TRUE)
		mediansDF <- merge(mediansDF, aggregate(StablePointNew ~ itemid + SetLevel, stablePointsDF, median, na.rm=TRUE))
	}

	maxVal <- max(mediansDF[,c("StablePointOld", "StablePointNew")], na.rm=TRUE)
	minVal <- min(mediansDF[,c("StablePointOld", "StablePointNew")], na.rm=TRUE)

	
	plot(x=mediansDF$StablePointOld, y=mediansDF$StablePointNew, type="p"
		, pch=mediansDF$SetLevel
		, col=mediansDF$SetLevel
		, ylim=c(minVal, maxVal), xlim=c(minVal, maxVal)
		, main=paste0("Scatterplot of rating convergence end points.")
		, xlab=conditionOld, ylab=conditionNew)

	abline(lm(StablePointNew ~ StablePointOld, data=mediansDF), col="black", lwd=2)
	abline(a=0, b=1, col="black", lwd=1, lty=2)

	print(summary(lm(StablePointNew ~ StablePointOld, data=mediansDF)))

	legend("topleft", title="Set level"
			, legend=sort(unique(mediansDF$SetLevel))
			, pch=sort(unique(mediansDF$SetLevel))
			, col=sort(unique(mediansDF$SetLevel)))

	par(op)

	perc <- (mediansDF$StablePointOld - mediansDF$StablePointNew)/mediansDF$StablePointOld
	print(paste(min(perc), mean(perc), max(perc)))

	print(mean(mediansDF$StablePointOld/mediansDF$StablePointNew))
	print(min(mediansDF$StablePointOld/mediansDF$StablePointNew))
	print(max(mediansDF$StablePointOld/mediansDF$StablePointNew))

	mediansDF <- cbind(mediansDF, Factor=mediansDF$StablePointOld/mediansDF$StablePointNew)
	print(mediansDF[order(mediansDF$Factor),])
	print(nrow(subset(mediansDF, Factor >= 2)))
}

plotItemRatingWithStablePoint <- function(itemid){
	itemMeanRatingOldDF <- read.table(paste0(datapath, "scenarioRatingMeans_", modeOldEquation, "_", itemid, ".txt")
						, stringsAsFactors=FALSE, header=TRUE)
	itemMeanRatingNewDF <- read.table(paste0(datapath, "scenarioRatingMeans_", modeNewEquation, "_", itemid, ".txt")
						, stringsAsFactors=FALSE, header=TRUE)

	stablePointsDF <- read.table(paste0(datapath, "stablePointsAllItems.txt")
								, header=TRUE, stringsAsFactors=FALSE)
	stablePointsDF <- subset(stablePointsDF , ItemID == itemid)


	baseRatingsDF <- loadBaseRatings()
	setLevel <- baseRatingsDF[baseRatingsDF$itemid==itemid,]$SetLevel[1]


	samplingInterval <- 10000
	samplePoints <- numeric(1)
	while(samplePoints[length(samplePoints)] < fullLength) {
		samplePoints <- c(samplePoints, samplePoints[length(samplePoints)] + samplingInterval)
	}
	itemMeanRatingOldDF <- subset(itemMeanRatingOldDF, ID %in% samplePoints)
	itemMeanRatingNewDF <- subset(itemMeanRatingNewDF, ID %in% samplePoints)


	plot(y=itemMeanRatingOldDF$ScenarioRatingMean, x=itemMeanRatingOldDF$ID
		, type="l", lty=1, col=1, lwd=2
		, main=paste0("Problem id: ", itemid, "; Set level: ", setLevel)
		, xlab="Matches", ylab="Difficulty rating", ylim=c(-2, 0))
	for(stablePoint in stablePointsDF$StablePointOld){
		if (!is.na(stablePoint)) {
			abline(v=stablePoint, lty=1, col=1)
		}
	}

	lines(y=itemMeanRatingNewDF$ScenarioRatingMean, x=itemMeanRatingNewDF$ID
		, type="l", lty=2, col=4, lwd=2)
	for(stablePoint in stablePointsDF$StablePointNew){
		if (!is.na(stablePoint)) {
			abline(v=stablePoint, lty=2, col=4)
		}
	}

	legend("topright", legend=c(conditionOld, conditionNew), lty=1:2, col=c(1, 4))
}

analyzeRatingDispersion <- function(){
	if (FALSE) {
	stablePointsDF <- read.table(paste0(datapath, "stablePointsAllItems.txt")
								, header=TRUE, stringsAsFactors=FALSE)
	colnames(stablePointsDF)[colnames(stablePointsDF)=="ItemID"] <- "itemid"
	
	mediansOldDF <- aggregate(StablePointOld ~ itemid, stablePointsDF, median, na.rm=TRUE)
	colnames(mediansOldDF)[colnames(mediansOldDF)=="StablePointOld"] <- "StablePoint"
	mediansNewDF <- aggregate(StablePointNew ~ itemid, stablePointsDF, median, na.rm=TRUE)
	colnames(mediansNewDF)[colnames(mediansNewDF)=="StablePointNew"] <- "StablePoint"

	medianList <- list(mediansOldDF, mediansNewDF)
	modeVC <- c(modeOldEquation, modeNewEquation)
	
	baseRatingsDF <- loadBaseRatings()
	baseRatingsDF <- baseRatingsDF[order(baseRatingsDF$SetLevel),]

	seStatsDF <- data.frame(itemid=NA, SetLevel=NA, Mode=NA
					, MaxRatingSE=NA, MinRatingSE=NA, MeanRatingSE=NA
					, UnstableArea=NA, StableArea=NA)

	#for(itemIndex in 1:1) {
	for(itemIndex in 1:nrow(baseRatingsDF)) {
		itemID <- baseRatingsDF$itemid[itemIndex]
		setLevel <- baseRatingsDF$SetLevel[itemIndex]

		print(itemID)

		maxMedian <- max(mediansOldDF[mediansOldDF$itemid == itemID,]$StablePoint[1], 
					mediansNewDF[mediansNewDF$itemid == itemID,]$StablePoint[1])

		for(modeIndex in 1:2) {
			medianDF <- medianList[[modeIndex]]
			median <- medianDF[medianDF$itemid == itemID,]$StablePoint[1]

			itemMeanRatingDF <- read.table(paste0(datapath, "scenarioRatingMeans_", modeVC[modeIndex], "_", itemID, ".txt")
								, stringsAsFactors=FALSE, header=TRUE)

			subsetMeanRatingDF <- subset(itemMeanRatingDF, ScenarioRatingMean != 0.01 & ID <= median)
			subsetMeanRatingDF <- subsetMeanRatingDF[order(subsetMeanRatingDF$ID),]
			
			maxRatingSE <- max(subsetMeanRatingDF$ScenarioRatingSE)
			minRatingSE <- min(subsetMeanRatingDF$ScenarioRatingSE)
			meanRatingSE <- mean(subsetMeanRatingDF$ScenarioRatingSE)

			unstableDF <- subset(itemMeanRatingDF, ID <= maxMedian)
			unstableDF <- unstableDF[order(unstableDF$ID),]
			yVC <- c(unstableDF$ScenarioRatingMean + unstableDF$ScenarioRatingSE
					, rev(unstableDF$ScenarioRatingMean - unstableDF$ScenarioRatingSE))
			xVC <- c(unstableDF$ID, rev(unstableDF$ID))
			unstableArea <- geometry::polyarea(xVC, yVC, d = 1)

			stableDF <- subset(itemMeanRatingDF, ID > maxMedian)
			stableDF <- stableDF[order(stableDF$ID),]
			yVC <- c(stableDF$ScenarioRatingMean + stableDF$ScenarioRatingSE
					, rev(stableDF$ScenarioRatingMean - stableDF$ScenarioRatingSE))
			xVC <- c(stableDF$ID, rev(stableDF$ID))
			stableArea <- geometry::polyarea(xVC, yVC, d = 1)

			seStatsDF <- rbind(seStatsDF, data.frame(
				itemid=itemID, SetLevel=setLevel, Mode=modeVC[modeIndex]
				, MaxRatingSE=maxRatingSE, MinRatingSE=minRatingSE, MeanRatingSE=meanRatingSE
				, UnstableArea=unstableArea, StableArea=stableArea
			))
		}
	}
	
	seStatsDF <- seStatsDF[-1,]

	print(seStatsDF)

	write.table(seStatsDF, paste0(datapath, "seStats.txt")
		, sep="\t", row.names=FALSE, col.names=TRUE)
	}

	#######################################################

	seStatsDF <- read.table(paste0(datapath, "seStats.txt"), stringsAsFactors=FALSE, header=TRUE)
	seStatsDF <- cbind(seStatsDF, TotalArea=(seStatsDF$StableArea + seStatsDF$UnstableArea))

	op <- par(mfrow=c(1,3), ask=TRUE)

	orgAreaDF <- subset(seStatsDF, Mode == modeOldEquation)
	orgAreaDF <- orgAreaDF[order(orgAreaDF$itemid), c("itemid", "SetLevel", "TotalArea")]
	colnames(orgAreaDF)[colnames(orgAreaDF)=="TotalArea"] <- "OrgTotalArea"

	modAreaDF <- subset(seStatsDF, Mode == modeNewEquation)
	modAreaDF <- modAreaDF[order(modAreaDF$itemid), c("itemid", "SetLevel", "TotalArea")]
	colnames(modAreaDF)[colnames(modAreaDF)=="TotalArea"] <- "ModTotalArea"

	areaDF <-  merge(orgAreaDF, modAreaDF)

	yLim <- c(min(seStatsDF$StableArea), max(seStatsDF$TotalArea))

	plot(x=areaDF$OrgTotalArea, y=areaDF$ModTotalArea, type="p"
		, pch=areaDF$SetLevel, col=areaDF$SetLevel
		, ylim=yLim, xlim=yLim
		, main=paste0("Total areas of standard errors intervals\n of difficulty ratings.")
		, xlab="Original algorithm", ylab="Modified algorithm"
	)

	abline(lm(ModTotalArea ~ OrgTotalArea, data=areaDF), col="black", lwd=2)
	abline(a=0, b=1, col="black", lwd=1, lty=2)

	print(summary(lm(ModTotalArea ~ OrgTotalArea, data=areaDF)))
	
	legend("topleft", title="Set level"
			, legend=sort(unique(areaDF$SetLevel))
			, pch=sort(unique(areaDF$SetLevel))
			, col=sort(unique(areaDF$SetLevel)))

	############################33

	orgUAreaDF <- subset(seStatsDF, Mode == modeOldEquation)
	orgUAreaDF <- orgUAreaDF[order(orgUAreaDF$itemid), c("itemid", "SetLevel", "UnstableArea")]
	colnames(orgUAreaDF)[colnames(orgUAreaDF)=="UnstableArea"] <- "OrgUArea"

	modUAreaDF <- subset(seStatsDF, Mode == modeNewEquation)
	modUAreaDF <- modUAreaDF[order(modUAreaDF$itemid), c("itemid", "SetLevel", "UnstableArea")]
	colnames(modUAreaDF)[colnames(modUAreaDF)=="UnstableArea"] <- "ModUArea"

	areaDF <-  merge(orgUAreaDF, modUAreaDF)

	plot(x=areaDF$OrgUArea, y=areaDF$ModUArea, type="p"
		, pch=areaDF$SetLevel, col=areaDF$SetLevel
		, ylim=yLim, xlim=yLim
		, main=paste0("Areas of standard errors intervals\n in the convergence phases.")
		, xlab="Original algorithm", ylab="Modified algorithm"
	)

	abline(lm(ModUArea ~ OrgUArea, data=areaDF), col="black", lwd=2)
	abline(a=0, b=1, col="black", lwd=1, lty=2)

	print(summary(lm(ModUArea ~ OrgUArea, data=areaDF)))
	
	legend("topleft", title="Set level"
			, legend=sort(unique(areaDF$SetLevel))
			, pch=sort(unique(areaDF$SetLevel))
			, col=sort(unique(areaDF$SetLevel)))

	############################33

	orgSAreaDF <- subset(seStatsDF, Mode == modeOldEquation)
	orgSAreaDF <- orgSAreaDF[order(orgSAreaDF$itemid), c("itemid", "SetLevel", "StableArea")]
	colnames(orgSAreaDF)[colnames(orgSAreaDF)=="StableArea"] <- "OrgSArea"

	modSAreaDF <- subset(seStatsDF, Mode == modeNewEquation)
	modSAreaDF <- modSAreaDF[order(modSAreaDF$itemid), c("itemid", "SetLevel", "StableArea")]
	colnames(modSAreaDF)[colnames(modSAreaDF)=="StableArea"] <- "ModSArea"

	areaDF <-  merge(orgSAreaDF, modSAreaDF)

	plot(x=areaDF$OrgSArea, y=areaDF$ModSArea, type="p"
		, pch=areaDF$SetLevel, col=areaDF$SetLevel
		, ylim=yLim, xlim=yLim
		, main=paste0("Areas of standard errors intervals\n in the stable phases.")
		, xlab="Original algorithm", ylab="Modified algorithm"
	)

	abline(lm(ModSArea ~ OrgSArea, data=areaDF), col="black", lwd=2)
	abline(a=0, b=1, col="black", lwd=1, lty=2)

	print(summary(lm(ModSArea ~ OrgSArea, data=areaDF)))
	
	legend("topleft", title="Set level"
			, legend=sort(unique(areaDF$SetLevel))
			, pch=sort(unique(areaDF$SetLevel))
			, col=sort(unique(areaDF$SetLevel)))

}

areaTest <- function(){
	
	itemMeanRatingDF <- read.table(paste0(datapath, "scenarioRatingMeans_old_1.txt")
								, stringsAsFactors=FALSE, header=TRUE)

	yVC <- c(itemMeanRatingDF$ScenarioRatingMean + itemMeanRatingDF$ScenarioRatingSE
		, rev(itemMeanRatingDF$ScenarioRatingMean - itemMeanRatingDF$ScenarioRatingSE))
	xVC <- c(itemMeanRatingDF$ID, rev(itemMeanRatingDF$ID))

	print(geometry::polyarea(xVC, yVC, d = 1))
	print(pracma::polyarea(xVC, yVC))

	yVC <- c(3,3,3,3,3,3)
	xVC <- c(1,2,3,3,2,1)

	print(geometry::polyarea(xVC, yVC, d = 1))

}

#plotMeanRatingPerProblem()
#plotFreqDist()
#plotFreqSEDist()

#plotGameplayFreqMeans(1, yLim=c(0, 70000), TRUE, 10) # [TODO] make sure
#plotGameplayFreqMeans(1, yLim=c(0, 70000), FALSE, 20) # [TODO] make sure

#plotGameplayRatingMeans(c(1), yLim=list(c(-3, 0), c(-1, 0.2)), FALSE, 20)
#plotGameplayRatingMeans(c(1), yLim=list(c(-3, 0), c(-1, 0.2)), TRUE, 10)

#plotItemRatingWithStablePoint(9)

#plotMeanRatingStablePoints(TRUE)

analyzeRatingDispersion()

#areaTest()

