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
fwrite(submission[,.(ID,Target)],"sub0813g.csv")
