#Sales Opportunity Data Analysis
#By: Marcus Diehl
#for: MSDS 692, Regis Univerisyt

#load all the libraries
library(openxlsx)
library(dplyr)
library(data.table)
library(Amelia)
library(caret)
library(randomForest)
library(DataExplorer)
library(ggplot2)

#read in the data
opportunity.raw <- read.xlsx("opportunity.masked.xlsx")

#make a copy
opportunity <- opportunity.raw
#https://stackoverflow.com/questions/20345022/convert-a-data-frame-to-a-data-table-without-copy

setDT(opportunity) #make it a data.table

#need to change to factors, Quarter, Year, New State, Close State, Technology, Type
opportunity$OppType <- as.factor(opportunity$OppType)
opportunity$CustGblRegion <- as.factor(opportunity$CustGblRegion)
opportunity$CustRegion <- as.factor(opportunity$CustRegion)
opportunity$CustName <- as.factor(opportunity$CustName)
opportunity$OppTechnology <- as.factor(opportunity$OppTechnology)
opportunity$OppPrimeSalesRepName <- as.factor(opportunity$OppPrimeSalesRepName)
opportunity$CustCoreSeg <- as.factor(opportunity$CustCoreSeg)
opportunity$CustSubSeg <- as.factor(opportunity$CustSubSeg)
opportunity$OppEstClsYR <- as.factor(opportunity$OppEstClsYR)
opportunity$OppEstClsQtr <- as.factor(opportunity$OppEstClsQtr)
opportunity$OppTypeNewState <- as.factor(opportunity$OppTypeNewState)
opportunity$OppTypeJepState <- as.factor(opportunity$OppTypeJepState)
opportunity$OppPrimeCompetitor <- as.factor(opportunity$OppPrimeCompetitor)
opportunity$OppClosedState <- as.factor(opportunity$OppClosedState)
opportunity$OppBPPlatform <- as.factor(opportunity$OppBPPlatform)
opportunity$OppCurrency <- as.factor(opportunity$OppCurrency)
opportunity$OppHighValueFlag <- as.factor(opportunity$OppHighValueFlag)
opportunity$OppHighValueStatus <- as.factor(opportunity$OppHighValueStatus)
opportunity$OppCreatedBy <- as.factor(opportunity$OppCreatedBy)
opportunity$OppTypeSubCat <- as.factor(opportunity$OppTypeSubCat)


#http://r.789695.n4.nabble.com/Read-quot-xlsx-quot-and-convert-date-column-value-into-Dataframe-td4710192.html
#Read.xlsx messse up the DAte format and converts everything to PosIX time, simple formula below fixes it
opportunity$OppCreateDate <- as.Date('1900-01-01')+opportunity$OppCreateDate-2
opportunity$OppLastUpdateDate <- as.Date('1900-01-01')+opportunity$OppLastUpdateDate-2
opportunity$OppClosedDate <- as.Date('1900-01-01')+opportunity$OppClosedDate-2
opportunity$OppTypeJepDate <- as.Date('1900-01-01')+opportunity$OppTypeJepDate-2
opportunity$OppTypeNewDate <- as.Date('1900-01-01')+opportunity$OppTypeNewDate-2
opportunity$OppModifyDate <- as.Date('1900-01-01')+opportunity$OppModifyDate-2


#EDA, what are we dealing iwth
introduce(opportunity)

plot_bar(opportunity$OppType)

plot_bar(opportunity[,OppTypeNewState])
plot_bar(opportunity[,OppTypeJepState])

#https://stackoverflow.com/questions/14549433/count-rows-by-date
dt <- as.data.table(opportunity$OppCreateDate)
dt <- dt[,.N,by=V1]
#https://www.statmethods.net/graphs/scatterplot.html
plot(N ~ V1, dt, main="Opportunities over Time", xlab="Date", ylab="Count")

plot_bar(opportunity$OppTechnology)

#show to proportion
prop.table(table(opportunity$OppType))


#Prepocessing, Split the data between New Business and Jeopardy
#https://stackoverflow.com/questions/7448676/how-to-identify-which-columns-are-not-na-per-row-in-a-matrix
#we want to keep Opportunties that are not NA
opportunity.NewBusiness <- opportunity %>% filter(OppType == "New Business")
#and we'll store the rest as jeopardy
#I prefere to deal with absolutes
opportunity.Jepordy <- opportunity %>% filter(OppType != "New Business")

#Refinement
#ALL THE SOLD as a Cumulative Sum
opportunity.NewBusiness$cumsum <- ifelse(opportunity.NewBusiness$OppTypeNewState == "Sold", 1, 0)
#Cumualtive Sum based on Sales Rep's Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(OppPrimeSalesRepName) %>% mutate(OppPrimeSalesRepSoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Competitors Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(OppPrimeCompetitor) %>% mutate(OppPrimeCompetitorSoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customer Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustName) %>% mutate(CustNameSoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customers Region Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustRegion) %>% mutate(CustRegionSoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Global Region Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustGblRegion) %>% mutate(CustGblRegionSoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Technology Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(OppTechnology) %>% mutate(OppTechnologySoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customer Core Segment Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustCoreSeg) %>% mutate(CustCoreSegSoldExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customers Sub Segment Sold
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustSubSeg) %>% mutate(CustSubSegSoldExpCount = cumsum(cumsum)) %>% data.frame() 



#ALL THe DEAD
#Cumualtive Sum of Sales Rep's Dead
opportunity.NewBusiness$cumsum <- ifelse(opportunity.NewBusiness$OppTypeNewState == "Dead", 1, 0)
#Cumualtive Sum based on Sales Rep's Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(OppPrimeSalesRepName) %>% mutate(OppPrimeSalesRepDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Competitors Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(OppPrimeCompetitor) %>% mutate(OppPrimeCompetitorDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customer Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustName) %>% mutate(CustNameDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customers Region Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustRegion) %>% mutate(CustRegionDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Global Region Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustGblRegion) %>% mutate(CustGblRegionDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Technology Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(OppTechnology) %>% mutate(OppTechnologyDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customer Core Segment Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustCoreSeg) %>% mutate(CustCoreSegDeadExpCount = cumsum(cumsum)) %>% data.frame() 
#Cumualtive Sum based on Customers Sub Segment Dead
opportunity.NewBusiness <- opportunity.NewBusiness %>% arrange(OppClosedDate) %>% group_by(CustSubSeg) %>% mutate(CustSubSegDeadExpCount = cumsum(cumsum)) %>% data.frame() 


#Clean up by Removing CumSum now that it is nolonger needed
opportunity.NewBusiness <- opportunity.NewBusiness %>% select(-cumsum)


#THIS WILL NEVER WORK because Creaters are backdating information, too many negative durations


#need to count days since Created and close, to help score, since the older the opportunity, the higher the risk
#if active compare created against 05/14/2018, date the flat file was recieved. 
#store a static date on rows that have OppClosedDate
opportunity.NewBusiness$OppClosedDate[is.na(opportunity.NewBusiness$OppClosedDate)] <- as.Date("2018-05-14")
#measure the duration in days
#opportunity$OppDurration <- opportunity$OppClosedDate - opportunity$OppCreateDate
#https://stackoverflow.com/questions/37056201/r-rounding-with-difftime-function
opportunity.NewBusiness$OppDurration <- round(difftime(opportunity.NewBusiness$OppClosedDate, opportunity.NewBusiness$OppCreateDate, units = "days"), 0)

#https://plot.ly/ggplot2/box-plots/
ggplot(opportunity.NewBusiness, aes(x=OppTypeNewState, y=OppDurration, fill=OppTypeNewState)) + geom_boxplot()



#Duration breakdown
prop.table(opportunity.NewBusiness %>% summarise(Postitive = sum(OppDurration>0), Negative = sum(OppDurration<0)))

#well isn't too bad, 401 fo 10830 are negative

#need to replace the negative Durations with a Mean value
#https://www.r-bloggers.com/using-r-quickly-calculating-summary-statistics-with-dplyr/
temp <-summarise(opportunity.NewBusiness, mean=mean(OppDurration))
#round to the nearest day
temp <- round(temp$mean)
#now replace the negative durations with the mean duration
#https://stackoverflow.com/questions/28013850/change-value-of-variable-with-dplyr
opportunity.NewBusiness <- opportunity.NewBusiness %>% mutate(OppDurration=replace(OppDurration, OppDurration < 0, temp))


#with Duration found back dating and filled wiht mean values, there are other rows with missing data
#crutial to address missing data before ML
#https://www.r-bloggers.com/how-to-perform-a-logistic-regression-in-r/
#view Missing Data

#key columns
columns <- c("CustGblRegion","OppTechnology", "CustCoreSeg", "OppEstClsYR", "OppEstClsQtr", "OppEstAnnSales", "OppEstClsYrsSales", "OppEstCOSales", "OppClosedDate", "OppEstAnnPctProfits", "OppEstClsYrSalesUSD", "OppEstCOSalesUSD", "OppEstTotalSalesUSD", "OppCurrency", "OppHighValueFlag", "OppHighValueStatus", "OppCreateDate", "OppPrimeSalesRepSoldExpCount", "OppPrimeCompetitorSoldExpCount", "CustNameSoldExpCount", "CustRegionSoldExpCount", "CustGblRegionSoldExpCount", "OppTechnologySoldExpCount", "CustCoreSegSoldExpCount", "OppPrimeSalesRepDeadExpCount", "OppPrimeCompetitorDeadExpCount", "CustNameDeadExpCount", "CustRegionDeadExpCount", "CustGblRegionDeadExpCount", "OppTechnologyDeadExpCount", "CustCoreSegDeadExpCount", "OppDurration", "OppTypeNewState")

#missmap(opportunity.NewBusiness, main = "Missing values vs observed")
plot_missing(opportunity.NewBusiness %>% select(columns))

#columns found with a few (<5%) missing values and useful ML
nacolumns <- c("CustSubSeg", "OppEstClsYR", "OppEstCOSales", "OppEstCOSalesUSD", "OppHighValueStatus")

#Factors, picked the Max occuring value
#max value
temp <- as.data.frame(table(opportunity.NewBusiness$CustSubSeg)) %>% filter(Freq == max(Freq)) %>% select(Var1)
#apply temp
opportunity.NewBusiness <- opportunity.NewBusiness %>% mutate(CustSubSeg=replace(CustSubSeg, is.na(CustSubSeg), temp$Var1))

#max value
temp <- as.data.frame(table(opportunity.NewBusiness$OppHighValueStatus)) %>% filter(Freq == max(Freq)) %>% select(Var1)
#Apply temp
opportunity.NewBusiness <- opportunity.NewBusiness %>% mutate(OppHighValueStatus=replace(OppHighValueStatus, is.na(OppHighValueStatus), temp$Var1))

#OppEstClsYR is a factor but there is extra data in other columns base it off of, this is the estimated year the Opp would Close. So the actual close date
#turns out all the CloseDates for the NAs of OppEstClsYear are 2014, and are all label SOLD, and were all for the same customer..
#opportunity.NewBusiness %>% filter(is.na(OppEstClsYR)) %>% mutate(OppEstClsYR2=format(OppClosedDate, '%Y')) %>% select(OppEstClsYR2, OppClosedDate)
#But earliest Estimate in OppEstClsYR is 2015, which is the earliest so the first row
opportunity.NewBusiness <- opportunity.NewBusiness %>% mutate(OppEstClsYR=replace(OppEstClsYR, is.na(OppEstClsYR), as.character(as.data.frame(table(opportunity.NewBusiness$OppEstClsYR))[1,"Var1"])))



#Numbers, picked the mean
#But can't pick a mean if NA values, so filter
#for Opportunity Estimates Close Out Sales $$
temp <-opportunity.NewBusiness %>% filter(!is.na(OppEstCOSales)) %>%summarise(mean=mean(OppEstCOSales))
#now store it
opportunity.NewBusiness <- opportunity.NewBusiness %>% mutate(OppEstCOSales=replace(OppEstCOSales, is.na(OppEstCOSales), temp$mean))

temp <-opportunity.NewBusiness %>% filter(!is.na(OppEstCOSalesUSD)) %>%summarise(mean=mean(OppEstCOSalesUSD))
#now store it
opportunity.NewBusiness <- opportunity.NewBusiness %>% mutate(OppEstCOSalesUSD=replace(OppEstCOSalesUSD, is.na(OppEstCOSalesUSD), temp$mean))

#key columns
columns <- c("CustGblRegion","OppTechnology", "CustName", "CustCoreSeg", "OppEstClsYR", "OppEstClsQtr", "OppEstAnnSales", "OppEstClsYrsSales", "OppEstCOSales", "OppClosedDate", "OppEstAnnPctProfits", "OppEstClsYrSalesUSD", "OppEstCOSalesUSD", "OppEstTotalSalesUSD", "OppCurrency", "OppHighValueFlag", "OppHighValueStatus", "OppCreateDate", "OppTypeNewState")
plot_boxplot(opportunity.NewBusiness %>% select(columns), by = "OppTypeNewState")

prop.table(table(opportunity.NewBusiness$OppTypeNewState))

#https://stackoverflow.com/questions/7448676/how-to-identify-which-columns-are-not-na-per-row-in-a-matrix
#we want to keep Opportunties Opportunites that are currently Active
opportunity.Active <- opportunity.NewBusiness %>% filter(OppTypeNewState == 'Active')
#In History we'll store everything not Active (I like to deal in absolutes)
opportunity.History <- opportunity.NewBusiness %>% filter(!(OppTypeNewState == 'Active'))

#after the seperation need to reindex the Factor for OppTypeNewState
opportunity.Active$OppTypeNewState <- factor(opportunity.Active$OppTypeNewState)
opportunity.History$OppTypeNewState <- factor(opportunity.History$OppTypeNewState)

#need to reduce down to key columns (non char based) for ML to use. 
#so what columns...
columns <- c("CustGblRegion","OppTechnology", "CustCoreSeg", "OppEstClsYR", "OppEstClsQtr", "OppEstAnnSales", "OppEstClsYrsSales", "OppEstCOSales", "OppClosedDate", "OppEstAnnPctProfits", "OppEstClsYrSalesUSD", "OppEstCOSalesUSD", "OppEstTotalSalesUSD", "OppCurrency", "OppHighValueFlag", "OppHighValueStatus", "OppCreateDate", "OppPrimeSalesRepSoldExpCount", "OppPrimeCompetitorSoldExpCount", "CustNameSoldExpCount", "CustRegionSoldExpCount", "CustGblRegionSoldExpCount", "OppTechnologySoldExpCount", "CustCoreSegSoldExpCount", "OppPrimeSalesRepDeadExpCount", "OppPrimeCompetitorDeadExpCount", "CustNameDeadExpCount", "CustRegionDeadExpCount", "CustGblRegionDeadExpCount", "OppTechnologyDeadExpCount", "CustCoreSegDeadExpCount", "OppDurration", "OppTypeNewState")

#setup Train and Test with a 70:30 ratio
#Caret library has a nice createDataPartition that creates sample based on a column that is random but so that sampling isn't onesided (train has a higher ratio of Solds than Test)
#https://stackoverflow.com/questions/35718350/train-test-split-in-rs-caret-package
temp <- createDataPartition(opportunity.History$OppTypeNewState, p = 0.7, list=FALSE)
#setup train/test
opportunity.train <- opportunity.History[temp,columns]
opportunity.test <- opportunity.History[-temp,columns]

#confirm equal break down of Sold/Dead across Train/Test
prop.table(table(opportunity.train$OppTypeNewState))
prop.table(table(opportunity.test$OppTypeNewState))


#Random Forest Model to predict Sold/Dead
#https://www.r-bloggers.com/random-forests-in-r/
#https://www.r-bloggers.com/random-forest-classification-of-mushrooms/
#using 100 Trees, run a Random Forest model against the Train dataset
rfmodel <- randomForest(OppTypeNewState ~ ., ntree = 100, data = opportunity.train)
#apply RF on test data
opportunity.predict.RF = predict(rfmodel, opportunity.test)
#print out a confusion Matrix on the Prediction from the model against the Test dataset
print(confusionMatrix(data = opportunity.predict.RF,  
                      reference = opportunity.test$OppTypeNewState,
                      positive = 'Sold'))

#Plot the Error Rate
plot(rfmodel)

#Variable of Importance
varImpPlot(rfmodel,  
           sort = T,
           n.var=10,
           main="Top 10 - Variable Importance")

var.imp = data.frame(importance(rfmodel,  
                                type=2))
# make row names as columns
var.imp$Variables = row.names(var.imp)  
print(var.imp[order(var.imp$MeanDecreaseGini,decreasing = T),])
