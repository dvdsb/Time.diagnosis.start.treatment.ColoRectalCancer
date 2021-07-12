proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data 	*/
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ;
libname ny "H:\Data\Derived\ny210706"; 

proc format ; 
value timedik 0 = '0-28 days' 1 = '29-56 days' 2 = '57- days' ; 
value timediksh 1 = '0-28 days' 2 = '29-56 days'  ; 
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
value type 1="Unadjusted" 
			2="Adjusted complete case"
			3="Adjusted IPW complete case (ATT)" 
			3.5 = "Unadjusted IPW complete case (ATT)"
			4="Adjusted multiple imputations" ; 
run; 

data Y ; set ny.Y210706; 
run;
proc sort; by lopnr ; 
run; 	
data X ; set ny.X210706; 
run;
proc sort data = X; by lopnr ; 
run; 

/* Create design matrix with spline functions and dummy variables for use 
when estimating the propensity score below */
%macro DC(loc, loctxt);
data D; set X; 
if location = &loc; 
run;
proc glmselect data = D outdesign(addinputvars fullmodel)=DsgnMtrx_&loc.; 
class uicc_final lung sex  pt_cat / missing;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
effect sexD = mm(sex);
effect uiccD = mm(uicc_final/ NOEFFECT);
effect pt_catD = mm(pt_cat/ NOEFFECT);
effect lungD = mm(lung/ NOEFFECT);
model location = BMIcS year_cS 
				diagagecS 
				DispInkKE04_cS 
				CCI_weightedS
				sexD
				uiccD
				pt_catD 
				lungD / noint selection=none   ;   
run; 
data DsgnMtrx_&loc.; length info $ 30 ; set DsgnMtrx_&loc.;
info = &loctxt. ; 
run; 
proc datasets library=work; delete D ; 
run; quit; 
%mend; 
%DC(loc = 1, loctxt = "Kolon")
%DC(loc = 2, loctxt = "Rektum")

data DsgnMtrx_ ; merge  DsgnMtrx_1 DsgnMtrx_2;
by info ; 
run; 
proc sort data = DsgnMtrx_ ;
by lopnr ; 
run; 
data XZ ; merge X DsgnMtrx_ ;
by lopnr ; 
if info ne '' ; 
run; 
/* Estimate propensity score and ATE weights	*/
%macro IP( loc,  vr, tp);
data D; set XZ; 
if A2_lapa  = . then delete ; 
if location = &loc; 
	format A2_lapa lap. ; 
run; 
proc psmatch data = D region=allobs(psmin=0.05 psmax=0.95); 
class A2_lapa 	sexD_Male
				uiccD_I uiccD_II uiccD_III uiccD_IV
				pt_catD_T1 pt_catD_T2 pt_catD_T3 pt_catD_T4 pt_catD_TX
				lungD_1 ; 
psmodel A2_lapa(Treated='Laparoscopy') = 		year_cS_1 year_cS_2 year_cS_3
												BMIcS_1 BMIcS_2 BMIcS_3
												diagagecS_1 diagagecS_2 diagagecS_3 
												DispInkKE04_cS_1 DispInkKE04_cS_2 DispInkKE04_cS_3
												CCI_weightedS_1 CCI_weightedS_2 
											sexD_Male
											uiccD_I uiccD_II uiccD_III uiccD_IV 
											pt_catD_T1 pt_catD_T2 pt_catD_T3 pt_catD_T4 pt_catD_TX	
											lungD_1 ;  
assess lps ALLCOV / weight=atewgt plots=none ; 
output out(obs=region)= GRP_pred_&tp.   lps=_lps ps=_ps atewgt=weight_ATE ;  
ods output StdDiff = StdDiff_&tp. ;  
run; 
data StdDiff_&tp. ; length info $ 30 ; set StdDiff_&tp. ;
info = &vr. ; run; 
data GRP_pred_&tp.; length info $ 30 ;  set GRP_pred_&tp.; 
info = &vr. ; run; 
proc datasets library=work; delete D GRP_pred; 
run; quit;
%mend; 
%IP( loc=1,  vr= "KOLON_",  tp=KOLON_ )
%IP( loc=2, vr= "REKTUM_",  tp=REKTUM_ )

data IPW_GR; merge 	 GRP_PRED_KOLON_
					   GRP_PRED_REKTUM_ ;
by info ; run; 
proc sort data = IPW_GR;; 
by 	lopnr ;
run;  

					data StdDiff_; merge StdDiff_KOLON_ StdDiff_REKTUM_;
					by info ; run; 
					/*Standardised mean difference (SMD) (Treated-control)
					Absolute SMD should be <  0.25.
					Variance ratios should be close to 1 and between 0.5 och 2.
					(i.e. variability should be similar), Rubin, 2001*/
					data StdDiff_2; set StdDiff_ ; 
					if abs(StdDiff) > 0.25 then Z1 = 1 ; 
					if VarianceRatio > 2 then Z2 = 1 ; 
					if VarianceRatio < 0.5 then Z3 = 1 ; 
					run; 
					data chk ; set StdDiff_2;
					if OBS = "Weighted" ;
					if Z1 = 1 OR Z2 = 1 OR Z3 = 1; 
					run; 
/*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*	*/
data X ; set X;
keep lopnr A2_lapa A2_konv; 
run; 
proc sort; by lopnr ; 
data XY ; merge Y X IPW_GR ; 
by 	lopnr ; 
if index = 3 ; 
tid = FUopdate/365.25; 
run; 									/* Multiple imputations for the Cox regression */
										data imputed_covar; set ny.IMP_50imps_210706;
										run; 
										proc sort; by lopnr; run; 
										/* Single imputation  for the adjusted survival curve*/
										data imp ; set imputed_covar ; 
										if _Imputation_ = 1 ;   /*OBS! */
										drop A2_lapa ; 
										run; 	
										proc sort; by lopnr ; run; 

							/* Condition on these levels when estimating displaying the adjusted survival curves	*/
								data inrisk_KOLON; 
								input year_c Group  BMIc diagagec DispInkKE04_c CCI_weighted sex 
								uicc_final pt_cat LUNG;
								datalines ; 
								0 0 -0.055 0.32 -0.18 0.01 2 2  4 0
								0 1 -0.055 0.32 -0.18 0.01 2 2  4 0
								; 
								run; 
								data inrisk_REKTUM; 
								input year_c Group  BMIc diagagec DispInkKE04_c CCI_weighted sex 
								uicc_final pt_cat LUNG;
								datalines ; 
								0 0 -0.07 0.01 0.01 0.01 1 3  4 0
								0 1 -0.07 0.01 0.01 0.01 1 3  4 0 
								; 
								run; 

/*	_____________________________________________________________________________________	*/
											data atr; input tm; 
											cards; 
											0
											2
											4
											6
											8
											10 
											; run; 
											data atrr; set atr; do i = 0 to 1; Group = i; atrr=1; 
											output ; end ; run; 
											proc sort; by Group tm ; run; 
/*	_____________________________________________________________________________________	*/
%macro SRV(gr, loc, trt , inrisk , vr,  tp);
data D; set XY; 
if A2_lapa   = . then delete ; 
if location = &loc; 
Group = A2_lapa ; 
info = &vr. ; 
format Group lap. ; 
run; 
data inrisk; set &inrisk. ; 
format Group lap.
		sex sex. 
		uicc_final stage. pt_cat pt.; 
run; 
ods graphics on;
/*ods trace on ; */
proc phreg data = D plots(overlay cl)=survival covs(aggregate); 
class Group (ref = "Open") 		
		sex uicc_final pt_cat LUNG   ;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group              					
							sex uicc_final pt_cat
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
id surgery_hospital ; 
hazardratio Group / diff = ref ; 
store sasuser.coxr; 
baseline covariates = inrisk out=pred1 survival=_all_/rowid=Group ; 
ods dataset SurvivalPlot = plotdata ; 
run;

data plotdata; set plotdata; 
tid = time ; 
drop Group ; 
run; 
data plotdata_; set plotdata; 
Group  = _Vector_ -1; 
format Group lap. ;  
run; 

proc lifetest data=D method = KM atrisk; 
ods dataset ProductLimitEstimates = km ; 
time tid*censored(0); 
strata Group ; 
run; 
data km2; set km; 
where survival ne . ; 
tid = 1*tid; 
tm = tid; 
keep tid NumberAtRisk Group tm ; 
run; 
proc sort; by Group tm ; run; 
data km3; merge km2 atrr; 
by  Group tm ;
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
by Group tid ; run;
proc sort data = plotdata_  ; 
by Group tid ; run;  
data PLD_&tp. ; merge plotdata_ km3; 
by Group tid ; 
if tm ne . then tm = tm2 ; 
run; 
proc datasets library=work; delete plotdata plotdata_ km km2 km3 pred1 inrisk ; 
run; quit; 
%mend; 

%SRV(gr=Group1, loc=1, trt= 1, inrisk = inrisk_KOLON, vr= "dsadd",  tp=KOLON_Gr2 )
%SRV(gr=Group1, loc=2, trt= 1, inrisk = inrisk_REKTUM, vr= "dsadd",  tp=REKTUM_Gr2 )
/*______________________________________________________________________________________________________________________________	*/
/* Make plots */
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
step y = survival x=time / group =  Group name='s'  lineattrs=(thickness=2); 
band x=tid lower=LowerSurvival upper=UpperSurvival / group = Group  
			FILLATTRS=( transparency = 0.7)   ; 
xaxistable NumberAtRisk / x=tm class = Group colorgroup = Group 					
			valueattrs=(weight=bold size=10) labelattrs=(weight=bold size=10)
			NOMISSINGCHAR location=inside;
xaxis label = "Time from surgery (years)" labelattrs=(weight=bold); 
yaxis label= "Survival probability"  labelattrs=(weight=bold) 
		grid values=(.0 .1 .2 .3 .4 .5 .6 .7 .8 .9 1)   
		ranges=(-.01-.05 &cut-1)  
			display=(noline noticks);
	keylegend 's' / title= &ttl2. linelength=50 location = inside 
					titleattrs=(Size=8)
					valueattrs=(Size=8)
				position=BOTTOMLEFT across=1;
run; quit; 
%mend;
/* Save plots */
%FG(dt=Pld_kolon_Gr2, ttl="Colon cancer", 
	ttl2="Technique" , cut = .48, imagename = "kolonLAP_OPEN_210706")
%FG(dt=Pld_rektum_Gr2, ttl="Rectal cancer", 
	ttl2="Technique", cut = .48, imagename = "rektumLAP_OPEN_210706")
/*	*****************************************************************************************	*/
/* Cox regresison to estimate hazard ratios */
	%macro CXs(gr, Outcome_Exposure, loc, vr, tp, IPW);
data D; set XY; 
Group = A2_lapa; 
if Group  = . then delete ; 
if location = &loc; 
format Group lap. ; 
run; 
								data CC; set D; run; 
data D; set D;
keep lopnr Group tid censored info surgery_hospital ; 
run; 
data D; merge D imputed_covar; 
by lopnr; 
if Group  = . then delete ; 
run; 
proc sort data = D ; 
by _imputation_ lopnr ; run; 
/*	____________________________________________________________________	*/
	/* Unadjusted analysis */
ODS EXCLUDE ALL ; 
	proc phreg data = CC covs(aggregate) ; 
	class Group (ref = "Open") ;		
	model tid*censored(0) = Group  / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	id surgery_hospital ;
	store sasuser.coxr; 
	ods output ParameterEstimates = pUA_&tp. ConvergenceStatus = cUA_&tp. ; 
	run;
	data pUA_&tp. ; length  info $50 ; set pUA_&tp. ; 
	info = &vr. ; 
	type = 1 ; 
	format type type. ; 
	if parameter = "Group";
	keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info;
	run; 
/*	______________________________________________________________________________________________	*/
/* Adjusted complete case analysis	*/
proc phreg data = CC covs(aggregate)  ; 
class Group (ref = "Open") 		
		sex uicc_final pt_cat LUNG;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group  
							sex uicc_final pt_cat
							year_cS 
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
		id surgery_hospital ;
	lsmeans Group / cl ; 
	store sasuser.coxr; 
	ods output ParameterEstimates = pACC_&tp. lsmeans=lACC_&tp. ConvergenceStatus = cACC_&tp. ; 
	run;
	data pACC_&tp. ; length  info $50 ; set pACC_&tp. ; 
	info = &vr. ; 
	type = 2 ; 
	format type type. ; 
	if parameter = "Group"; 
	keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info;
	run; 

/*	______________________________________________________________________________________________	*/
/* Adjusted complete case analysis with IPW	*/
	proc phreg data = CC covs(aggregate)  ; 
class Group (ref = "Open") 		
		sex uicc_final pt_cat LUNG;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
model tid*censored(0) = Group              							
							sex uicc_final pt_cat
							year_c
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
								hazardratio Group / diff = ref ; 
									id surgery_hospital ;
								store sasuser.coxr; 
								weight weight_ATE ;
								ods output ParameterEstimates = pATE_&tp. ConvergenceStatus = cATE_&tp. ; 
								run;
								data pATE_&tp. ; length  info $50  ; set pATE_&tp. ;
								info = &vr. ; 
								type = 3 ; 
								format type type. ; 
								if parameter = "Group"; 
								keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info;
								run; 
				/*	______________________________________________________________________________________________	*/
				/* Unadjsuted complete case analysis med IPW	*/
					proc phreg data = CC covs(aggregate)  ; 
					class Group (ref = "Open") ;		
					model tid*censored(0) = Group  / rl = wald ties = EFRON ;
					hazardratio Group / diff = ref ; 
						id surgery_hospital ;
					store sasuser.coxr; 
					weight weight_ATE ;
					ods output ParameterEstimates = pATEUA_&tp. ConvergenceStatus = cATEUA_&tp. ; 
					run;
					data pATEUA_&tp. ; length  info $50 ; set pATEUA_&tp. ; 
					info = &vr. ; 
					type = 3.5 ; 
					format type type. ; 
					if parameter = "Group";
					keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info;
					run; 
			/*	______________________________________________________________________________________________	*/
/* Adjusted analysis with multiple imputations	*/
	proc phreg data = D  covs(aggregate) ; 
	by _imputation_ ;
class Group (ref = "Open") 		
		sex uicc_final pt_cat LUNG;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group              
							sex uicc_final pt_cat
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
		id surgery_hospital ;
	store sasuser.coxr; 
	ods output ParameterEstimates = parms_MI ConvergenceStatus = cMI_&tp. ; 
	run;
		ods select all; 
		proc mianalyze parms(classvar=classval)=parms_MI;
		class Group ; 
		modeleffects Group ; 
		ods output ParameterEstimates = parms_MI2;
		run; 
		data pMI_&tp. ; length  info $50  ; set parms_MI2 ; 
		info = &vr. ; 
		type = 4 ; 
		format type type. ; 
		HazardRatio = exp(estimate) ; HRLowerCL=exp(lclmean); HRUpperCL=exp(uclmean);  
		ProbChiSq = Probt; 
		keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info;
		run; 

data P_&tp. ; 
merge pUA_&tp.  pACC_&tp. pATE_&tp. pATEUA_&tp.  pMI_&tp. ; 
by type ; 
run; 
proc datasets library=work; delete CC D pUA_&tp.  pACC_&tp. pATE_&tp.  pATEUA_&tp.  pMI_&tp. parms_MI parms_MI2 
		cUA_&tp.  cACC_&tp. cATE_&tp.  cATEUA_&tp.  cMI_&tp. ; 
run; quit; 
	%mend; 
	%CXs(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 1, 
		vr= "KOLON_T2Trt_OS",  tp=KOLON_T2Trt_OS, IPW = w_Group1 )
	%CXs(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 2, 
		vr= "REKTUM_T2Trt_OS",  tp=REKTUM_T2Trt_OS, IPW = w_Group1    )

data P_OUT_ ; merge 	p_kolon_t2trt_os 
						p_rektum_t2trt_os ; 
	by info ; 
a = put(HazardRatio, f12.2); 
b = put(HRLowerCL, f12.2); 
c = put(HRUpperCL, f12.2); 
Res = compress(a||'(95%CI:'||b||';'||c||')');
run; 
/* Save output */
data ny.OUT_OS_LAP_OPEN_210706 ; set P_OUT_ ;
run; 
/*__________________________________________________________________________________________*/
/* Sensitivity analysis: Use hospital as frailty to enable shrinkage due to multi-level structure (hospital)*/
%macro CXfrailty(gr, Outcome_Exposure, loc, vr, tp);
data D; set XY; 
Group = A2_lapa; 
if Group  = . then delete ; 
if location = &loc; 
format Group lap. ; 
run; 
								data CC; set D; run; 
data D; set D;
keep lopnr Group tid censored info surgery_hospital ; 
run; 
data D; merge D imputed_covar; 
by lopnr; 
if Group  = . then delete ; 
run; 
proc sort data = D ; 
by _imputation_ lopnr ; run; 
/* Adjusted analysis with  multiple imputations	*/
	proc phreg data = D   ; 
	by _imputation_ ;
class Group (ref = "Open") 		
		sex uicc_final pt_cat LUNG surgery_hospital;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group              
							sex uicc_final pt_cat
							year_cS 
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
		random surgery_hospital ;
	store sasuser.coxr; 
	ods output ParameterEstimates = parms_MI ConvergenceStatus = cMI_&tp. ; 
	run;
				ods select all; 
				proc mianalyze parms(classvar=classval)=parms_MI;
				class Group ; 
				modeleffects Group ; 
				ods output ParameterEstimates = parms_MI2;
				run; 
				data pMI_&tp. ; length  info $50  ; set parms_MI2 ; 
				info = &vr. ; 
				type = 4 ; 
				format type type. ; 
				HazardRatio = exp(estimate) ; HRLowerCL=exp(lclmean); HRUpperCL=exp(uclmean);  
				ProbChiSq = Probt; 
				keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info  Group;
				run; 
			%mend; 
			%CXfrailty(gr=Group1, Outcome_Exposure = "OS T2Trt_F", loc = 1, 
				vr= "KOLON_T2Trt_OS_F",  tp=KOLON_T2Trt_OS_F )
			%CXfrailty(gr=Group1, Outcome_Exposure = "OS T2Trt_F", loc = 2, 
				vr= "REKTUM_T2Trt_OS_F",  tp=REKTUM_T2Trt_OS_F   )

			data P_OUT_FRAILTY ; merge 	pmi_kolon_t2trt_os_f 
								pmi_rektum_t2trt_os_f ; 
			by info ; 
		a = put(HazardRatio, f12.2); 
		b = put(HRLowerCL, f12.2); 
		c = put(HRUpperCL, f12.2); 
		Res = compress(a||'(95%CI:'||b||';'||c||')');
		run; 
/* Save data	*/
data ny.OUT_OS_LAP_OPEN_FRAILTY_2100706; set P_OUT_FRAILTY ;
run; 

/* Additional analysis: Adjust for time until surgery	*/
%macro CXsTIME(gr, Outcome_Exposure, loc, vr, tp, IPW);
data D; set XY; 
Group = A2_lapa; 
if Group  = . then delete ; 
if location = &loc; 
format Group lap. ; 
run; 
data D; set D;
keep lopnr Group tid censored info surgery_hospital ; 
run; 
data D; merge D imputed_covar; 
by lopnr; 
if Group  = . then delete ; 
run; 
proc sort data = D ; 
by _imputation_ lopnr ; run; 
/* Adjusted analysis with  multiple imputations	*/
	proc phreg data = D  covs(aggregate) ; 
	by _imputation_ ;
class Group (ref = "Open") 		
		sex uicc_final pt_cat LUNG;
effect Time_Diag_OP_cS = spline(Time_Diag_OP_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group              
							sex uicc_final pt_cat
							Time_Diag_OP_cS 
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS LUNG / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
		id surgery_hospital ;
	store sasuser.coxr; 
	ods output ParameterEstimates = parms_MI ConvergenceStatus = cMI_&tp. ; 
	run;
		ods select all; 
		proc mianalyze parms(classvar=classval)=parms_MI;
		class Group ; 
		modeleffects Group ; 
		ods output ParameterEstimates = parms_MI2;
		run; 
		data pMI_&tp. ; length  info $50  ; set parms_MI2 ; 
		info = &vr. ; 
		type = 4 ; 
		format type type. ; 
		HazardRatio = exp(estimate) ; HRLowerCL=exp(lclmean); HRUpperCL=exp(uclmean);  
		ProbChiSq = Probt; 
		keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info;
		run; 

data P_&tp. ; set  pMI_&tp. ; 
by type ; 
run; 
proc datasets library=work; delete CC D   pMI_&tp. parms_MI parms_MI2 
		 cMI_&tp. ; 
run; quit; 
	%mend; 
	%CXsTIME(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 1, 
		vr= "KOLON_T2Trt_OS",  tp=KOLON_T2Trt_OS, IPW = w_Group1 )
	%CXsTIME(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 2, 
		vr= "REKTUM_T2Trt_OS",  tp=REKTUM_T2Trt_OS, IPW = w_Group1    )

data P_OUT_ ; merge 	p_kolon_t2trt_os 
						p_rektum_t2trt_os ; 
	by info ; 
a = put(HazardRatio, f12.2); 
b = put(HRLowerCL, f12.2); 
c = put(HRUpperCL, f12.2); 
Res = compress(a||'(95%CI:'||b||';'||c||')');
run; 
/* Save data	*/
data ny.OUT_OS_LAP_OPEN_Sens_210706;  set P_OUT_ ;
run; 
