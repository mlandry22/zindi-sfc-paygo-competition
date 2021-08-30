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
* Created origianlly on MacOS Catalina; reproduction performed on MacOS Big Sur

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
The modelling is mostly carried out through straightforward XGBoost models, trained in H2O.
The six different targets are related, so smoothing the six as a set was experimented with and a 70/30 average of the original prediction (70%) and the average of all six predictions (30%) was used.

One exception is that an unsupervised clustering of all payment values occurs in a kMeans model. The cluster IDs are used in the modelling step. This model trains very quickly and did provide a slight uplift.

## Additional Comments
It was particularly interesting that once the prediction scores of the public test set achieved a particular relative score, it seemed most new ideas made an insignificant difference. Most of those ideas had been vetted through cross-validation to show some gain, but only those that showed gains in both were retained. However, a look at the private leaderboard scores shows that this strategy was not optimal. The best private leaderboard score was one of the first models created, and the improvement was enough that even if estimating the performance loss of removing the leaked column, it was still likely the best overall model.

One of the larger factors of a good or bad score appeared to be the way the large payments in month6 were handled. Very often, we would see a customer pay over 10x their average payment in the last month. I was not sure if the model was properly finding patterns that indicated a customer may do this, so I occasionally softened the impact, but each time I did, the accuracy decreased. So the model appears to have found a reliable signal about when customers may make such a large payment. I was unable to spot such behavior in a more intuitive/interpretible manner (there was some discussion on the forums that indicate other competitors were able to do so). I intended to experiment more with accounting for the 70/30 average so that it did not spread higher-than-average month-6 payments across the set, but did not have the time to experiment with that idea.

It was surprising to see that all training data had clean payment history, yet the payment history in the full detail contains many missed payments. I assumed this was intentional, and proceeded modelling with the data as provided in training. If this happened to be unintentional, it will merit a reconsideration of all modelling from all competitors. In general, features that counted zeros and realigned payments and missed payments did influence the model as much as I expected, but this is likely due to the guarantee of no missed payments in the final 6 months of training (and presumably test).
