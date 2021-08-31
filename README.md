# zindi-sfc-paygo-competition
* SFC PAYGo Solar Credit Repayment Competition on Zindi
* 20th place submission from Mark Landry (mlandry)

## Submission info from Zindi platform
* ID: PxUMpsQ1
* Filename: sub0813g.csv
* Comment: kMeans on Paid columns
* Submitted: 14 August 19:41

## Environment
* MacBook Pro (15-inch, 2018)
* 2.9 GHz 6-Core Intel Core i9
* 32 GB 2400 MHz DDR4
* Created originally on MacOS Catalina; reproduction performed on MacOS Big Sur
* Runtime from start to finish was 58 minutes on the specified hardware.

## Software
* R: 3.5.2
* data.table: 1.12.6
* h2o: 3.32.1.3
* xgboost: 0.90.0.2
The R version is over two years old, but more recent versions should run these packages identically.

## Zindi documentation expectations:
* Data used: only files provided as part of the competition
* Output data and where they are stored: local drive; altering all locations from "/Users/mlandry003/Documents/zindi-sfc-paygo-solar/sfc-paygo-solar-credit-repayment-competition/" to the desired location will not affect the input or output, as long as both exist at the same level. 
* Extra note on the usage of the leaked feature: `LastPaymentDate` was removed as requested. Line99 uses the code `meta[,LastPaymentDate:=NULL]` will removes it from the meta data frame prior to it being used in the merges to the train and test sets.

## Explanation of features used

### Unrolling payments
One pass through the transactional data is performed, unrolling all payments into a tabular format. While this code is not particularly efficient, it was performed only one time, and the exported format used for all ensuing experimentation. This transformed the original format into the format shown below, which is effectively an unpivoted format, more amenable for creating features by grouping by ID. The code is executed against both the train and test files.
The code to do this section is `unroll_train_test_ONETIME.R` which makes up the first 87 lines of the single submission file `single_script_Aug13h.R`

The `monthNum` and `rkMonth` features help align the payments to a standard relative distance from the training data or test situation. `monthNum` is in increasing order from the first payment, `rkMonth` is more often used as it counts backwards from the final payment, so that `rkMonth:1` is the most recent payment month.

```
           ID dateVal monthNum monthVal ttlPayments rkMonth nMonths
1: ID_001AMM9 2017-08        1     2200           9      10      10
2: ID_001AMM9 2017-09        2      880           9       9      10
```

### Group-by features and meta features
After transforming the payment data, features are then re-pivoted in a standardized format that is organized by the number of months from the final month. As mentioned above, the dense data has already been aligned so that the most recent payments are aligned, regardless of the date they occurred.

The meta data is then merged (after removing the leaked column). Various math calculations are performed to try and frame the raw payment data into relative payment data, such as dividing the most recent month's payment (`m1Paid`) by the total countract value from the meta data. A few date differences are calculated to show the model the relative time between events, rather than the specific date of occurrenct. Both forms will be included.

### Modelling
The modelling is mostly carried out through straightforward XGBoost models, trained in H2O. Each target was modelled independently after observing the independent behavior of the 6th month. CV metrics are shared below.

The six different targets are related, so smoothing the six as a set was experimented with and a 70/30 average of the original prediction (70%) and the average of all six predictions (30%) was used.

One exception is that an unsupervised clustering of all payment values occurs in a kMeans model. The cluster IDs are used in the modelling step. This model trains very quickly and did provide a slight uplift.

For reproducibility across experiments, I switched from random cross-validation to an arbitrary but consistent use of FirstPaymentDate, where the 19th digit was used to obtain an even distribution (`fold5` and `fold10` are derived in this way). 5-fold cross validation was used, managed through H2O's fold column, where the final model was created using the average tree counts of the five CV models, each with early stopping.
While reproducibility of the folds was removed from a random selection, seeds into the model were not always consistent, except the kMeans. I have run the script top to bottom a couple times and get answers hat have a 0.996 and 0.997 correlation. Scores are nearly identical, but very slightly different. In this code, I have used the same seed as the kMeans model.

## Additional Comments
It was particularly interesting that once the prediction scores of the public test set achieved a particular relative score, it seemed most new ideas made an insignificant difference. Most of those ideas had been vetted through cross-validation to show some gain, but only those that showed gains in both were retained. However, a look at the private leaderboard scores shows that this strategy was not optimal. The best private leaderboard score was one of the first models created, and the improvement was enough that even if estimating the performance loss of removing the leaked column, it was still likely the best overall model.

One of the larger factors of a good or bad score appeared to be the way the large payments in month6 were handled. Very often, we would see a customer pay over 10x their average payment in the last month. I was not sure if the model was properly finding patterns that indicated a customer may do this, so I occasionally softened the impact, but each time I did, the accuracy decreased. So the model appears to have found a reliable signal about when customers may make such a large payment. I was unable to spot such behavior in a more intuitive/interpretible manner (there was some discussion on the forums that indicate other competitors were able to do so). I intended to experiment more with accounting for the 70/30 average so that it did not spread higher-than-average month-6 payments across the set, but did not have the time to experiment with that idea.

It was surprising to see that all training data had clean payment history, yet the payment history in the full detail contains many missed payments. I assumed this was intentional, and proceeded modelling with the data as provided in training. If this happened to be unintentional, it will merit a reconsideration of all modelling from all competitors. In general, features that counted zeros and realigned payments and missed payments did influence the model as much as I expected, but this is likely due to the guarantee of no missed payments in the final 6 months of training (and presumably test).

## CV Performance

Here we see how inconsistent the models can be across folds and for different targets.
Each row is a model that pertains to a specific month (`month` columns) and the columns are in the columns. The folds are consistent for all models. We can easily see the difficulty managing the high payment values experienced in month 6, yet the models performed better than expected at predicting these large payments.

```
        mean        sd cv_1_valid cv_2_valid cv_3_valid cv_4_valid cv_5_valid month          sub
1:  469.9268  94.92119   558.4242   505.3653   372.7790   549.1501   363.9153    m1 sub0813g.csv
2:  585.9584 388.17630   385.4031  1278.3843   382.1752   445.2796   438.5500    m2 sub0813g.csv
3:  497.0643 107.12404   395.8952   453.8251   418.8038   570.4381   646.3593    m3 sub0813g.csv
4:  524.9970  64.57057   617.4728   481.9898   487.4796   470.0466   567.9963    m4 sub0813g.csv
5:  636.8624 218.32373   480.1812   554.5950   963.2587   436.6362   749.6412    m5 sub0813g.csv
6: 1218.3550 188.80966  1119.7009  1092.9310  1545.5518  1215.5709  1118.0201    m6 sub0813g.csv
```
