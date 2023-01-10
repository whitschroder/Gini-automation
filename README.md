# Gini Automation for Large Datasets
This R code automates the calculation of Gini coefficients and summary statistics across the large datasets. The code requires an input .csv file in the following format (see SampleData.csv):

| Name  | Metric      |
| ----- | ----------- |
| 11444 | 160.1165767 |
| 11444 | 192.3794014 |
| 11444 | 57.26671944 |
| 11444 | 195.2263164 |
| 11445 | 177.3647787 |
| 11445 | 64.85372645 |
| 11445 | 211.2993753 |
| 11445 | 99.88499478 |

Name is any string that identifies how data will be grouped; for example, the name of an individual, a place, an archaeological site, a neighborhood, etc; or in this case the unique identifier for a NASA G-LiHT tile ([https://doi.org/10.1016/j.jasrep.2020.102543]). Metric is the 
