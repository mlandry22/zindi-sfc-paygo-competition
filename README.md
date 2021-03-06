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
  * Metrics: 0.1.4
* Java: 1.8.0_181

The R version is over two years old, but more recent versions should run these packages identically.

## Zindi documentation expectations:
* Data used: only files provided as part of the competition
* Output data and where they are stored: local drive; altering all locations from "/Users/mlandry003/Documents/zindi-sfc-paygo-solar/sfc-paygo-solar-credit-repayment-competition/" to the desired location will not affect the input or output, as long as both exist at the same level. 
* Extra notes
  * Usage of the leaked feature: `LastPaymentDate` was removed as requested. Line99 uses the code `meta[,LastPaymentDate:=NULL]` will removes it from the meta data frame prior to it being used in the merges to the train and test sets.
  * Code structure: the code was run as three separate files, to break apart the process without continually recreating the pieces. One can run them by simply calling them in order with three `source({file.R})` files. But for simplicity, the three have been concatenated together as `single_script_Aug13h.R`, so this script is all that is needed to run. Due to being strictly concatenated, the locations and library calls are repeated, but this causes no harm.

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
While reproducibility of the folds was removed from a random selection, seeds into the model were not always consistent, except the kMeans. I have run the script top to bottom a couple times and get answers hat have a 0.996 and 0.997 correlation. Scores are nearly identical, but very slightly different. The seed used produces a score just barely better than the actual submission (692.733632637332 vs 692.847512832696, correlation 0.9970816).

## Additional Comments
It was particularly interesting that once the prediction scores of the public test set achieved a particular relative score, it seemed most new ideas made an insignificant difference (in my case). Most of those ideas had been vetted through cross-validation to show some gain, but only those that showed gains in both were retained. However, a look at the private leaderboard scores shows that this strategy was not optimal. The best private leaderboard score was one of the first models created, and the improvement was enough that even if estimating the performance loss of removing the leaked column, it was still likely the best overall model.

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

## Variable importance
Top 10 features for each of the monthly models:

MONTH1

```
         variable relative_importance scaled_importance percentage
1          m1Paid 146723749888.000000          1.000000   0.299702
2          middle  59245166592.000000          0.403787   0.121016
3          remain  33521485824.000000          0.228467   0.068472
4      UpsellDate  23986327552.000000          0.163480   0.048995
5  dateFromUpsell  23899203584.000000          0.162886   0.048817
6           m2Pct  12925257728.000000          0.088092   0.026401
7          m6Paid  11501818880.000000          0.078391   0.023494
8          m4Paid  11334920192.000000          0.077253   0.023153
9          m3Paid  11323867136.000000          0.077178   0.023130
10         m2Paid  10724717568.000000          0.073095   0.021907
```

MONTH2
```
            variable relative_importance scaled_importance percentage
1  Occupation.Farmer 154042843136.000000          1.000000   0.193336
2             m6Paid 135701520384.000000          0.880934   0.170316
3             m1Paid 124267954176.000000          0.806710   0.155966
4             m2Paid  75801853952.000000          0.492083   0.095137
5             middle  54955327488.000000          0.356754   0.068973
6             remain  46733361152.000000          0.303379   0.058654
7       Town.Kericho  39632531456.000000          0.257283   0.049742
8             m1Date   9895418880.000000          0.064238   0.012420
9             m9Paid   9324230656.000000          0.060530   0.011703
10            m3Paid   8781887488.000000          0.057009   0.011022
```

MONTH3
```
         variable relative_importance scaled_importance percentage
1          m1Paid  99856490496.000000          1.000000   0.203143
2          middle  58782973952.000000          0.588675   0.119585
3          remain  47716204544.000000          0.477848   0.097072
4  dateFromUpsell  30953207808.000000          0.309977   0.062970
5         maxPaid  14835605504.000000          0.148569   0.030181
6      UpsellDate  14666413056.000000          0.146875   0.029837
7          m6Paid  13636589568.000000          0.136562   0.027742
8          m2Paid  13213291520.000000          0.132323   0.026881
9     m1RemainPct  10150343680.000000          0.101649   0.020649
10        ttlPaid   9496797184.000000          0.095104   0.019320
```

MONTH4
```
         variable relative_importance scaled_importance percentage
1          middle  80784580608.000000          1.000000   0.153242
2          m1Paid  57313214464.000000          0.709457   0.108719
3          remain  54337789952.000000          0.672626   0.103075
4  dateFromUpsell  33231118336.000000          0.411355   0.063037
5      UpsellDate  26765240320.000000          0.331316   0.050772
6     m1RemainPct  17161409536.000000          0.212434   0.032554
7          m5Paid  16626149376.000000          0.205808   0.031539
8          m6Paid  16284816384.000000          0.201583   0.030891
9          m2Paid  13413720064.000000          0.166043   0.025445
10     Town.Nandi  12164807680.000000          0.150583   0.023076
```

MONTH5
```
             variable relative_importance scaled_importance percentage
1              m1Paid  72747106304.000000          1.000000   0.114135
2              middle  58900598784.000000          0.809662   0.092411
3        Town.Bungoma  57872289792.000000          0.795527   0.090798
4              remain  53401251840.000000          0.734067   0.083783
5       AccessoryRate  38489518080.000000          0.529087   0.060387
6      Region.Western  30552711168.000000          0.419985   0.047935
7              m2Paid  29183516672.000000          0.401164   0.045787
8         m1RemainPct  24766838784.000000          0.340451   0.038857
9  TotalContractValue  22462844928.000000          0.308780   0.035243
10             m5Paid  18062297088.000000          0.248289   0.028339
```

MONTH6: strong preference toward the two upsell features
```
           variable relative_importance scaled_importance percentage
1    dateFromUpsell 267745787904.000000          1.000000   0.126044
2        UpsellDate 208729194496.000000          0.779580   0.098262
3  dateFromExpected 190079893504.000000          0.709927   0.089482
4            m1Paid  85670699008.000000          0.319970   0.040330
5            remain  82062344192.000000          0.306494   0.038632
6  maxPaidPastFirst  67533258752.000000          0.252229   0.031792
7   Town.West Pokot  61227921408.000000          0.228679   0.028824
8       m1RemainPct  58988277760.000000          0.220314   0.027769
9            m1Date  53618675712.000000          0.200260   0.025242
10          ttlPaid  53503717376.000000          0.199830   0.025187
```
