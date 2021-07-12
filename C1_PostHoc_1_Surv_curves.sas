proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data	*/
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ; 
libname ny "H:\Data\Derived\ny210706"; 
data X ; set ny.X210706; 
run;
data Y ; set ny.Y210706; 
run;

proc format ; 
value timedik 0 = '0-28 days' 1 = '29-56 days' 2 = '57- days' ; 
value timediksh 1 = '0-28 days' 2 = '29-56 days' 3 = '57- days' ; 
value timedikk 0 = '0-14 days' 1 = '15-28 days' 2 = '29-56 days' 3 = '57- days' ; 
value cntry 1="Sverige"
			2="Norden eller Europa"
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
value stage 1 = "I" 2 = "II" 3 = "III" 4 = "IV" 5 = "Unknown";
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
run; 
/*	************************************************************************	*/
										data imputed_covar; set ny.IMP_50imps_210706;
										run; 
						/* Use single imputation when estimated the adjusted survival curves for plotting*/
						data imp ; set imputed_covar ; 
						if _Imputation_ = 1 ;   /*OBS! */
						run; 	
data X ; set X ; 
keep lopnr 	location 
		Time_Diag_ANY_dik  
		Time_diag_op_dik 
		First_TRT_type ;
run; 
proc sort; by lopnr ; run; 
/*	*******************************************************************************************************************************************	*/
proc sort data = imp; by lopnr ; run; 
proc sort data = Y; by lopnr index; run; 
data XY ; merge Y X imp ; 
by 	lopnr ; 
run; 
/*	_______________________________________________________________________________________________________________________	*/
data XY; set XY ;  
if index = 3 ; 
tid = FUopdate/365.25; 	
format Time_Diag_ANY_dik  Time_diag_op_dik timedik. 
		 sex sex. uicc_final stage.  tstage_path_cat pt.
		A2_lapa lap.;
run; 
proc sort data = XY nodupkey ; 
by lopnr ; 
run; 
/*	___________________________________________________________________________________________________________________________	*/

								/* Condition on these leves when estimating adjusted survival curves	*/
									data inrisk_KOLON; 
									input year_c GRTYP  BMIc diagagec DispInkKE04_c CCI_weighted sex 
									uicc_final pt_cat;
									datalines ; 
									0 1 -0.055 0.32 -0.18 0.01 2 2  4
									0 2 -0.055 0.32 -0.18 0.01 2 2  4
									0 3 -0.055 0.32 -0.18 0.01 2 2  4
									0 4 -0.055 0.32 -0.18 0.01 2 2  4
									0 5 -0.055 0.32 -0.18 0.01 2 2  4
									0 6 -0.055 0.32 -0.18 0.01 2 2  4
									; 
									run; 
									data inrisk_REKTUM; 
									input year_c GRTYP  BMIc diagagec DispInkKE04_c CCI_weighted sex 
									uicc_final pt_cat;
									datalines ; 
									0 1 -0.07 0.01 0.01 0.01 1 3  4
									0 2 -0.07 0.01 0.01 0.01 1 3  4
									0 3 -0.07 0.01 0.01 0.01 1 3  4
									0 4 -0.07 0.01 0.01 0.01 1 3  4
									0 5 -0.07 0.01 0.01 0.01 1 3  4
									0 6 -0.07 0.01 0.01 0.01 1 3  4
									; 
									run; 
/*	_____________________________________________________________________________________	*/
								/* value timediksh 1 = '0-28 days' 2 = '29-56 days'  ;  */ 
								proc format ; 
								value grt 	1 = "0-28, Open" 
											2 = "0-28, Laparoscopic"
											3 = "29-56, Open" 
											4 = "29-56, Laparoscopic"
											5 = "57-, Open" 
											6 = "57-, Laparoscopic" ;
											run; 
data XY ; set XY; 
if Time_Diag_ANY_dik = 0 then Group1 = 1 ; 
if Time_Diag_ANY_dik = 1 then Group1 = 2 ;  
if Time_Diag_ANY_dik = 2 then Group1 = 3 ; 
format Group1  timediksh. ; 
run; 
/* Group : Time to initiation of treatment (regardless of type) */
/*	_____________________________________________________________________________________	*/
																data atr; input tm; 
																cards; 
																2
																4
																6
																8
																10 
																; run; 
																data atrr; set atr; do i = 1 to 6; GRTYP = i; atrr=1; 
																output ; end ; run; 
																proc sort; by GRTYP tm ; run; 
%macro SRV(gr, loc, trt , inrisk , vr,  tp);
data D; set XY; 
Group = &gr; 
if Group  = . then delete ; 
if location = &loc; 
info = &vr. ; 
if Group = 1 & A2_lapa = 0 then GRTYP = 1 ; 
if Group = 1 & A2_lapa = 1 then GRTYP = 2 ; 
if Group = 2 & A2_lapa = 0 then GRTYP = 3 ; 
if Group = 2 & A2_lapa = 1 then GRTYP = 4 ;
if Group = 3 & A2_lapa = 0 then GRTYP = 5 ; 
if Group = 3 & A2_lapa = 1 then GRTYP = 6 ;
format Group timediksh. GRTYP grt. ; 
run; 
data inrisk; set &inrisk. ; 
format GRTYP grt. 
		 sex sex. 
		uicc_final stage. 
		pt_cat pt. ; 
run; 
ods graphics on;
proc phreg data = D plots(overlay cl)=survival ; 
class  	GRTYP	
		sex uicc_final pt_cat ;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
model tid*censored(0) =    sex uicc_final pt_cat
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS
								GRTYP
						/ rl = wald ties = EFRON ;
store sasuser.coxr; 
baseline covariates = inrisk out=pred1 survival=_all_/rowid=GRTYP ; 
ods dataset SurvivalPlot = plotdata ; 
run;
	data plotdata; set plotdata; 
	tid = time ; 
	drop GRTYP ; 
	run; 
		data plotdata_; set plotdata; 
		GRTYP  = _Vector_ ; 
		format GRTYP grt. ;  
		run; 
proc lifetest data=D method = KM atrisk; 
ods dataset ProductLimitEstimates = km ; 
time tid*censored(0); 
strata GRTYP ; 
run; 
data km2; set km; 
where survival ne . ; 
tid = 1*tid; 
tm = tid; 
keep tid NumberAtRisk GRTYP tm ; 
run; 
proc sort; by GRTYP tm ; run; 
data km3; merge km2 atrr; 
by  GRTYP tm ;
nart = lag1(NumberAtRisk); 
if atrr = 1 & NumberAtRisk = . then do ; 
NumberAtRisk = nart;  ; end ; 
tm2 = tm; 
if tm2 in (0, 2, 4, 6, 8, 10) ;
run; 
		data km3; set km3; 
		nart_ = lag1(NumberAtRisk); 
		if NumberAtRisk = . then do ; 
		NumberAtRisk = nart_;  ; end ; 
		run; 
proc sort data = km3 ; 
by GRTYP tid ; run;
proc sort data = plotdata_  ; 
by GRTYP tid ; run;  
data PLD_&tp. ; merge plotdata_ km3; 
by GRTYP tid ; 
if tm ne . then tm = tm2 ; 
run; 
/*proc datasets library=work; delete plotdata plotdata_ km km2 km3 pred1 inrisk ; 
run; quit; */
%mend; 
%SRV(gr=Group1, loc=1, trt= 1, inrisk = inrisk_KOLON, vr= "dsadd",  tp=KOLON_Gr1 )
%SRV(gr=Group1, loc=2, trt= 1, inrisk = inrisk_REKTUM, vr= "dsadd",  tp=REKTUM_Gr1 )
/*______________________________________________________________________________________________________________________________	*/
%macro FG(dt, ttl, ttl2, cut, imagename);
/*ods html image_dpi = 500 ;*/
ods graphics  / imagefmt=tiff 
				imagename= &imagename.
				HEIGHT=(16/1.5)in WIDTH=(24/1.5)in  
				noborder; 
ods listing gpath = "H:\LogOutput" image_dpi=500 ; 
ods graphics  / attrpriority = none  ANTIALIASMAX=4100 ; 
title height=12pt j=l &ttl. ; 
proc sgplot data = &dt noautolegend; 
styleattrs  DATALINEPATTERNS=(  Solid Shortdash Mediumdash Longdash MediumDashShortDash DashDotDot  ) 
			DATACOLORS=(gray red blue green purple black ) 
			DATACONTRASTCOLORS=(gray red blue green purple black ) 
			DATAFILLPATTERNS=(L1 L2 L3 L4 L5 R1)
			axisbreak=slantedright;
step y = survival x=time / group =  GRTYP name='s'  lineattrs=(thickness=2); 
band x=tid lower=LowerSurvival upper=UpperSurvival / group = GRTYP  
			FILLATTRS=( transparency = 0.75)   ; * color = Group;
xaxistable NumberAtRisk / x=tm class = GRTYP colorgroup = GRTYP        /*tid*/
			valueattrs=(weight=bold size=7.5) labelattrs=( size=8)
			NOMISSINGCHAR location=inside;
xaxis label = "Time from surgery (years)" labelattrs=(weight=bold); 
yaxis label= "Survival probability"  labelattrs=(weight=bold) 
		grid values=(.0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1)   
		ranges=(-.01-.05 &cut-1)    /*18*/
			display=(noline noticks);
	keylegend 's' / title= &ttl2. linelength=50 location = inside 
					titleattrs=(Size=8)
					valueattrs=(Size=8)
				position=BOTTOMLEFT across=1;                         /*topright*/
run; quit; 
%mend;
/* Save the plots */
%FG(dt=Pld_kolon_Gr1, ttl="Colon cancer", 
	ttl2="Days from diagnosis to initiation of treatment" , cut = .48 , imagename = "kolonGr_1_LAP_210706")
%FG(dt=Pld_rektum_Gr1, ttl="Rectal cancer", 
	ttl2="Days from diagnosis to initiation of treatment", cut = .48, imagename = "rektumGr_1_LAP_210706")


