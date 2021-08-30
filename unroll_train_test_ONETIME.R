## UNROLL TRAIN and TEST
## ONE TIME USE, THEN SAVED
library(data.table)
library(Metrics)
setwd("/Users/mlandry003/Documents/zindi-sfc-paygo-solar/sfc-paygo-solar-credit-repayment-competition/")
train<-fread("Train.csv")
test<-fread("Test.csv")
ss<-fread("SampleSubmission.csv")
meta<-fread("metadata.csv")

train[,`:=`(
  firstTxn=substr(TransactionDates,3,9)
  ,lastTxn=substr(TransactionDates,nchar(TransactionDates)-8,nchar(TransactionDates)-2)
  ,ttlTxns=(nchar(TransactionDates)-0)/11
)]
#########################
#########################
trainPayments<-strsplit(gsub("[","",gsub("]", "",train$PaymentsHistory,fixed=TRUE),fixed = TRUE),", ")
trainDates<-strsplit(gsub("[","",gsub("]", "",train$TransactionDates,fixed=TRUE),fixed = TRUE),", ")
for(i in 1:length(trainPayments)){
  train[i,ttlPayments:=length(trainPayments[[i]])]
  train[i,ttlDates:=length(trainDates[[i]])]
}
l<-list()
for(i in 1:length(trainPayments)){
  if(i%%1000==1){print(paste(i,Sys.time()))}
  for(j in 1:train[i,ttlPayments]){
    l[[length(l)+1]]<-train[i,.(ID,monthNum=j
                                ,monthVal=trainPayments[[i]][j]
                                ,dateVal=trainDates[[i]][j])]
  }
}
trainUnrolled<-rbindlist(l)
trainUnrolled<-merge(trainUnrolled,train[,.(ID,ttlPayments)],"ID",all.x=TRUE)
trainUnrolled[,revMonth:=ttlPayments-monthNum+1]
trainUnrolled[,monthVal:=as.numeric(monthVal)]
trainUnrolled[,dateVal:=paste0(substr(dateVal,5,8),"-",substr(dateVal,2,3))]

allTrainMonths<-trainUnrolled[,.N,dateVal][order(dateVal),.(dummy=1,dateInt=.I,dateVal)]
trainDense<-merge(
  trainUnrolled[,.(dummy=1,firstMonth=min(dateVal),lastMonth=max(dateVal)),ID]
  ,allTrainMonths,"dummy",allow.cartesian = TRUE
)[(dateVal>=firstMonth) & (dateVal<=lastMonth),.(ID,dateVal)]
trainDense<-merge(trainDense
                  ,trainUnrolled[,.(ID,monthNum,monthVal,dateVal,ttlPayments)]
                  ,c("ID","dateVal"),all.x=TRUE)
trainDense[,`:=`(rkMonth=frank(dateVal),nMonths=.N),ID]
trainDense[,`:=`(rkMonth=nMonths-rkMonth+1)]
fwrite(trainDense,"trainDense.csv")
######################################
testPayments<-strsplit(gsub("[","",gsub("]", "",test$PaymentsHistory,fixed=TRUE),fixed = TRUE),", ")
testDates<-strsplit(gsub("[","",gsub("]", "",test$TransactionDates,fixed=TRUE),fixed = TRUE),", ")
for(i in 1:length(testPayments)){
  test[i,ttlPayments:=length(testPayments[[i]])]
  test[i,ttlDates:=length(testDates[[i]])]
}
l<-list()
for(i in 1:length(testPayments)){
  if(i%%100==1){print(paste(i,Sys.time()))}
  for(j in 1:test[i,ttlPayments]){
    l[[length(l)+1]]<-test[i,.(ID,monthNum=j
                               ,monthVal=testPayments[[i]][j]
                               ,dateVal=testDates[[i]][j])]
  }
}
testUnrolled<-rbindlist(l)
testUnrolled<-merge(testUnrolled,test[,.(ID,ttlPayments)],"ID",all.x=TRUE)
testUnrolled[,revMonth:=ttlPayments-monthNum+1]
testUnrolled[,monthVal:=as.numeric(monthVal)]
testUnrolled[,dateVal:=paste0(substr(dateVal,5,8),"-",substr(dateVal,2,3))]

allMonths<-testUnrolled[,.N,dateVal][order(dateVal),.(dummy=1,dateInt=.I,dateVal)]
testDense<-merge(
  testUnrolled[,.(dummy=1,firstMonth=min(dateVal),lastMonth=max(dateVal)),ID]
  ,allMonths,"dummy",allow.cartesian = TRUE
)[(dateVal>=firstMonth) & (dateVal<=lastMonth),.(ID,dateVal)]
testDense<-merge(testDense
                 ,testUnrolled[,.(ID,monthNum,monthVal,dateVal,ttlPayments)]
                 ,c("ID","dateVal"),all.x=TRUE)
testDense[,`:=`(rkMonth=frank(dateVal),nMonths=.N),ID]
testDense[,`:=`(rkMonth=nMonths-rkMonth+1)]
fwrite(testDense,"testDense.csv")
