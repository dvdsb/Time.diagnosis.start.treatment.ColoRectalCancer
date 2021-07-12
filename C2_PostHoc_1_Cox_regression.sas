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
1 = "1-90 days after index admission" 2 = ">90 days after index admission" 3 = 'Before/during or anytime after'; 
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
value type 1="Unadjusted" 
			2="Adjusted complete case"
			3="Adjusted IPW complete case (ATT)" 
			3.5 = "Unadjusted IPW complete case (ATT)"
			4="Adjusted multiple imputations" ; 
value lap 0 = 'Open' 1 = "Laparoscopy"; 
run; 

data XY ; merge X Y  ; 
by lopnr ; run;
								/* Multiple imputations data	*/
									data imputed_covar; set ny.IMP_50imps_210706;
									run; 
									proc sort data = imputed_covar; 
									by lopnr _imputation_ ; run; 
data XY ; set XY ; 
if Time_Diag_ANY_dik = 0 then Group1 = 1 ; 
if Time_Diag_ANY_dik = 1 then Group1 = 2 ;  
if Time_Diag_ANY_dik = 2 then Group1 = 3 ; 
format Group1  timediksh. ; 
run; 
/* Overall survival */
data XY2 ; set XY ; 
if index = 3 ; 
tid = FUopdate/365.25; 
run; 
/* Cox regression 	*/
%macro CXs(gr, Outcome_Exposure, loc, vr, tp, IPW);
data D; set XY2; 
Group = &gr; 
if Group  = . then delete ; 
if location = &loc; 
format Group timediksh. A2_lapa lap.; 
run; 
								data CC; set D; run; 
data D; set D;
keep lopnr Group A2_lapa tid censored info  ; 
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
	proc phreg data = CC  ; 
	class Group (ref = "0-28 days") A2_lapa(ref = "Open");		
	model tid*censored(0) = Group A2_lapa Group*A2_lapa / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	strata A2_lapa ;
	ods output ParameterEstimates = pUA_&tp. HazardRatios = hrUA_&tp.; 
	run;
	data pUA_&tp. ; length  info $50 ; set pUA_&tp. ; 
	info = &vr. ; 
	type = 1 ; 
	format type type. ; 
	if parameter = "Group*A2_lapa";
	Pvalue_Interaction = ProbChiSq ; 
	keep  Pvalue_Interaction  type info;
	run; 
	data hrUA_&tp. ; length  info $50 ; set hrUA_&tp. ; 
	info = &vr. ; 
	type = 1 ; 
	format type type. ; 
	run; 
	data pUA_&tp.; merge hrUA_&tp. pUA_&tp. ;
	by info type ; run; 
/*	______________________________________________________________________________________________	*/
/* Adjusted complete case analysis	*/
proc phreg data = CC  ; 
class Group (ref = "0-28 days") A2_lapa(ref = "Open")		
		sex uicc_final pt_cat;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group A2_lapa Group*A2_lapa  
							sex uicc_final pt_cat
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	lsmeans Group / cl ; 
	strata A2_lapa ;
	store sasuser.coxr; 
	ods output ParameterEstimates = pACC_&tp. lsmeans=lACC_&tp. 
				HazardRatios = hrACC_&tp. ConvergenceStatus = cACC_&tp. ; 
	run;
	data pACC_&tp. ; length  info $50 ; set pACC_&tp. ; 
	info = &vr. ; 
	type = 2 ; 
	format type type. ; 
	if parameter = "Group*A2_lapa";
	Pvalue_Interaction = ProbChiSq ; 
	keep  Pvalue_Interaction  type info;
	run; 
	data hrACC_&tp. ; length  info $50 ; set hrACC_&tp. ; 
	info = &vr. ; 
	type = 2 ; 
	format type type. ; 
	run; 
	data pACC_&tp.; merge hrACC_&tp. pACC_&tp. ;
	by info type ; run; 

/* Adjusted analysis med multiple imputations	*/
	proc phreg data = D  ; 
	by _imputation_ ;
class Group (ref = "0-28 days")  A2_lapa(ref = "Open")		
		sex uicc_final pt_cat;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group  A2_lapa   Group*A2_lapa            
							sex uicc_final pt_cat
							year_cS
							BMIcS
							diagagecS
							DispInkKE04_cS
							CCI_weightedS / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	store sasuser.coxr; 
	strata A2_lapa ;
	ods output ParameterEstimates = parms_MI ConvergenceStatus = cMI_&tp. HazardRatios = hr_MI; 
	run;
			data hr_MI ; set hr_MI; 
			if description = "Group 29-56 days vs 0-28 days At A2_lapa=Laparoscopy" then ClassVal0 = "L1"; 
			if description = "Group 29-56 days vs 0-28 days At A2_lapa=Open" then ClassVal0 = "O1"; 
			if description = "Group 57- days vs 0-28 days At A2_lapa=Laparoscopy" then ClassVal0 = "L2"; 
			if description = "Group 57- days vs 0-28 days At A2_lapa=Open" then ClassVal0 = "O2"; 
			ClassVal1 = "X" ; 
			parameter = "X"; 
			Estimate = log(HazardRatio); 
			StdErr = (log(WaldUpper/WaldLower))/3.92;
			run; 
			ods select all; 
				proc mianalyze parms(classvar=classval)=hr_MI;
				class X ; 
				modeleffects X ; 
				ods output ParameterEstimates = hr_MI2;
				run; 
			data hr_MI2; length  info $50  ; set hr_MI2 ; 
			info = &vr. ; type = 4 ; format type type. ; 
			HazardRatio = exp(estimate) ; WaldLower=exp(lclmean); WaldUpper=exp(uclmean);  
			ProbChiSq = Probt; 
			keep  ProbChiSq HazardRatio HazardRatio WaldLower WaldUpper X type info;
			run;
									data parms_MI ; set parms_MI ;
									if parameter = "Group*A2_lapa"; 
												ClassVal0 = 1 ; 
									ClassVal1 = "X" ; 
									parameter = "X"; 
									run; 
									proc mianalyze parms(classvar=classval)=parms_MI;
									class X ; 
									modeleffects X ; 
									ods output ParameterEstimates = parms_MI2;
									run;	
									data parms_MI2	; length  info $50 ; set parms_MI2	;
										info = &vr. ; type = 4 ; 	format type type. ; 
										Pvalue_Interaction = Probt ; 
									keep    type info Pvalue_Interaction;
									run;
									data pMI_&tp.; merge hr_MI2  parms_MI2;
									by info type ; 
									keep info type X Pvalue_Interaction HazardRatio WaldLower WaldUpper ; 
									run; 

data P_&tp. ; 
merge pUA_&tp.  pACC_&tp.   pMI_&tp. ; 
by type ; 
if X = "L1" then Description = "Group 29-56 days vs 0-28 days At A2_lapa=Laparoscopy" ; 
if X = "O1" then Description = "Group 29-56 days vs 0-28 days At A2_lapa=Open" ; 
if X = "L2" then Description = "Group 57- days vs 0-28 days At A2_lapa=Laparoscopy" ; 
if X = "O2" then Description = "Group 57- days vs 0-28 days At A2_lapa=Open" ; 
run; 
proc datasets library=work; delete CC D pUA_&tp.  pACC_&tp. pATT_&tp.  
									pATTUA_&tp.  pMI_&tp. parms_MI parms_MI2  ; 
run; quit; 
	%mend; 
/* Group1 : Time to treatment */
	%CXs(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 1, 
		vr= "KOLON_T2Trt_OS",  tp=KOLON_T2Trt_OS , IPW = w_Group1 )
	%CXs(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 2, 
		vr= "REKTUM_T2Trt_OS",  tp=REKTUM_T2Trt_OS , IPW = w_Group1)
/*	____________________________________________________________________________________________	*/

data P_OUT_1 ; merge 
						p_kolon_t2trt_os 
						p_rektum_t2trt_os  ; 
	by info ; 
a = put(HazardRatio, f12.2); 
b = put(WaldLower, f12.2); 
c = put(WaldUpper, f12.2); 
Res = compress(a||'(95%CI:'||b||';'||c||')');
run; 
/* Save output */
data ny.OUT_OS_LAP_Smspl_210626; set P_OUT_1 ;
run; 

data DS ; set XY; 
if index = 3 ; 
if Group1  = . then delete ; 
if A2_lapa = . then delete ;
keep location index group1 A2_lapa lopnr censored ; 
run; 
proc sort; by location index group1 A2_lapa lopnr; 
run; 
proc freq data = DS noprint; 
by location index group1 A2_lapa;
table censored  / out = freq; 
run; 
proc transpose data = freq out = freq2; 
by location index group1 A2_lapa;
var COUNT ; 
id censored ; 
run; 
data freq2; set freq2; 
if _1 ne . ; 
N = _0 + _1 ; 
P=100*(_1/(_0 + _1));  
c = put(P, f11.1); 
Res = compress(_1||'/'||N||'('||c||'%)');
run; 
/* Save raw frequencies	*/
data ny.OUT_freq_OS_TRT_LAP_Smspl_210706; set freq2 ;
run;
