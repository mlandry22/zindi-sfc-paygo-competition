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


################################
################################
## End, unroll_train_test_ONETIME.R
## Start, features_Aug13f.R
################################
################################

library(data.table)
library(Metrics)
setwd("/Users/mlandry003/Documents/zindi-sfc-paygo-solar/sfc-paygo-solar-credit-repayment-competition/")
train<-fread("Train.csv")
test<-fread("Test.csv")
ss<-fread("SampleSubmission.csv")
meta<-fread("metadata.csv")
meta[,LastPaymentDate:=NULL]

#train[1:2]
#ss[1:2]

###################################
### TRAIN PROCESSING
###################################
trainDense<-fread("trainDense.csv")  ## see unroll_train_test_ONETIME.R

trainSingle<-trainDense[,.(
  m1Date=dateVal[rkMonth==1]
  ,m1Paid=monthVal[rkMonth==1]
  ,m2Paid=monthVal[rkMonth==2]
  ,m3Paid=monthVal[rkMonth==3]
  ,m4Paid=monthVal[rkMonth==4]
  ,m5Paid=monthVal[rkMonth==5]
  ,m6Paid=monthVal[rkMonth==6]
  ,m7Paid=monthVal[rkMonth==7]
  ,m8Paid=monthVal[rkMonth==8]
  ,m9Paid=monthVal[rkMonth==9]
  ,m10Paid=monthVal[rkMonth==10]
  ,m11Paid=monthVal[rkMonth==11]
  ,m12Paid=monthVal[rkMonth==12]
  ,nMonths=max(nMonths)
  ,maxPaid=max(monthVal,na.rm = TRUE)
  ,maxPaidPastFirst=max(monthVal[rkMonth!=nMonths],na.rm = TRUE)
  ,ttlPayments=max(ttlPayments,na.rm = TRUE)
  ,ttlPaid=as.numeric(sum(monthVal,na.rm = TRUE))
  ,ttlPaidPastFirst=as.numeric(sum(monthVal[rkMonth!=nMonths],na.rm = TRUE))
  ,lastMiss=as.numeric(min(rkMonth[is.na(monthNum)]))
  ,ttlMisses=sum(is.na(monthNum))
),ID]
trainSingle[lastMiss==Inf,lastMiss:=999]
trainSingle<-merge(trainSingle,meta,"ID",all.x=TRUE)
trainSingle<-merge(trainSingle,train[,.(ID,m1,m2,m3,m4,m5,m6)],"ID")

trainSingle[,`:=`(
  m1Pct=m1Paid/TotalContractValue
  ,m2Pct=m2Paid/TotalContractValue
  ,m3Pct=m3Paid/TotalContractValue
  ,m4Pct=m4Paid/TotalContractValue
  ,m5Pct=m5Paid/TotalContractValue
  ,m6Pct=m6Paid/TotalContractValue
  ,remain=TotalContractValue-ttlPaid
  ,pctRemain=round((TotalContractValue-ttlPaid)/TotalContractValue,6)
  ,m1RemainPct=round(m1Paid/(TotalContractValue-ttlPaid-m1Paid),6)
  ,dateFromUpsell=as.integer(as.Date(paste0(m1Date,"-01"))-
                               as.Date(substr(ifelse(UpsellDate=="","1900-01-01",UpsellDate),1,10)))
  ,dateFromExpected=as.integer(as.Date(paste0(m1Date,"-01"))
                               -as.Date(substr(ExpectedTermDate,1,10)))
  ,payRt=round(mean(ttlMisses/nMonths),4)
  #,yearRegDate=substr(RegistrationDate,1,4)
  #,monthRegDate=substr(RegistrationDate,6,7)
  #,dayRegDate=substr(RegistrationDate,9,10)
  #,wkdayRegDate=weekdays(as.Date(substr(RegistrationDate,1,10)))
  #,yearTermDate=substr(ExpectedTermDate,1,4)
  #,monthTermDate=substr(ExpectedTermDate,6,7)
  #,dayTermDate=substr(ExpectedTermDate,9,10)
  #,wkdayTermDate=weekdays(as.Date(substr(ExpectedTermDate,1,10)))
  #,yearFirstPayDate=substr(FirstPaymentDate,1,4)
  #,monthFirstPayDate=substr(FirstPaymentDate,6,7)
  #,dayFirstPayDate=substr(FirstPaymentDate,9,10)
  #,wkdayFirstPayDate=weekdays(as.Date(substr(FirstPaymentDate,1,10)))
  #,yearPredictionDate=substr(m1Date,1,4)
  #,monthPredictionDate=substr(m1Date,6,7)
)]
trainSingle[,middle:=
              ifelse(is.na(m1Paid),ttlPaidPastFirst/(ttlPayments-1),m1Paid)
            +ifelse(is.na(m2Paid),ttlPaidPastFirst/(ttlPayments-1),m2Paid)
            +ifelse(is.na(m3Paid),ttlPaidPastFirst/(ttlPayments-1),m3Paid)
            -pmin(m1Paid,m2Paid,m3Paid,na.rm = TRUE)
            -pmax(m1Paid,m2Paid,m3Paid,na.rm = TRUE)
            ]
trainSingle[,`:=`(
  townAvgT1=mean(m1Paid,na.rm = T)
  ,townAvgT6=mean(m6Paid,na.rm = T)
  ,townAvgTAll=mean(m1Paid+m2Paid+m3Paid+m4Paid+m5Paid+m6Paid,na.rm = T)
  ,townMissedPays=mean(ttlMisses,na.rm = T)
  ,townPayments=mean(nMonths,na.rm = T)
  ,townPayRt=round(mean(ttlMisses/nMonths,na.rm = T),4)
),Town]
trainSingle[,`:=`(
  set=ifelse(substr(as.character(FirstPaymentDate),19,19) %in% c("0","1"),"valid","train")
  ,fold5=floor(as.integer(substr(as.character(FirstPaymentDate),19,19))/2)
  ,fold10=as.integer(substr(as.character(FirstPaymentDate),19,19))
)]

fwrite(trainSingle,"trainFeatures.csv")

#########################
testDense<-fread("testDense.csv")  ## see unroll_train_test_ONETIME.R

testSingle<-testDense[,.(
  m1Date=dateVal[rkMonth==1]
  ,m1Paid=monthVal[rkMonth==1]
  ,m2Paid=monthVal[rkMonth==2]
  ,m3Paid=monthVal[rkMonth==3]
  ,m4Paid=monthVal[rkMonth==4]
  ,m5Paid=monthVal[rkMonth==5]
  ,m6Paid=monthVal[rkMonth==6]
  ,m7Paid=monthVal[rkMonth==7]
  ,m8Paid=monthVal[rkMonth==8]
  ,m9Paid=monthVal[rkMonth==9]
  ,m10Paid=monthVal[rkMonth==10]
  ,m11Paid=monthVal[rkMonth==11]
  ,m12Paid=monthVal[rkMonth==12]
  ,nMonths=max(nMonths)
  ,maxPaid=max(monthVal,na.rm = TRUE)
  ,maxPaidPastFirst=max(monthVal[rkMonth!=nMonths],na.rm = TRUE)
  ,ttlPayments=max(ttlPayments,na.rm = TRUE)
  ,ttlPaid=as.numeric(sum(monthVal,na.rm = TRUE))
  ,ttlPaidPastFirst=sum(as.numeric(monthVal[rkMonth!=nMonths]),na.rm = TRUE)
  ,lastMiss=min(as.numeric(rkMonth[is.na(monthNum)]))
  ,ttlMisses=sum(is.na(monthNum))
),ID]
testSingle[lastMiss==Inf,lastMiss:=999]
testSingle<-merge(testSingle,meta,"ID",all.x=TRUE)

testSingle[,`:=`(
  m1Pct=m1Paid/TotalContractValue
  ,m2Pct=m2Paid/TotalContractValue
  ,m3Pct=m3Paid/TotalContractValue
  ,m4Pct=m4Paid/TotalContractValue
  ,m5Pct=m5Paid/TotalContractValue
  ,m6Pct=m6Paid/TotalContractValue
  ,remain=TotalContractValue-ttlPaid
  ,pctRemain=round((TotalContractValue-ttlPaid)/TotalContractValue,6)
  ,m1RemainPct=round(m1Paid/(TotalContractValue-ttlPaid-m1Paid),6)
  ,dateFromUpsell=as.integer(as.Date(paste0(m1Date,"-01"))-
                               as.Date(substr(ifelse(UpsellDate=="","1900-01-01",UpsellDate),1,10)))
  ,dateFromExpected=as.integer(as.Date(paste0(m1Date,"-01"))-as.Date(substr(ExpectedTermDate,1,10)))
  ,payRt=round(mean(ttlMisses/nMonths),4)
  #,yearRegDate=substr(RegistrationDate,1,4)
  #,monthRegDate=substr(RegistrationDate,6,7)
  #,dayRegDate=substr(RegistrationDate,9,10)
  #,wkdayRegDate=weekdays(as.Date(substr(RegistrationDate,1,10)))
  #,yearTermDate=substr(ExpectedTermDate,1,4)
  #,monthTermDate=substr(ExpectedTermDate,6,7)
  #,dayTermDate=substr(ExpectedTermDate,9,10)
  #,wkdayTermDate=weekdays(as.Date(substr(ExpectedTermDate,1,10)))
  #,yearFirstPayDate=substr(FirstPaymentDate,1,4)
  #,monthFirstPayDate=substr(FirstPaymentDate,6,7)
  #,dayFirstPayDate=substr(FirstPaymentDate,9,10)
  #,wkdayFirstPayDate=weekdays(as.Date(substr(FirstPaymentDate,1,10)))
  #,yearPredictionDate=substr(m1Date,1,4)
  #,monthPredictionDate=substr(m1Date,6,7)
)]
testSingle[,`:=`(
  townAvgT1=mean(m1Paid,na.rm = T)
  ,townAvgT6=mean(m6Paid,na.rm = T)
  ,townAvgTAll=mean(m1Paid+m2Paid+m3Paid+m4Paid+m5Paid+m6Paid,na.rm = T)
  ,townMissedPays=mean(ttlMisses,na.rm = T)
  ,townPayments=mean(nMonths,na.rm = T)
  ,townPayRt=round(mean(ttlMisses/nMonths,na.rm = T),4)
),Town]

testSingle[,middle:=
             ifelse(is.na(m1Paid),ttlPaidPastFirst/(ttlPayments-1),m1Paid)
           +ifelse(is.na(m2Paid),ttlPaidPastFirst/(ttlPayments-1),m2Paid)
           +ifelse(is.na(m3Paid),ttlPaidPastFirst/(ttlPayments-1),m3Paid)
           -pmin(m1Paid,m2Paid,m3Paid,na.rm = TRUE)
           -pmax(m1Paid,m2Paid,m3Paid,na.rm = TRUE)
           ]

fwrite(testSingle,"testFeatures.csv")

#################################

#trainSingle[1:2]
if(0==1){
  View(trainSingle[order(-pmax((middle-m1)^2,(middle-m2)^2,(middle-m3)^2
                               ,(middle-m4)^2,(middle-m5)^2,(middle-m6)^2))
                   ][1:20,.(ID,FirstDt=substr(FirstPaymentDate,1,10)
                            ,LastDt=substr(LastPaymentDate,1,10)
                            ,UpsellDt=substr(UpsellDate,1,10)
                            ,Term=substr(ExpectedTermDate,1,10)
                            ,m1Date
                            ,m1,m2,m3,m4,m5,m6
                            ,ttlPaid,TCV=TotalContractValue,remain
                            ,m1Paid,m2Paid,m3Paid,m4Paid,m5Paid,m6Paid
                   )])
}
#################################


################################
################################
## End, features_Aug13f.R
## Start, h2o_modelling_Aug13g.R
################################
################################

library(h2o)
setwd("/Users/mlandry003/Documents/zindi-sfc-paygo-solar/sfc-paygo-solar-credit-repayment-competition/")
h2o.init(nthreads = -1)
fullHex<-h2o.importFile("trainFeatures.csv",destination_frame = "full.hex")
fullHex$keyInt<-as.h2o(1:nrow(fullHex))
testHex<-h2o.importFile("testFeatures.csv",destination_frame = "test.hex")
testHex$keyInt<-as.h2o((nrow(fullHex)+1):(nrow(fullHex)+nrow(testHex)))
#trainHex<-fullHex[fullHex$set=="train",]
#validHex<-fullHex[fullHex$set=="valid",]

# cluster first, add features, then get feature list
kmHex<-h2o.rbind(fullHex[,colnames(testHex)],testHex[,colnames(testHex)])

kmPaid<-h2o.kmeans(training_frame = kmHex,k = 50,seed=2021
                   ,x=colnames(fullHex)[grepl("Paid",colnames(fullHex))]
                   ,max_iterations = 500,model_id="kmeans_paid")
#kmDates<-h2o.kmeans(training_frame = kmHex,k = 50,seed = 2021
#                    ,x=colnames(fullHex)[grepl("Date",colnames(fullHex))]
#                   ,max_iterations = 500,model_id="kmeans_dates")
#kmPcts<-h2o.kmeans(training_frame = kmHex,k = 50,seed = 2021
#                    ,x=colnames(fullHex)[grepl("Pct",colnames(fullHex))]
#                    ,max_iterations = 500,model_id="kmeans_pcts")

kMeansPaidPreds<-h2o.cbind(
  kmHex$keyInt
  ,h2o.predict(kmPaid,kmHex)
)
names(kMeansPaidPreds)[2] = c("clustPaid")

fullHex<-h2o.merge(fullHex,kMeansPaidPreds,"keyInt",all.x = TRUE)
testHex<-h2o.merge(testHex,kMeansPaidPreds,"keyInt",all.x = TRUE)

targetCols<-c("m1","m2","m3","m4","m5","m6")
targetXCols<-c("x1","x2","x3","x4","x5","x6")
excludeCols<-c("ID","set","PaymentMethod","SupplierName"
               ,"fold5","fold10","keyInt")
featureCols<-setdiff(colnames(fullHex)
                     ,c(targetCols,targetXCols,excludeCols))



###########################################
###########################################
###########################################
xgbm2m1<-h2o.xgboost(x=featureCols,y="m1",training_frame = fullHex, seed = 2021
                     ,learn_rate = 0.01,ntrees = 2000,max_depth = 10
                     ,fold_column = "fold5",score_tree_interval = 10
                     ,stopping_rounds = 5,stopping_tolerance = 0.0
                     ,sample_rate = 0.75,col_sample_rate = 0.75
                     ,model_id = "xgbm2.m1")
xgbm2m2<-h2o.xgboost(x=featureCols,y="m2",training_frame = fullHex, seed = 2021
                     ,learn_rate = 0.01,ntrees = 2000,max_depth = 10
                     ,fold_column = "fold5",score_tree_interval = 10
                     ,stopping_rounds = 5,stopping_tolerance = 0.0
                     ,sample_rate = 0.75,col_sample_rate = 0.75
                     ,model_id = "xgbm2.m2")
xgbm2m3<-h2o.xgboost(x=featureCols,y="m3",training_frame = fullHex, seed = 2021
                     ,learn_rate = 0.01,ntrees = 2000,max_depth = 10
                     ,fold_column = "fold5",score_tree_interval = 10
                     ,stopping_rounds = 5,stopping_tolerance = 0.0
                     ,sample_rate = 0.75,col_sample_rate = 0.75
                     ,model_id = "xgbm2.m3")
xgbm2m4<-h2o.xgboost(x=featureCols,y="m4",training_frame = fullHex, seed = 2021
                     ,learn_rate = 0.01,ntrees = 2000,max_depth = 10
                     ,fold_column = "fold5",score_tree_interval = 10
                     ,stopping_rounds = 5,stopping_tolerance = 0.0
                     ,sample_rate = 0.75,col_sample_rate = 0.75
                     ,model_id = "xgbm2.m4")
xgbm2m5<-h2o.xgboost(x=featureCols,y="m5",training_frame = fullHex, seed = 2021
                     ,learn_rate = 0.01,ntrees = 2000,max_depth = 10
                     ,fold_column = "fold5",score_tree_interval = 10
                     ,stopping_rounds = 5,stopping_tolerance = 0.0
                     ,sample_rate = 0.75,col_sample_rate = 0.75
                     ,model_id = "xgbm2.m5")
xgbm2m6<-h2o.xgboost(x=featureCols,y="m6",training_frame = fullHex, seed = 2021
                     ,learn_rate = 0.01,ntrees = 2000,max_depth = 10
                     ,fold_column = "fold5",score_tree_interval = 10
                     ,stopping_rounds = 5,stopping_tolerance = 0.0
                     ,sample_rate = 0.75,col_sample_rate = 0.75
                     ,model_id = "xgbm2.m6")

xp1<-data.table(as.data.frame(h2o.cbind(testHex$ID,h2o.predict(xgbm2m1,testHex))))
xp2<-data.table(as.data.frame(h2o.cbind(testHex$ID,h2o.predict(xgbm2m2,testHex))))
xp3<-data.table(as.data.frame(h2o.cbind(testHex$ID,h2o.predict(xgbm2m3,testHex))))
xp4<-data.table(as.data.frame(h2o.cbind(testHex$ID,h2o.predict(xgbm2m4,testHex))))
xp5<-data.table(as.data.frame(h2o.cbind(testHex$ID,h2o.predict(xgbm2m5,testHex))))
xp6<-data.table(as.data.frame(h2o.cbind(testHex$ID,h2o.predict(xgbm2m6,testHex))))

submission<-rbind(
  xp1[,.(ID=paste(ID,"x m1"),rawTarget=predict,IDnum=ID)]
  ,xp2[,.(ID=paste(ID,"x m2"),rawTarget=predict,IDnum=ID)]
  ,xp3[,.(ID=paste(ID,"x m3"),rawTarget=predict,IDnum=ID)]
  ,xp4[,.(ID=paste(ID,"x m4"),rawTarget=predict,IDnum=ID)]
  ,xp5[,.(ID=paste(ID,"x m5"),rawTarget=predict,IDnum=ID)]
  ,xp6[,.(ID=paste(ID,"x m6"),rawTarget=predict,IDnum=ID)]
)[order(ID)]


submission[,meanTarget:=mean(rawTarget),IDnum]
submission[,`:=`(Target=pmax(0,rawTarget*0.7 + meanTarget*0.3))]
fwrite(submission[,.(ID,Target)],"sub0813g-replicated0830.csv")
