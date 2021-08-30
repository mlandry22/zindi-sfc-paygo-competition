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

