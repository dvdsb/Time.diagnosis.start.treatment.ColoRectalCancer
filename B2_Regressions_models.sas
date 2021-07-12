proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data 	*/
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
value timediksh 1 = '0-28 days' 2 = '29-56 days'  3 = '57- days'; 
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
			4="Adjusted multiple imputations" ; 
run; 

data XY ; merge X Y ; 
by lopnr ; run;
									/* Multiple imputations data set	*/
									data imputed_covar; set ny.IMP_50imps_210706;
									run; 
									proc sort data = imputed_covar; 
									by lopnr _imputation_ ; run; 

/*	____________________________________________________________________________________________________________	*/
data XY ; set XY ; 
if Time_Diag_ANY_dik = 0 then Group1 = 1 ; 
if Time_Diag_ANY_dik = 1 then Group1 = 2 ;  
if Time_Diag_ANY_dik = 2 then Group1 = 3 ; 
format Group1  timediksh. ; 
drop Time_Diag_ANY_dik Time_Diag_OP_dik  ;
run; 														/* Offset for secondary endpoints	*/
																data offset ; set Y ; 
																if index = 3 ; 
																if FUopdate < 90 then offset = log(FUopdate); 
																if FUopdate => 90 then offset = log(90); 
																keep lopnr FUopdate offset ; 
																run; 
																proc sort data = offset; by lopnr ; run; 		
data XY ; merge  XY offset;
by lopnr ; 
run;  
/* Overall survival */
data XY2 ; set XY ; 
if index = 3 ; 
tid = FUopdate/365.25; 
run; 
/* Macro for Cox regression */
%macro CXs(gr, Outcome_Exposure, loc, vr, tp);
data D; set XY2; 
Group = &gr; 
if Group  = . then delete ; 
if location = &loc; 
format Group timediksh. ; 
run; 
								data CC; set D; run; 
data D; set D;
keep lopnr Group tid censored info  ; 
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
	class Group (ref = "0-28 days") ;		
	model tid*censored(0) = Group  / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	store sasuser.coxr; 
	ods output ParameterEstimates = pUA_&tp. ConvergenceStatus = cUA_&tp. Nobs=NobsUA_&tp.; 
	run;
	data pUA_&tp. ; length  info $50 ; set pUA_&tp. ; 
	info = &vr. ; 
	type = 1 ; 
	format type type. ; 
	if parameter = "Group";
	Group = ClassVal0 ; 
	keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info Group ;
	run; 
/*	______________________________________________________________________________________________	*/
/*Adjusted complete case analysis	*/
proc phreg data = CC  ; 
class Group (ref = "0-28 days") 		
		sex uicc_final pt_cat;
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
							CCI_weightedS / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	lsmeans Group / cl ; 
	store sasuser.coxr; 
	ods output ParameterEstimates = pACC_&tp. lsmeans=lACC_&tp. ConvergenceStatus = cACC_&tp. Nobs=NobsACC_&tp.; 
	run;
	data pACC_&tp. ; length  info $50 ; set pACC_&tp. ; 
	info = &vr. ; 
	type = 2 ; 
	format type type. ; 
	if parameter = "Group"; 
	Group = ClassVal0 ; 
	keep  ProbChiSq HazardRatio HRLowerCL HRUpperCL  type info   Group;
	run; 
			/*	______________________________________________________________________________________________	*/
/* Adjusted analysis with multiple imputations	*/
	proc phreg data = D  ; 
	by _imputation_ ;
class Group (ref = "0-28 days") 		
		sex uicc_final pt_cat;
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
							CCI_weightedS / rl = wald ties = EFRON ;
	hazardratio Group / diff = ref ; 
	store sasuser.coxr; 
	ods output ParameterEstimates = parms_MI ConvergenceStatus = cMI_&tp. Nobs=NobsMI_&tp.; 
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

data P_&tp. ; 
merge pUA_&tp.  pACC_&tp.  pMI_&tp. ; 
by type ; 
run; 
proc datasets library=work; delete CC D pUA_&tp.  pACC_&tp.  pMI_&tp. parms_MI parms_MI2 
		cUA_&tp.  cACC_&tp.   cMI_&tp.  NobsUA_&tp. NobsACC_&tp. NobsMI_&tp.; 
run; quit; 
	%mend; 
	%CXs(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 1, 
		vr= "KOLON_T2Trt_OS",  tp=KOLON_T2Trt_OS )
	%CXs(gr=Group1, Outcome_Exposure = "OS T2Trt", loc = 2, 
		vr= "REKTUM_T2Trt_OS",  tp=REKTUM_T2Trt_OS   )
/*	____________________________________________________________________________________________	*/
/* Readmissions and reoperation by zero inflation poisson model */
data  XY3 ; set  XY ;  
if index = 1 ; 
run; 
/*	____________________________________________________________________	*/
%macro CX(gr, OUTCOME, Outcome_Exposure, loc, vr,  tp);
data D; set XY3; 
Group = &gr; 
Y = &OUTCOME;
if Group  = . then delete ; 
if location = &loc; 
format Group timediksh. ; 
run; 
								data CC; set D; run; 
data D; set D;
keep lopnr Group Y  offset; 
run; 
proc sort data = D ; by lopnr ; run; 
data D2; merge D imputed_covar; 
by lopnr; 
if Group  = . then delete ; 
run; 
proc sort data = D2 ; 
by _imputation_  lopnr ; run; 
	/* Unadjusted analysis */	
proc genmod data = CC ; 
class  Group(ref='0-28 days') ; 
model  Y = Group / dist = zip  offset=offset; 
zeromodel ;
lsmeans Group / cl ; 
output out = zip predicted=pred pzero=pzero; 
ods output modelfit = fit2 ParameterEstimates = pUA_&tp. LSMeans = lUA_&tp.  ConvergenceStatus = cUA_&tp. 
Nobs = NobsUA_&tp.  ;  
run; 
data pUA_&tp.  ; length   info $50 ; set pUA_&tp.  ; 
	info = &vr. ;  type = 1 ; 
	format type type. ; 
	if df = 1 ; 
	if parameter = "Group"; 
	Group = Level1 ; 
	keep info type estimate LowerWaldCL UpperWaldCL ProbChiSq Group; 
	run; 
data lUA_&tp. ; length   info $50 ; set lUA_&tp. ; 
	info = &vr. ; type = 1 ; 
	format type type. ;  
	run; 											
/*	______________________________________________________________________________________________	*/
/* Adjusted complete case analysis	*/
			proc glmselect data = CC outdesign(addinputvars fullmodel)=CC_; 
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
				model Y = BMIcS year_cS
								diagagecS DispInkKE04_cS CCI_weightedS /noint selection=none ;  
				run; 

				proc genmod data = CC_ ; 
				class  Group(ref='0-28 days') 		
						sex uicc_final pt_cat; 
				model  Y = Group 	year_cS_1 year_cS_2 year_cS_3
									BMIcS_1 BMIcS_2 BMIcS_3 
									diagagecS_1 diagagecS_2 diagagecS_3
										DispInkKE04_cS_1 DispInkKE04_cS_2 DispInkKE04_cS_3
										CCI_weightedS_1 CCI_weightedS_2
									sex uicc_final pt_cat / dist = zip  offset=offset; 
				zeromodel ;
				lsmeans Group / cl ; 
				output out = zip predicted=pred pzero=pzero; 
				ods output modelfit = fit2 ParameterEstimates = pACC_&tp. ConvergenceStatus = cACC_&tp.  
										Nobs = NobsACC_&tp.  ;  
				run; 
				data pACC_&tp.  ; length   info $50 ; set pACC_&tp.  ; 
					info = &vr. ;  type = 2 ; 
					format type type. ; 
					if df = 1 ; 
					if parameter = "Group";  
					Group = Level1 ; 
					keep info type estimate LowerWaldCL UpperWaldCL ProbChiSq Group ; 
				run; 
/*	______________________________________________________________________________________________	*/
/* Adjusted analysis med multiple imputations	*/
			proc glmselect data = D2 outdesign(addinputvars fullmodel)=D_; 
			by _imputation_   ;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
				model Y = BMIcS year_cS
								diagagecS DispInkKE04_cS CCI_weightedS /noint selection=none ;  	 
				run; 
				proc genmod data = D_ ; 
				by _imputation_   ;
				class  Group(ref='0-28 days') 		
						sex uicc_final pt_cat ; 
				model  Y = Group 
									_X1 _X2 _X3 
									_X4 _X5 _X6  
									_X7 _X8 _X9 
									_X10 _X11 _X12  
									_X13 _X14 
									sex uicc_final pt_cat / dist = zip  offset=offset covb; 
				zeromodel ;
				lsmeans Group / cl ; 
				output out = zip predicted=pred pzero=pzero; 
				ods output modelfit = fit2 ParameterEstimates = parms_MI 
              				ParmInfo=gmpinfo_MI
              				CovB=gmcovb_MI   ConvergenceStatus = cMI_&tp. 
										Nobs = NobsMI_&tp. ;  
				run; 
				data parms_MI ; set parms_MI; 
				if df = 1 & Parameter = "Group"; 
				run; 
					data gmpinfo_MI ; set gmpinfo_MI; 
					if Parameter in ("Prm2", "Prm3"); 
					run; 
						data gmcovb_MI ; set gmcovb_MI; 
						if rowname in ("Prm2", "Prm3"); 
						run; 
				proc sort data = parms_MI ; 
				by  _imputation_ ; run; 
				proc sort data = ParmInfo ; 
				by  _imputation_ ; run; 
				proc sort data = gmcovb_MI ; 
				by  _imputation_ ; run; 

		ods select all; 
		proc mianalyze parms(classvar=level) = parms_MI covb=gmcovb_MI parminfo=gmpinfo_MI;
		class Group ; 
		modeleffects Group ; 
		ods output ParameterEstimates = parms_MI2;
		run; 
		data pMI_&tp. ; length  info $50  ; set parms_MI2 ; 
		info = &vr. ; 
		type = 4 ; 
		format type type. ; 
		LowerWaldCL = LCLMean ; UpperWaldCL = UCLMean; ProbChiSq = Probt ; 
		keep info type estimate LowerWaldCL UpperWaldCL ProbChiSq Group;
		run;  
data P_&tp. ; length Outcome_Exposure $30  ; 
merge pUA_&tp.  pACC_&tp.  pMI_&tp. ; 
by type ; 
Outcome_Exposure = &Outcome_Exposure. ; 
run; 
proc datasets library=work; delete CC D parms_MI2 gmcovb_MI parms_MI gmpinfo_MI
	pUA_&tp.  pACC_&tp.   pMI_&tp. 
	cUA_&tp.  cACC_&tp.   cMI_&tp. 
	 NobsUA_&tp. NobsACC_&tp. NobsMI_&tp. ; 
run; quit;    
	%mend; 
	
%CX(gr=Group1, OUTCOME=additional_readmissions, Outcome_Exposure = "Readm T2trt", loc=1,  
		vr= "KOLON_T2trt_Readm",  tp=KOLON_T2trt_Readm )   
%CX(gr=Group1, OUTCOME=additional_surgery, Outcome_Exposure = "Reop T2trt", loc = 1, 
		vr= "KOLON_T2trt_Reop",  tp=KOLON_T2trt_Reop )
%CX(gr=Group1, OUTCOME=additional_readmissions, Outcome_Exposure = "Readm T2trt", loc=2,  
		vr= "REKTUM_T2trt_Readm",  tp=REKTUM_T2trt_Readm )
%CX(gr=Group1, OUTCOME=additional_surgery, Outcome_Exposure = "Reop T2trt", loc = 2, 
		vr= "REKTUM_T2trt_Reop",  tp=REKTUM_T2trt_Reop)			
/*	____________________________________________________________________________________________	*/
	/* Length of stay during index admission */
data  XY4 ; set  XY ;  
if index = 0; 
run; 
%macro CXX(gr, Outcome_Exposure, loc, vr,  tp, IPW);
data D; set XY4; 
Group = &gr; 
if Group  = . then delete ; 
if location = &loc; 
format Group timediksh. ; 
run; 
								data CC; set D; run; 
data D; set D;
keep lopnr Group LoS_index  offset; 
run; 
proc sort data = D ; by lopnr ; run; 
data D2; merge D imputed_covar; 
by lopnr; 
if Group  = . then delete ; 
run; 
proc sort data = D2 ; 
by _imputation_  lopnr ; run; 
/*	____________________________________________________________________	*/
	/* Unadjusted analysis */	
proc genmod data = CC ; 
class  Group(ref='0-28 days') ; 
model  LoS_index = Group / dist = nb; 
lsmeans Group / cl ; 
ods output modelfit = fit2 ParameterEstimates = pUA_&tp. LSMeans = lUA_&tp.  ConvergenceStatus = cUA_&tp. 
			Nobs = NobsUA_&tp. ;  
run; 
data pUA_&tp.  ; length   info $50 ; set pUA_&tp.  ; 
	info = &vr. ;  type = 1 ; 
	format type type. ; 
	if df = 1 ; 
	if parameter = "Group"; 
	Group = Level1 ; 
	keep info type estimate LowerWaldCL UpperWaldCL ProbChiSq Group; 
	run; 
data lUA_&tp. ; length   info $50 ; set lUA_&tp. ; 
	info = &vr. ; type = 1 ; 
	format type type. ;  
	run; 
/*	______________________________________________________________________________________________	*/
/* Adjusted complete case analysis	*/
			proc glmselect data = CC outdesign(addinputvars fullmodel)=CC_; 
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
				model LoS_index = BMIcS year_cS
								diagagecS DispInkKE04_cS CCI_weightedS /noint selection=none ;  	
				run; 

				proc genmod data = CC_ ; 
				class  Group(ref='0-28 days') 		
						sex uicc_final pt_cat; 
				model  LoS_index = Group 
									year_cS_1 year_cS_2 year_cS_3
									BMIcS_1 BMIcS_2 BMIcS_3 
									diagagecS_1 diagagecS_2 diagagecS_3
										DispInkKE04_cS_1 DispInkKE04_cS_2 DispInkKE04_cS_3
										CCI_weightedS_1 CCI_weightedS_2
									sex uicc_final pt_cat / dist = nb ;
				lsmeans Group / cl ; 
				ods output modelfit = fit2 ParameterEstimates = pACC_&tp.  ConvergenceStatus = cACC_&tp.  
							Nobs = NobsACC_&tp. ;  
				run; 
				data pACC_&tp.  ; length   info $50 ; set pACC_&tp.  ; 
					info = &vr. ;  type = 2 ; 
					format type type. ; 
					if df = 1 ; 
					if parameter = "Group";  
					Group = Level1 ; 
					keep info type estimate LowerWaldCL UpperWaldCL ProbChiSq Group; 
				run; 					
/*	______________________________________________________________________________________________	*/
/* djusted analysis with multiple imputations	*/
			proc glmselect data = D2 outdesign(addinputvars fullmodel)=D_; 
			by _imputation_   ;
effect year_cS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));
				model LoS_index = BMIcS year_cS
								diagagecS DispInkKE04_cS CCI_weightedS /noint selection=none ;  	 
				run; 
				proc genmod data = D_ ; 
				by _imputation_   ;
				class  Group(ref='0-28 days') 		
						sex uicc_final pt_cat ; 
				model  LoS_index = Group 
									_X1 _X2 _X3 
									_X4 _X5 _X6  
									_X7 _X8 _X9 
									_X10 _X11 _X12  
									_X13 _X14 
									sex uicc_final pt_cat / dist = nb covb; 
				lsmeans Group / cl ; 
				ods output modelfit = fit2 ParameterEstimates = parms_MI 
              				ParmInfo=gmpinfo_MI
              				CovB=gmcovb_MI
							  ConvergenceStatus = cMI_&tp. 
								Nobs = NobsMI_&tp. ;  
				run; 
				data parms_MI ; set parms_MI; 
				if df = 1 & Parameter = "Group"; 
				run; 
					data gmpinfo_MI ; set gmpinfo_MI; 
					if Parameter in ("Prm2", "Prm3"); 
					run; 
						data gmcovb_MI ; set gmcovb_MI; 
						if rowname in ("Prm2", "Prm3"); 
						run; 
				proc sort data = parms_MI ; 
				by  _imputation_ ; run; 
				proc sort data = ParmInfo ; 
				by  _imputation_ ; run; 
				proc sort data = gmcovb_MI ; 
				by  _imputation_ ; run; 

		ods select all; 
		proc mianalyze parms(classvar=level) = parms_MI covb=gmcovb_MI parminfo=gmpinfo_MI;
		class Group ; 
		modeleffects Group ; 
		ods output ParameterEstimates = parms_MI2;
		run; 
		data pMI_&tp. ; length  info $50  ; set parms_MI2 ; 
		info = &vr. ; 
		type = 4 ; 
		format type type. ; 
		LowerWaldCL = LCLMean ; UpperWaldCL = UCLMean; ProbChiSq = Probt ; 
		keep info type estimate LowerWaldCL UpperWaldCL ProbChiSq Group;
		run;  
data P_&tp. ; length Outcome_Exposure $30  ; 
merge pUA_&tp.  pACC_&tp.    pMI_&tp. ; 
by type ; 
Outcome_Exposure = &Outcome_Exposure. ; 
run; 

proc datasets library=work; delete CC D parms_MI2 gmcovb_MI parms_MI gmpinfo_MI
	pUA_&tp.  pACC_&tp.   pMI_&tp.   
		cUA_&tp.  cACC_&tp.  cMI_&tp. 
NobsUA_&tp. NobsACC_&tp. NobsMI_&tp. ; 
run; quit;    

	%mend; 

%CXX(gr=Group1, Outcome_Exposure = "LoS T2Trt", loc=1,  
		vr= "KOLON_T2Trt_LoS",  tp=KOLON_T2Trt_LoS, IPW = w_group1 )
%CXX(gr=Group1, Outcome_Exposure = "LoS T2Trt", loc = 2, 
		vr= "REKTUM_T2Trt_LoS",  tp=REKTUM_T2Trt_LoS, IPW = w_group1 )

data P_OUT_1 ; merge 	
							p_kolon_t2trt_readm 
							p_rektum_t2trt_readm 
							p_kolon_t2trt_reop 
							p_rektum_t2trt_reop 
							p_kolon_t2trt_los
							p_rektum_t2trt_los
; 
	by info ; 
a = put(exp(Estimate), f12.2); 
b = put(exp(LowerWaldCL), f12.2); 
c = put(exp(UpperWaldCL), f12.2); 
Res = compress(a||'(95%CI:'||b||';'||c||')');
run; 

/* Save output secondary endpoints 	*/
data ny.OUT_nonOS_210706; set P_OUT_1 ;
run; 

data P_OUT_2 ; merge 	p_kolon_t2trt_os 
						p_rektum_t2trt_os ; 
	by info ; 
a = put(HazardRatio, f12.2); 
b = put(HRLowerCL, f12.2); 
c = put(HRUpperCL, f12.2); 
Res = compress(a||'(95%CI:'||b||';'||c||')');
run; 
/* Save output primary endpoint 	*/
data ny.OUT_OS_210706; set P_OUT_2 ;
run; 

data LOS; merge 	Lua_kolon_t2trt_los
						Lua_rektum_t2trt_los ;
	by info ; 
a = put(exp(Estimate), f12.2); 
b = put(exp(Lower), f12.2); 
c = put(exp(Upper), f12.2); 
Res = compress(a||'(95%CI:'||b||';'||c||')');
run; 
/* Raw means */
data ny.OUT_lsm_LOS_210706; set LOS ;
run;
/*_____________________________________________________________________________________________*/
data DS ; set XY; 
if index in (1, 3) ; 
if  additional_surgery = 0 then reop_dik = 0 ; 
if  additional_surgery > 0 then reop_dik = 1 ; 
if  additional_readmissions = 0 then readm_dik = 0 ; 
if  additional_readmissions  > 0 then readm_dik = 1 ; 
if Group1  = . then delete ; 
run; 
proc sort; by location index group1 lopnr; 
run; 
proc transpose data = DS out = DS2; 
by location index group1 lopnr;
var reop_dik readm_dik censored; 
run; 
proc sort data = DS2 ; by _NAME_ location index group1 lopnr;
run; 
proc freq data = DS2 noprint; 
by _NAME_ location index group1 ;
table col1  / out = freq; 
run; 
proc transpose data = freq out = freq2; 
by _NAME_ location index group1 ;
var COUNT ; 
id col1 ; 
run; 
data freq2; set freq2; 
if _1 ne . ; 
N = _0 + _1 ; 
P=100*(_1/(_0 + _1));  
c = put(P, f11.1); 
Res = compress(_1||'/'||N||'('||c||'%)');
run; 
/* Raw freqencies  */
data ny.OUT_freq_GR1_210706; set freq2 ;
run;

/*__________________________________________________________________________________________*/
/* Sensitivity analysis: Use hospital as frailty to enable shrinkage due to multi-level structure (hospital)*/
%macro CXfrailty(gr, Outcome_Exposure, loc, vr, tp);
data D; set XY2; 
Group = &gr; 
if Group  = . then delete ; 
if location = &loc; 
format Group timediksh. ; 
keep lopnr Group tid censored info surgery_hospital ; 
run; 
data D; merge D imputed_covar; 
by lopnr; run; 
if Group  = . then delete ; 
run; 
proc sort data = D ; 
by _imputation_ lopnr ; run; 

	proc phreg data = D  ; 
	by _imputation_ ;
class Group (ref = "0-28 days") 		
		sex uicc_final pt_cat
			surgery_hospital   ;
effect year_cS = spline(year_c / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect BMIcS = spline(BMIc / basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect diagagecS = spline( diagagec/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect DispInkKE04_cS = spline( DispInkKE04_c/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(5 35 65 95)) ;
effect CCI_weightedS = spline( CCI_weighted/ basis=tpf(noint) NATURALCUBIC details knotmethod=percentilelist(90 95 97.5));

model tid*censored(0) = Group              
							sex uicc_final pt_cat
							BMIcS 
							year_cS 
							diagagecS
							DispInkKE04_cS
							CCI_weightedS / rl = wald ties = EFRON ;
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
/* Save output   */
data ny.OUT_OS_frailty_210706; set P_OUT_FRAILTY ;
run; 
