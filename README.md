# loan_default_model
## Data

The data was provided by Lending Club, for 2007 to 2016. The loan data files can be downloaded [here.](https://drive.google.com/open?id=1L0_BR8YUibOQtQStiiUmh3G6YQOMbn9o) To use the data, simply open the downloaded zipped file and put the csvs in the same directory as the sas code. The LoanStats a-d files are cleaned. The quarterly 2016 data is not cleaned, and therefore additional code had to be written to account for discrepencies in how variables were written, and odd character/numeric value mismatches. There is also a dictionary of variables provided, which is useful in understanding the metrics gathered in Lending Club accounts.

## Model Variables

Explanation of Variables:
- Revolving utilization rate
    Measures the amount of credit the borrower is using relative to available revolving credit. It should be expected that as the revolving utilization rate increases, more credit is being used. This implies the borrower is closer to defaulting (+).
- Interest rate on the loan
    As the interest rate on the loan increases, it reflects poorly on the reliability of the borrower. It also makes the loan harder to pay back, increasing probability of default (+).
- Delinquency
    Determined from months since last delinquency. If the borrower had a listed delinquency of payments, the value is set to 1. If there was no listed delinquency, it is set to zero. It is expected that if the borrower has a past delinquency, he/she is more likely to default in the future (+).
- DTI
    Measures the total monthly debt payments on obligations as a percentage of reported income. If the borrower has a higher DTI, then the borrower has a larger amount of debt payments relative to their income. This should increase likelihood of default (+).
- Total payback as a percentage of the total loan
    It was expected that the smaller percentage of the loan paid back, the easier it would be for the borrower to walk away (-).
- Recent payback as a percentage of the total loan
    An indicator of the borrower’s current financial situation. If they are paying back in very small fractions of the loan’s total value, then it would be implied there is a strained financial situation (-).
- Loan Grade
    The grade was weighted to represent the dependability of the borrower. The loans were rated A through G, with sub-grades of 1 to 5. Each value was given a weighted score, so that A1 was a 7, A2 was 6.8, and so on. As the grade value decreased, the default was expected to increase (-).
- Total credit lines
    This was a measure of the credit lines on the borrower’s credit file. It could be seen as an indicator of the borrower’s reliability. As the number of credit lines increased, it would be implied that the financial stability of the borrower decreased, leaving them prone to default (+).

Default of loans were then determined by markers set by the "Loan Status" variable. If they are paid off, then they are marked with a zero, for no default. If they are carried off or defaulted, then they are marked with a one, for default.

From here, a logistical regression can be used to determine coefficients for each variable that can be applied to a model used to estimate laon default.

## Model Calculations

- In-Sample
    For an initial model, an in-sample method is used. The model is created using data from     2007 to 2016, and then projected over the same time period. This is used as an estimator of whether the variables can be used to accurately estimate default.

- Standard Out-Sample
    A standard out-sample model is then determined. A static model is created from 2007 to 2014, and is then used to estimate the bankruptcy for each year from 2015 to 2016. Due to the short time period being estimated after the model data, it can be viewed as an accurate estimation. Furthermore, due to the closeness of model period and estimation period, there is little need for a rolling model in this scenario.

## Model Comparison

The output data allows for a comparison of the logistic output between the in-sample and standard out-sample. The Chi-Square statistic indicates the variable's accuracy at determining default. For the in-sample, DTI has a Pr>Chi-Square of ~0.15, implying DTI is the least accurate predictor of default amongst all the variables. However, in the out-sample model, it has a extremly small Pr>Chi-Square like all other variables.

The in-sample and out-sample both have roughly 98% of all defaults captured within the first two deciles of the model. This implies that the model is an accurate predictor of default for this given sample of data.
