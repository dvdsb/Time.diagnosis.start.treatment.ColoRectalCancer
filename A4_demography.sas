proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data */
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ; 
libname ny "H:\Data\Derived\ny210706"; 
proc format ; 
value timedik 0 = '0-28 days' 1 = '29-56 days' 2 = '57- days' ; 
value timediksh 1 = '0-28 days' 2 = '29-56 days'  3 = '57- days' 4 = "Missing" 5 = "Total"; 
value timedikk 0 = '0-14 days' 1 = '15-28 days' 2 = '29-56 days' 3 = '57- days' ; 
value cntry 1="Sverige"
			2="Norden eller Europa(EU)"
			3="Other"; 
value radikal 0 = 'Icke radikal resektion'  1 = 'Radikal resektion' ; 
value lok 1 = 'Kolon' 2 = 'Rektum'; 
value sun  	7="Forskare" 
			6="Eftergymnasial mer än 3 år" 
			5="Eftergymnasial mindre än 3 år"
			4 = "Gymnasium 3 år"
			3 = "Gymnasium 1-2 år"
			2 = "Grundskola"
			1 = "Folkskola" ; 
value sunn 1 = "Folkskola/Grundskola" 2 = "Gymnasium (1-2 eller 3 år)" 3 = "Efter gymnasial";
value index -1 = "Before index admission" 0 = 'During index admission' 
			1 = "After index admission" 2 = ">90 days after index admission" 3 = 'Before/during or anytime after'; 
value stage 1 = "I" 2 = "II" 3 = "III" 4 = "IV" 5 = "Unknown";
value stagee 2 = "I-II" 3 = "III" 4 = "IV" 5 = "Unknown";
value ct 1="cT1-2" 2="cT3" 3="cT4" 4 = "cTX" ;
value cn 1="cN0" 2 = "cN1-2" 3 = "cNX" ;
value cm 1= "cM0" 2 = "cM1" 3 = "cMX" ; 
value pt 1="T0" 2 = "T1" 3 = "T2" 4 = "T3" 5 = "T4" 6 = "TX";
value pn 1 = "N0" 2 = "N1" 3 = "N2" 4 = "NX";
value pm 1="M0" 2 = "M1" 3 = "MX"; 
value sex 1="Male" 2="Female";
value asa 1="I"  2= "II" 3="III" 4 = "IV" 5 = "V"; 
value ny 0 = "No" 1 = "Yes" ; 
value lap 0 = 'Open' 1 = "Laparoscopy"; 
value konvlap 0 = "N/A" 1 = "Yes" 2 = "No";
value cci 0 = "0" 1 = "1" 2 = "2" 3 = ">3";  
value yr 0 = "2008-2012"  1 = "2013-2016"; 
value ylap 0 = "-2012, Open" 1="-2012, Laparoscopy" 2 = "2013-, Open" 3="2013-, Laparoscopy"; 
value $ylapp 
"2008_0" = "2008 Open"
"2008_1" = "2008 Lap"
"2009_0" = "2009 Open"
"2009_1" = "2009 Lap"
"2010_0" = "2010 Open"
"2010_1" = "2010 Lap"
"2011_0" = "2011 Open"
"2011_1" = "2011 Lap"
"2012_0" = "2012 Open"
"2012_1" = "2012 Lap"
"2013_0" = "2013 Open"
"2013_1" = "2013 Lap"
"2014_0" = "2014 Open"
"2014_1" = "2014 Lap"
"2015_0" = "2015 Open"
"2015_1" = "2015 Lap"
"2016_0" = "2016 Open"
"2016_1" = "2016 Lap" ; 
run; 
/* Derive variables */
data X ; set ny.X210706; 
if location ne . ; 
if Time_Diag_ANY_dik = 0 then Group1 = 1 ; 
if Time_Diag_ANY_dik = 1 then Group1 = 2 ;  
if Time_Diag_ANY_dik = 2 then Group1 = 3 ; 
if Time_Diag_ANY_dik = . then Group1 = 4 ; 
if A2_lapa = 0 then konvlap = 0 ; 
if A2_lapa = 1 & A2_konv = . then konvlap = 2 ; 
if A2_lapa = 1 & A2_konv = 1 then konvlap = 1 ; 
if CCI_weighted < 3 then CCI_cat = CCI_weighted; 
if CCI_weighted > 2 then CCI_cat = 3; 
if year_ < 2013 then Year_dik = 0 ; 
if year_ => 2013 then Year_dik = 1 ; 
format  Year_dik yr.;  
if Year_dik = 0 & A2_lapa = 0 then YLAP = 0 ; 
if Year_dik = 0 & A2_lapa = 1 then YLAP = 1 ; 
if Year_dik = 1 & A2_lapa = 0 then YLAP = 2 ; 
if Year_dik = 1 & A2_lapa = 1 then YLAP = 3 ; 
format YLAP ylap. ; 
Ymethod = compress(year_||'_'||A2_lapa) ; 
run; 
												
data X2 ; set X; 
Group1 = 5 ; output; 
set X; output ;  
format Group1  timediksh. konvlap konvlap. A2_lapa lap.; 
run; 
proc sort; by lopnr location Group1 ; run; 
proc transpose data = X2 out = X3;
by lopnr location Group1; 
var sex uicc_final pt_cat lung asa_class neoadj_ct neoadj_rt konvlap
	A2_lapa cT cN cM pN pM bcntry utbildning CCI_cat Year_dik YLAP Ymethod; 
run; 
proc sort data = X3; 
by _NAME_ _label_ location Group1 ; run; 

proc freq data = X3 noprint; 
by _NAME_ _label_ location Group1 ;
table COL1 / out = freq ; 
run; 
data freq2;  length res $ 16; set freq; 
Res = compress(COUNT||'('||put(PERCENT, f11.0)||'%)');
run; 
proc sort data = freq2; 
by _NAME_ _label_ COL1 location; 
run; 
proc transpose data = freq2 out = freq3 ; 
by _NAME_ _label_ COL1 location; 
var Res; 
id Group1 ; 
run; 
data freq4 ; length newcol $ 80 ; set freq3; 
if _NAME_ = "A2_lapa" then newcol = put(COL1, lap.); 
if _NAME_ = "asa_class" then newcol = put(COL1, asa.); 
if _NAME_ = "bcntry" then newcol = put(COL1, cntry.); 
if _NAME_ = "cm" then newcol = put(COL1, cm.); 
if _NAME_ = "cn" then newcol = put(COL1, cn.); 
if _NAME_ = "ct" then newcol = put(COL1, ct.); 
if _NAME_ = "konvlap" then newcol = put(COL1, konvlap.); 
if _NAME_ = "lung" then newcol = put(COL1, ny.); 
if _NAME_ = "neoadj_ct" then newcol = put(COL1, ny.); 
if _NAME_ = "neoadj_rt" then newcol = put(COL1, ny.); 
if _NAME_ = "pm" then newcol = put(COL1, pm.); 
if _NAME_ = "pn" then newcol = put(COL1, pn.); 
if _NAME_ = "pt_cat" then newcol = put(COL1, pt.); 
if _NAME_ = "sex" then newcol = put(COL1, sex.); 
if _NAME_ = "uicc_final" then newcol = put(COL1, stage.); 
if _NAME_ = "utbildning" then newcol = put(COL1, sunn.); 
if _NAME_ = "CCI_cat" then newcol = put(COL1, cci.); 
if _NAME_ = "Year_dik" then newcol = put(COL1, yr.); 
if _NAME_ = "YLAP" then newcol = put(COL1, ylap.); 
if _NAME_ = "Ymethod" then newcol = put(COL1, ylapp.); 
run; 
data freq4; set freq4; 
n=_n_; 
keep _NAME_ _LABEL_ newcol location 
		_0_28_days _29_56_days _57__days Missing Total n; 
run; 
proc sort; by _NAME_ _LABEL_ newcol location ; run; 
/*******************************************************************************************************/
proc transpose data = X2 out = X33;
by lopnr location Group1; 
var diagage BMI CCI_weighted DispInkKE04 ; 
run; 
proc sort data = X33; 
by _NAME_ _label_ location Group1 ; run; 

proc univariate data = X33 noprint; 
by _NAME_ _label_ location Group1 ;
var COL1  ;
output out = X44 median=median q1=q1 q3=q3 min=min max=max;  
run; 
data X44; length MedQ1Q3 $ 16  MinMax $ 16; set X44; 
MedQ1Q3 = compress(put(median,f11.0)||'('||put(q1,f11.0)||';'||put(q3,f11.0)||')');
MinMax = compress(put(min,f11.0)||';'||put(max,f11.0));
run; 
proc sort data = X44; 
by _NAME_ _label_  location; 
run; 
proc transpose data = X44 out = X55 ; 
by _NAME_ _label_  location; 
var MedQ1Q3; 
id Group1 ; 
run; 
proc transpose data = X44 out = X66 ; 
by _NAME_ _label_  location; 
var Minmax; 
id Group1 ; 
run; 
data X55 ; length newcol $ 80 _NAME_ $ 10 _LABEL_ $ 40  ; set X55; 
newcol = "Median(Q1; Q3)" ; 
n=_n_; 
keep _NAME_ _LABEL_ newcol location 
		_0_28_days _29_56_days _57__days Missing Total n; 
run;
proc sort; by _NAME_ _LABEL_ newcol location ; run; 
data X66 ; length newcol $ 80 _NAME_ $ 10 _LABEL_ $ 40  ; set X66; 
newcol = "Min; max" ; 
n=_n_; 
keep _NAME_ _LABEL_ newcol location 
		_0_28_days _29_56_days _57__days Missing Total n; 
run;  
proc sort; by _NAME_ _LABEL_ newcol location ; run; 

data demo ; merge freq4 X55 X66 ; 
by _NAME_ _LABEL_ newcol location ; 
run; 
data demo ; retain
_NAME_ _LABEL_ newcol location
_0_28_days _29_56_days _57__days Total Missing n; 
set demo ; 
run; 
proc sort data = demo ; 
by location _NAME_ n ;
run;  
/* Save output */
data ny.demography210706; set demo ; 
run; 
