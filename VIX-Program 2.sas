*2;

*Se importa datele dintr-un fisier de tip csv;

proc import datafile="/home/u58173551/Proiect/^GSPC (2).csv" dbms=csv
out=date replace;
run;

*Calculam randamentele în forma logaritmica;

proc sort data=date;by date;
data date;set date;
logprice=log (close);
logreturn=logprice-lag (logprice);
run;

*Se afi?eaza indicatorii distributiei ?i histograma randamentelor;
proc univariate data=date;
var logreturn;
histogram;
run;
quit;

data date_negativ;set date;
if logreturn<0;
x=-logreturn;

proc univariate data=date_negativ;
var x;
histogram;
run;



proc means data=date noprint;
output out=medii p10(logreturn) =q10 n(logreturn) =n mean(logreturn)=mu std(logreturn)=std;
run;

data date; if _n_=1 then set medii;set date;
run;

*Estimam func?ia de reparti?ie empirica;
proc sort data=date;by logreturn;
data date;set date;
if logreturn ne . then p=1/n;
run;

data date;set date;
f_rep+p;
run;

*Se afiseaza graficul functiei de repartitie empirice (EDF);
proc sgplot data=date;
series y=f_rep x=logreturn;
run;
quit;

*Selectam doar coada stinga a distributiei, 
cele mai mici 10% dintre valori ?i estimam parametrii distribu?iei Pareto;

data pareto;set date;
if logreturn<q10;


data pareto;set pareto;
x=abs(logreturn);
ln_x=log(x);
ff_rep=1-f_rep;
ln_f_rep=log(f_rep);
run;
proc reg data=pareto outest=parms;
model ln_f_rep=ln_x;
run;
quit;
*In datasetul ‘parms’ se afla valorile estimate pentru alfa si C;

data parms (keep=c alpha);set parms;
alpha=-ln_x;
c=exp(intercept/alpha);
run;


data pareto; if _n_=1 then set parms; set pareto;
run;

data pareto;set pareto;
f_rep_pareto=(c/x)**alpha;
f_rep_normal=1-cdf('normal',x,mu,std);
run;

proc sgplot data=pareto;
series x=x y=f_rep;
series x=x y=f_rep_pareto;
series x=x y=f_rep_normal;
run;

data parms; set parms;
prob=((c/abs(0.05))**alpha);
run;
