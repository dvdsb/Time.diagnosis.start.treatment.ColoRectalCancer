proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data	*/
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ;
libname ny "H:\Data\Derived\ny210706"; 

data Y ; set ny.Y210706; 
run;
proc sort; by lopnr ; 
run; 	
data X ; set ny.X210706; 
run;
proc sort data = X; 
by lopnr ; run; 
proc format ; 
value timedik 0 = '0-28 days' 1 = '29-56 days' 2 = '57- days' ; 
value timediksh 1 = '0-28 days' 2 = '29-56 days' 3 = '57- days' ; 
value timedikk 0 = '0-14 days' 1 = '15-28 days' 2 = '29-56 days' 3 = '57- days' ; 
value cntry 1="Sverige"
			2="Norden eller Europa(EU)"
			3="Other"; 
value type 	1 = "Första behandling: kirurgi" 2 = "Första behandling: Chemo" 
			3 = "Första behandling: Strålning" 4 = "Första behandling: Kombo-beh."; 
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
value stage 1 = "I" 2 = "II" 3 = "III" 4 = "IV" 5 = "Unknown" 0 = "0";
value ct 1="cT1-2" 2="cT3" 3="cT4" 4 = "cTX" ;
value cn 1="cN0" 2 = "cN1-2" 3 = "cNX" ;
value cm 1= "cM0" 2 = "cM1" 3 = "cMX" ; 
value pt 1="T0" 2 = "T1" 3 = "T2" 4 = "T3" 5 = "T4" 6 = "TX";
value pn 1 = "N0" 2 = "N1" 3 = "N2" 4 = "NX";
value pm 1="M0" 2 = "M1" 3 = "MX"; 
value sex 1="Male" 2="Female";
value asa 1="I"  2= "II" 3="III" 4 = "IV" 5 = "V"; 
value ny 0 = "No" 1 = "Yes" ; 
run; 
/*___________________________________________________________________________________________	*/
										data imputed_covar; set ny.IMP_50imps_210706;
										run; 
										/*  Use simple imputations for the dose reposne curve	*/
										data imp ; set imputed_covar ; 
										if _Imputation_ = 1 ;   /*OBS! */
										run; 	
data X ; set X ; 
keep lopnr 	location lung
		Time_Diag_ANY 
		First_TRT_type ;
run; 
proc sort; by lopnr ; run; 														
proc sort data = imp; by lopnr ; run; 
proc sort data = Y; by lopnr index; run; 
data XY ; merge Y X imp ; 
by 	lopnr ; 
run; 
data XY; set XY ;  
if index = 3 ; 
tid = FUopdate/365.25; 	
offset = log(tid); 
format  bcntry cntry. asa_class asa. sex sex. uicc_final stage. utbildning sunn. pt_cat pt.;
run; 
proc sort data = XY nodupkey ; 
by lopnr ; 
run;  
proc sort data = XY ; by location; run; 
data XY2; set XY ; 
run; 
proc sort data = XY2; 
by location; run; 
/* Levels to condition on when estimating the adjusted dose response curve */
data inrisk_; 
input year_c Time_Diag_ANY A2_lapa  BMIc diagagec DispInkKE04_c CCI_weighted sex 
uicc_final pt_cat LUNG;
datalines ; 
0	0	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	0	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	7	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	7	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	14	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	14	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	21	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	21	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	28	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	28	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	35	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	35	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	42	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	42	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	49	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	49	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	56	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	56	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	63	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	63	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	70	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	70	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	77	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	77	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	84	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	84	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	91	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	91	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	98	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	98	1	-0.055	0.32	-0.18	0.01	2	2	4	0
0	105	0	-0.055	0.32	-0.18	0.01	2	2	4	0
0	105	1	-0.055	0.32	-0.18	0.01	2	2	4	0
; 
run; 

data inrisk_ ; set inrisk_ ; 
format A2_lapa  lap.
		sex sex. 
		uicc_final stage. pt_cat pt. lung ny.; 
run; 

proc phreg data = XY2  covs(aggregate); 
by location;
class A2_lapa 	
		sex uicc_final pt_cat LUNG   ;
effect year_cS=spline(year_c/basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect Time_Diag_ANY_S=spline(Time_Diag_ANY/basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS=spline(BMIc/basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS=spline( diagagec/basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS=spline( DispInkKE04_c/basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS=spline( CCI_weighted/basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = A2_lapa              					
							sex uicc_final pt_cat
							Time_Diag_ANY_S
							Time_Diag_ANY_S*A2_lapa
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
id surgery_hospital ; 
strata A2_lapa ; 
store sasuser.coxr; 
ods output ParameterEstimates = prms_ ; 
baseline covariates = inrisk_ out=pred1 survival=_all_/rowid=Group ; 
run;

data pred2; set pred1; 
run; 
proc sort data = pred2; 
by location year_c Time_Diag_ANY A2_lapa  BMIc diagagec DispInkKE04_c CCI_weighted sex 
uicc_final pt_cat LUNG tid; 
run; 
data pred3; set pred2; 
by location year_c Time_Diag_ANY A2_lapa  BMIc diagagec DispInkKE04_c CCI_weighted sex 
uicc_final pt_cat LUNG tid; 
if tid <= 5; 
run; 
data pred4; set pred3; 
by location year_c year_c Time_Diag_ANY A2_lapa  BMIc diagagec DispInkKE04_c CCI_weighted sex 
uicc_final pt_cat LUNG tid; 
if last.LUNG; 
run;
/*______________________________________________________________________________________________________________________________	*/
data Pld_kolon_Gr2 ; set pred4; 
if location = 1 ; 
Group = A2_lapa ; 
format Group lap. ; 
run; 
data Pld_rektum_Gr2 ; set pred4; 
if location = 2 ;
Group = A2_lapa ;  
format Group lap. ; 
run; 
/* Make the plots 	*/
%macro FG(dt, ttl, ttl2, cut, imagename);
ods graphics  / imagefmt=tiff 
				imagename= &imagename.
				HEIGHT=(16/1.5)in WIDTH=(24/1.5)in  
				noborder; 
ods listing gpath = "H:\LogOutput" image_dpi=500 ; 
ods graphics  / attrpriority = none  ANTIALIASMAX=4100 ; 
title height=12pt j=l &ttl. ; 
proc sgplot data = &dt noautolegend; 
styleattrs  DATALINEPATTERNS=(  Longdash Solid ) 
			DATACOLORS=(red blue) 
			DATACONTRASTCOLORS=(red blue) 
			DATAFILLPATTERNS=(L1 L2)
			axisbreak=slantedright;
series y = survival x=Time_Diag_ANY / group =  Group name='s'  lineattrs=(thickness=2); 
band x=Time_Diag_ANY lower=LowerSurvival upper=UpperSurvival / group = Group  
			FILLATTRS=( transparency = 0.5)   ; 
xaxis label = "Days from diagnosis to initiation of treatment" labelattrs=(weight=bold); 
yaxis label= "Five year survival probability"  labelattrs=(weight=bold) 
		grid values=(.0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1)   
		ranges=(-.01-.05 &cut-1)    /*18*/
			display=(noline noticks);
	keylegend 's' / title= &ttl2. linelength=50 location = inside 
					titleattrs=(Size=8)
					valueattrs=(Size=8)
				position=BOTTOMLEFT across=1;
run; quit; 
%mend;
/* Save the plots */
%FG(dt=Pld_kolon_Gr2, ttl="Colon cancer", 
	ttl2="Technique" , cut = .7, imagename = "kolon_dose_response_210706")
%FG(dt=Pld_rektum_Gr2, ttl="Rectal cancer", 
	ttl2="Technique", cut = .7, imagename = "rektum_dose_response_210706")

