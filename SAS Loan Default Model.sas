/*Austin Griffith
/*11/17/2017
/*Assignment 6.2
/*Loan Default Modeling*/

/*web address of annoticks sample code*/
/*http://support.sas.com/kb/42/513.html*/

/*web address where loan data was offered*/
/*https://www.lendingclub.com/info/prospectus.action*/

OPTIONS ls = 70 nodate nocenter;
OPTIONS missing = '';

/*file paths need to be updated according to current computer*/
%let Ppath = P:\Loan Default;
%let Lpath = P:\Loan Default\Loan_Data;

/*--------------------------Import Loan3x Data--------------------------*/
/*get loan stats 3a*/
proc import datafile = "&Lpath\LoanStats3a.csv"
out = LS3a
dbms = csv replace;
getnames = yes;
run;

/*get loan stats 3b*/
proc import datafile = "&Lpath\LoanStats3b.csv"
out = LS3b
dbms = csv replace;
getnames = yes;
run;

/*get loan stats 3c*/
proc import datafile = "&Lpath\LoanStats3c.csv"
out = LS3c
dbms = csv replace;
getnames = yes;
run;

/*get loan stats 3d*/
proc import datafile = "&Lpath\LoanStats3d.csv"
out = LS3d
dbms = csv replace;
getnames = yes;
run;

/*--------------------------Clean up Loan stats a--------------------------*/
/*sets character variables to numeric values*/
data LS3a;
set LS3a;
mslr = input(mths_since_last_record,3.);
msld = input(mths_since_last_major_derog,3.);
drop mths_since_last_record mths_since_last_major_derog;
run;

/*resets variable names after character -> numeric is complete*/
data LS3a;
set LS3a;
mths_since_last_record = mslr;
mths_since_last_major_derog = msld;
drop mslr msld;
run;

/*--------------------------Import Loan Stats 2016 Quarters--------------------------*/
/*import 2016q1*/
proc import datafile = "&Lpath\LoanStats_2016Q1.csv"
out = LSQ_1
dbms = csv replace;
getnames = yes;
run;

/*import 2016q2*/
proc import datafile = "&Lpath\LoanStats_2016Q2.csv"
out = LSQ_2
dbms = csv replace;
getnames = yes;
run;

/*import 2016q3*/
proc import datafile = "&Lpath\LoanStats_2016Q3.csv"
out = LSQ_3
dbms = csv replace;
getnames = yes;
run;

/*import 2016q4*/
proc import datafile = "&Lpath\LoanStats_2016Q4.csv"
out = LSQ_4
dbms = csv replace;
getnames = yes;
run;

/*macro to keep variables in quarter data*/
/*drops all variables not needed due to numeric/character errors in merge*/
/*creates year value for modeling*/
%macro Qkeep;
%do k = 1 %to 4;
data LSQ_&k;
set LSQ_&k;
fyear = 2016;
keep loan_status term fyear
revol_util int_rate mths_since_last_delinq dti
total_pymnt loan_amnt last_pymnt_amnt total_acc
grade sub_grade;
run;
%end;
%mend;

%Qkeep;

/*--------------------------Combine Loan Stats--------------------------*/
/*combines abcd data*/
/*doesn't need to merge by any variable since no overlap*/
/*creates year variable for modeling*/
data Loan_S;
set LS3a LS3b LS3c LS3d;
if length(issue_d) = 6 then fyear = ("20" || substr(issue_d,1,2)) + 0;
else fyear = ("200" || substr(issue_d,1,1)) + 0;
run;

/*combines quarter data*/
data Loan_Q;
set LSQ_1 LSQ_2 LSQ_3 LSQ_4;
run;

/*combines all data*/
data Loan_Stats;
set Loan_Q Loan_S;
run;

/*--------------------------Variable Calculations--------------------------*/
/*gets macro variable to easily call all variables*/
%let var = util int delinq dti total_paid rec_paid grade_value total_acc;

/*marks loans with default flags*/
/*removes observations with no loan status values*/
/*calculates variables*/
data Loan_Stats;
set Loan_Stats;
if Loan_Status = "Fully Paid" then default = 0;
else if Loan_Status = "Charged Off" then default = 1;
else if Loan_Status = "Default" then default = 1;
else delete;

util = input(substr(revol_util,1,length(revol_util)-1),8.2);
int = input(substr(int_rate,1,length(int_rate)-1),8.2);
dti = dti + 0;
total_paid = total_pymnt/loan_amnt;
rec_paid = last_pymnt_amnt/loan_amnt;

if mths_since_last_delinq > 0 then mths_since_last_delinq = 1;
if nmiss(of mths_since_last_delinq) then mths_since_last_delinq = 0;
delinq = mths_since_last_delinq;

/*weighted grades*/
/*letter grade value*/
if grade = "A" then grade_value = 7;
else if grade = "B" then grade_value = 6;
else if grade = "C" then grade_value = 5;
else if grade = "D" then grade_value = 4;
else if grade = "E" then grade_value = 3;
else if grade = "F" then grade_value = 2;
else if grade = "G" then grade_value = 1;
else delete;

/*sub grade value*/
sub = substr(sub_grade,2);
sub1 = input(sub,8.0);
sub_value = (sub1 - 1)*0.2;

/*weighted loan grade*/
grade_value = grade_value - sub_value;

if nmiss(of &var) then delete;
keep &var fyear default;
run;

/*--------------------------In Sample--------------------------*/
/*opens up pdf file for output*/
ods pdf file = "&Ppath\Loan_model_data.pdf";

/*gets data set for in-sampling*/
data Loan_in;
set Loan_Stats;
run;

proc sort data = Loan_Stats;
by util;
run;

/*sorts data by year*/
proc sort data = Loan_in;
by fyear;
run;

/*logistic process for loan default values*/
/*gets beta values for each variable*/
proc logistic data = Loan_in descending
outest = in_results;
title1 "In-Sample Logistics";
model default(event = '1') = &var;
run;

/*renames beta values, Bi, for each variable*/
/*will allow for merge while avoiding overlap in names*/
data in_results;
set in_results;
beta_util = util;
beta_int = int;
beta_delinq = delinq;
beta_dti = dti;
beta_total_paid = total_paid;
beta_rec_paid = rec_paid;
beta_grade = grade_value;
beta_acc = total_acc;
drop &var;
run;

/*merges the beta values with variables*/
/*multiplies beta and variables for Bi*xi in default equation*/
/*finds hazard estimate using Bi*xi*/
data in_default;
if _n_ = 1 then set in_results;
set Loan_in;
sum_Bx =
beta_util*util +
beta_int*int +
beta_delinq*delinq +
beta_dti*dti +
beta_total_paid*total_paid +
beta_rec_paid*rec_paid +
beta_acc*total_acc +
beta_grade*grade_value;

D_estimate = exp(sum_Bx)/(1 + exp(sum_Bx));
run;

/*ranks data into decile by estimated default probability*/
proc rank data = in_default
out = in_default_rank
groups = 10 descending;
var D_estimate;
ranks hazard; /*names rank variable*/
run;

/*gets default values in each decile*/
data in_check;
set in_default_rank;
if default = 1;
run;

/*--------------------------In Sample Check Graph--------------------------*/
/*orders by rank for counting*/
proc sort data = in_check;
by hazard;
run;

/*gets check data for each year in check library*/
/*used to check how many defaults per decile*/
proc means data = in_check N NOPRINT;
var default;
by hazard;
output out = in_check (drop = _TYPE_ _FREQ_) N=;
run;

/*normalizes default data per decile*/
proc sql NOPRINT;
create table in_graph as
select hazard, default/sum(default) as default,
1 as Data_Set
from in_check
quit;

/*sorts data by static variable for proc print*/
proc sort data = in_graph;
by Data_Set;
run;

/*prints percentage values per decile estimated in model*/
proc print data = in_graph;
title2 "Out-Sample Decile Percentages";
by Data_Set;
run;

/*annotations for bar graph of deciles*/
data annoticks;
length function color $ 8;
retain color 'black' when 'a' xsys '2';
set in_graph;
by hazard;

if first.default then do;
function = 'move';
ysys = '1';
midpoint = hazard;
y = 0;
output;

function = 'draw';
ysys = 'a'; /* relative coordinate system */
midpoint = hazard;
y = -.75;
line = 1;
size = 1;
output;
end;
run;

/*generate the graph of default in deciles*/
proc gchart data = in_graph;
vbar hazard / sumvar = default discrete
width = 10 annotate = annoticks
maxis = axis1 raxis = axis2;
axis1 label = ('Default Decile');
axis2 label = (angle=90 'Defaults on Mortgages (% estimated by model)');
title2 'Defaults per Decile in In-sample, 2007 to 2016';
run;
quit;


/*--------------------------Out Sample--------------------------*/
/*sets title for out sample*/
title1 "Out-Sample Logistics";

/*gets data set for 07 to 14 for logistic data*/
data out_left;
set Loan_Stats;
if fyear <= 2014;
run;

/*gets data set for 15 to 16 for out sample estimation*/
data out_right;
set Loan_Stats;
if fyear > 2014;
run;

/*sorts data by year*/
proc sort data = out_left;
by year default;
run;

proc sort data = out_right;
by year default;
run;

/*logistic process for default values*/
/*gets beta values for each variable*/
proc logistic data = out_left descending
outest = out_results;
title2 "Out-Sample Logistics for 2007-2014";
model default(event = '1') = &var;
run;

/*renames beta values, Bi, for each variable*/
/*will allow for merge while avoiding overlap in names*/
data out_results;
set out_results;
beta_util = util;
beta_int = int;
beta_delinq = delinq;
beta_dti = dti;
beta_total_paid = total_paid;
beta_rec_paid = rec_paid;
beta_acc = total_acc;
beta_grade = grade_value;
drop &var;
run;

/*merges the beta values with variables*/
/*multiplies beta and variables for Bi*xi in hazard equation*/
/*finds hazard estimate using Bi*xi*/
data out_hazard;
if _n_ = 1 then set out_results;
set out_right;
sum_Bx =
beta_util*util +
beta_int*int +
beta_delinq*delinq +
beta_dti*dti +
beta_total_paid*total_paid +
beta_rec_paid*rec_paid +
beta_acc*total_acc +
beta_grade*grade_value;

D_estimate = exp(sum_Bx)/(1 + exp(sum_Bx));
run;

/*ranks data into decile by estimated hazard*/
proc rank data = out_hazard
out = out_hazard_rank
groups = 10 descending;
var D_estimate;
ranks hazard; /*names rank variable*/
run;

/*gets default values in each decile*/
data out_check;
set out_hazard_rank;
if default = 1;
run;

/*--------------------------Out Sample Check Graph--------------------------*/
/*orders by rank for counting*/
proc sort data = out_check;
by hazard;
run;

/*gets check data for each year in check library*/
/*used to check how many defaults per decile*/
proc means data = out_check N NOPRINT;
var default;
by hazard;
output out = out_check (drop = _TYPE_ _FREQ_) N=;
run;

/*normalizes default data per decile*/
proc sql NOPRINT;
create table out_graph as
select hazard, default/sum(default) as default,
1 as Data_Set
from out_check
quit;

/*sorts data by static variable for proc print*/
proc sort data = out_graph;
by Data_Set;
run;

/*prints percentage values per decile estimated in model*/
proc print data = out_graph;
title2 "Out-Sample Decile Percentages";
by Data_Set;
run;

/*annotations for bar graph of deciles*/
data annoticks;
length function color $ 8;
retain color 'black' when 'a' xsys '2';
set out_graph;
by hazard;

if first.default then do;
function = 'move';
ysys = '1';
midpoint = hazard;
y = 0;
output;

function = 'draw';
ysys = 'a'; /* relative coordinate system */
midpoint = hazard;
y = -.75;
line = 1;
size = 1;
output;
end;
run;

/*generate the graph of defaults in deciles*/
proc gchart data = out_graph;
vbar hazard / sumvar = default discrete
width = 10 annotate = annoticks
maxis = axis1 raxis = axis2;
axis1 label = ('Default Decile');
axis2 label = (angle=90 'Defaults on Mortgages (% estimated by model)');
title2 'Defaults per Decile in Out-sample, 2015 to 2016';
run;
quit;

ods pdf close; /*closes roll sample pdf*/
