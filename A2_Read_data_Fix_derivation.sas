proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data */
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ;
libname ny "H:\Data\Derived\ny210706"; 

data Ea_cci_patients ; set dat.Ea_cci_20210608; 	/* Charlson Comorbidity Index  */
run; 
data Ea_cdr ; set dat.Ea_cdr_20210608; 		/*Dödsorsaksregistret (Cause of death registry))*/
run; 
data Ea_demography ; set dat.Ea_demography_20210608; 
run; 
data Ea_ipr ; set dat.Ea_ipr_20210608;    /*Slutenvårdsregistret (In patient registry)*/
run; 
data Ea_lisa ; set dat.Ea_lisa_20210608; 		/*LISA*/
run; 
data Ea_lmed ; set dat.Ea_lmed; /*Läkemedelsregistret (Drug registry)*/
run; 
data Ea_migrations ; set dat.Ea_migrations_20210608; /* migration */
run; 
data Ea_scr; set dat.Ea_scr_20210608;  /* Cancer registry*/
run; 
data Ea_scrcr0; set dat.Ea_scrcr_20210608;  /*SCRCR*/
run; 
data set_ ; set Ny.Flowfinal210706; 
run; 
/*	*****************************************************************************************************************************	*/
proc format ; 
value timedik 0 = '0-28 days' 1 = '29-56 days' 2 = '57- days' ; 
value timediksh 1 = '0-28 days' 2 = '29-56 days'  ; 
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
proc sort data = Ea_scrcr0; by lopnr diagdate_scrcr; 
run; 
data Ea_scrcr0; set Ea_scrcr0;
by lopnr diagdate_scrcr  ; 
diagdate = diagdate_scrcr ; 
lopnr_cnter +1 ; if first.lopnr then lopnr_cnter=1; 
run;
proc sort data = SET_; by lopnr lopnr_cntr; run; 
data Ea_scrcr; merge Ea_scrcr0 set_ ; 
by lopnr lopnr_cnter;
if SET = 1 ; 
run; 												
proc sort data = Ea_scrcr nodupkey; 					/* 32355 patienter	*/
by lopnr ; run; 	

/* Time from diagnosis to different parts/components of the treatment */
data SCRCR_EXPOSURE; set Ea_scrcr;
if procedure = 1 then do ; 
Time_Diag_OP =  proceduredate   - diagdate +1 ; end;    /*Time to surgery*/	
	/*ingen if-sats här pga neoadj_ct_o1  finns inte */
	Time_Diag_NeoA_CYT =  neoadj_ct_date_o1   - diagdate +1 ;     /*Time to neoadj chemo*/
		if neoadj_rt_o1 = 1 then do ; 
		Time_Diag_NeoA_RD =  neoadj_rt_date_o1    - diagdate +1 ; end;    /*Time to neoadj radio*/
				if neoadj_rt_ct = 1 then do ; 
 				Time_Diag_NeoA_COMBO_CYT = neoadj_ct_date_rtct - diagdate +1 ;     /* Time to combo treatment */
				Time_Diag_NeoA_COMBO_RD = neoadj_rt_date_rtct - diagdate +1 ; end; 
Time_Diag_ANY = min(Time_Diag_OP , 
					Time_Diag_NeoA_CYT , 
					Time_Diag_NeoA_RD, 
					Time_Diag_NeoA_COMBO_CYT, 
					Time_Diag_NeoA_COMBO_RD);
if Time_Diag_ANY  = Time_Diag_OP  then First_TRT_type = 1 ; 
if Time_Diag_ANY  = Time_Diag_NeoA_CYT  then First_TRT_type = 2 ; 
if Time_Diag_ANY  = Time_Diag_NeoA_RD  then First_TRT_type = 3 ; 
if Time_Diag_ANY  = Time_Diag_NeoA_COMBO_CYT  then First_TRT_type = 4 ; 
if Time_Diag_ANY  = Time_Diag_NeoA_COMBO_RD  then First_TRT_type = 4 ; 
   /* Negative time put as missing */
if Time_Diag_OP <0 then  Time_Diag_OP = . ;
if Time_Diag_NeoA_CYT  <0 then  Time_Diag_NeoA_CYT = . ;
if Time_Diag_NeoA_RD  <0 then Time_Diag_NeoA_RD = . ;
if Time_Diag_NeoA_COMBO_CYT  <0 then  Time_Diag_NeoA_COMBO_CYT  = . ;
if Time_Diag_NeoA_COMBO_RD   <0 then  Time_Diag_NeoA_COMBO_RD = . ;
if Time_Diag_ANY <0 then  Time_Diag_ANY = . ;
keep lopnr diagdate location  proceduredate lopnr_cnter SET
	Time_Diag_OP Time_Diag_NeoA_CYT Time_Diag_NeoA_RD
	Time_Diag_NeoA_COMBO_CYT Time_Diag_NeoA_COMBO_RD
	Time_Diag_ANY  First_TRT_type ; 
format First_TRT_type  type.  location lok.; 
run; 
proc sort; by lopnr lopnr_cnter; run;
/*	_____________________________________________________________________________________________	*/
/* Variables to extract to include for confounder adjustment, demographics, etc 
-	Cancer location (location)           
-	Age of patient (diagage)		
-	Gender of patient (sex)			
-	Body mass index (derived from height & weight)	
-	Charlston comorbidity index.		
-	ASA-classification (asa_class)		
-	Preoperative isolated radiotherapy (neoadj_rt=1, neoadj_ct=0)		
-	Preoperative chemotherapy (neoadj_ct)				x
-	Preoperative cancer stage (calculated from tstage_clin, nstage_clin). 		
-	Adjuvant chemotherapy (adj_ct).				
-	Performing hospital (surgery_hospital). 		
-	Immigrant status (utlsvbakgr)					
-	Income, two years prior to colorectal cancer diagnosis. 
-	Level of education. Classified as not completed gymnasium, 
	completed gymnasium or at least 3 years of university studies (Sun2000niva). */
data SCRCR_Covariates ; set Ea_scrcr;
BMI = weight/((height/100)**2); 
keep lopnr   
lopnr_cnter SET
	year_
	location		  /* 1 = colon, 2 = rectum*/
	diagage      /*Age at diagnosis*/
    sex         /*1=male, 2=female*/
	neoadj_ct    /* Neoadjuvant chemotherapy (1=Yes/0=No) */
	neoadj_rt  /* Neoadjuvant radiation (1=Yes/0=No) */
	adj_ct /* Adjuvant chemotherapy (1=Yes/0=No)*/ 
		height    /*Height*/
 		weight     /*Weight*/
		asa_class   /*ASA*/
	surgery_hospital   /*Hospital */ 
	BMI 
		A2_konv A2_lapa;
run; 
proc sort; by lopnr lopnr_cnter; run; 
/* ___________________________________________________________________________________________*/
data SCRCR_stage ; set derived.stage210611 ;   /* TNM stage derived	*/
run; 
proc sort ; by lopnr lopnr_cnter; run; 
data SCRCR; merge SCRCR_EXPOSURE SCRCR_Covariates SCRCR_stage;
by lopnr lopnr_cnter; 
if SET = 1 ; 
run; 
/*___________________________________________________________________________________________________________________	*/
/* Charlson Comorbidity Index */
data CCI ; set Ea_cci_patients ; 
if copd = 1 OR other_cpd = 1 then lung = 1 ;
if lung = . then lung = 0 ; 
keep lopnr  CCI_weighted lung; 
run; 
proc sort; by lopnr ; run; 
/*___________________________________________________________________________________________________________________	*/
/* Country of birth */
data bcntry; set EA_demography ; 
run;
data bcntry; set bcntry; 
if birthcountry = 1 then bcntry = 1 ;
if 2 <= birthcountry <= 3  then bcntry  = 2 ;
if bcntry not in  (1, 2, 3) then bcntry  = 3 ;
format bcntry  cntry. ; 
keep lopnr bcntry ; 
run; 
proc sort; by lopnr; run; 
/*	____________________________________________________________________________________________________	*/
/* Migrated */
data migrations; set Ea_migrations; 
run; 
proc sort; by lopnr; run; 
proc datasets; 
modify migrations; 
format type ; 
run; 
/*_______________________________________________________________________________________________________	*/
/* Level of education*/
proc format ; 
value sun  	7="Forskare" 
			6="Eftergymnasial mer än 3 år" 
			5="Eftergymnasial mindre än 3 år"
			4 = "Gymnasium 3 år"
			3 = "Gymnasium 1-2 år"
			2 = "Grundskola"
			1 = "Folkskola" ; 
value sunn 1 = "Folkskola/Grundskola" 2 = "Gymnasium (1-2 eller 3 år)" 3 = "Efter gymnasial";
run; 
data utbildning ; set EA_lisa ; 
Sun2000niva_old2006NUM = 1*Sun2000niva_old2006 ; 	 
if Sun2000niva_old2006NUM in (1, 2) then utbildning = 1 ; 
if Sun2000niva_old2006NUM in (3, 4) then utbildning = 2 ; 
if Sun2000niva_old2006NUM in (5, 6, 7) then utbildning = 3 ; 
format Sun2000niva_old2006NUM sun. utbildning sunn. ; 
keep lopnr    utbildning ; 
run; 
proc sort; by lopnr; run; 
/*	******************************************************************************************************	*/
	/*Income*/
data Inkomst ; set EA_lisa ; 
keep lopnr 
		DispInkKE2006 - DispInkKE2016
		DispInkKE042006 - DispInkKE042016; 
run; 
proc sort; by lopnr; run; 
				/*Average disposable income during the 2 years before diagnosis*/
data info ; set Ea_scrcr; 
diagY = year(diagdate); 
Y_2 = diagY-2; 
Y_1 = diagY-1; 
keep lopnr diagdate diagage diagY Y_2 Y_1; 
run; 
proc sort; by lopnr; run; 
			proc transpose data = Inkomst out = KE04_ prefix = KE04_; 
			by lopnr; 
			var DispInkKE042006 - DispInkKE042016 ; 
			run; 
				proc transpose data = Inkomst out = KE_ prefix = KE_; 
				by lopnr; 
				var DispInkKE2006 - DispInkKE2016 ; 
				run; 
			data KE04_; set KE04_; 
			PY = 1*substr(_NAME_, 12); 	keep lopnr PY KE04_1 ; run; 
			proc sort; by lopnr PY; run; 
			data KE_; set KE_; 
			PY = 1*substr(_NAME_, 10); 	keep lopnr PY KE_1 ; 	run; 
			proc sort; by lopnr PY; run; 
			data KEKE; merge KE04_ KE_ ;
			by lopnr PY; run; 
			data KEKE ; merge info KEKE; 
			by lopnr ; 
			if diagy -2 <= PY <  diagy;
			run; 
			proc univariate data = KEKE noprint; 
			by lopnr; 
			var KE04_1 KE_1; 
			output out = KEKE mean = DispInkKE04 DispInkKE  ;
			run;  
/*	**************************   Outcome variables    *************************************************************	*/
proc format ; 
value index -1 = "Before index admission" 0 = 'During index admission' 
			 1 = "1-90 days after index admission" 2 = ">90 days after index admission" 
			 3 = 'Before/during or anytime after'; 
run; 
										data zrs; set Ea_scrcr; ; 
										keep lopnr; run; 
										proc sort data = zrs nodupkey ; 
										by lopnr ; run; 
										data zrs2; 
													set zrs; index = -1 ; output ; 
													set zrs; index = 0 ; output ; 
													set zrs; index = 1 ; output ; 
													set zrs; index = 2 ; output ; 
										format index index. ; 
										run; 
										proc sort; by lopnr index; run; 
/* Primary  */
   /* All-cause mortality */
data  Mortalitet ; set Ea_cdr ;
deathdate_num = 1*deathdate;     
keep lopnr deathdate deathdate_num cod ; 
run; 
proc sort; by lopnr; run; 
data  Mortalitet ; merge  Mortalitet Ea_scrcr ; 
by lopnr ; 
if deathdate_num ne . then do ;  
		FUdiagdate = deathdate_num - diagdate + 1 ;
		FUopdate = deathdate_num - proceduredate + 1 ;
		censored = 1 ; dead_at_FU = 1 ; 
		end; 
if deathdate_num = . then do ; 
		FUdiagdate = 1* input('12/31/2020', mmddyy10.) - diagdate + 1 ;
		FUopdate = 1* input('12/31/2020', mmddyy10.) - proceduredate + 1 ;
		censored = 0 ; dead_at_FU = 0 ; 
		end ;  
if location in (1, 2) ; 
index = 3 ; 
format index index. ; 
keep lopnr deathdate diagdate censored dead_at_FU index 
	FUdiagdate FUopdate proceduredate index; 
run; 
/*________________________________________________________________________________________________________________________	*/
/* Secondary 	*/
/*-	Length of hospital stay (derived from indate & outdate for hospital stay including procedure date).*/
data EA_ipr2 ; set EA_ipr ; 
keep lopnr diagdate_scrcr indate outdate hdia los 
		surgerycodes opd1--opd30 ; 
run; 
proc sort data = EA_ipr2 ;
by lopnr ; run;
data opdat ; set Ea_scrcr ; 
keep lopnr proceduredate ;
run; 
proc sort data = opdat ;
by lopnr ; run;
data EA_ipr3; merge EA_ipr2 opdat;
by lopnr ; 
run;
data LoS_index; set EA_ipr3;
if indate <= proceduredate & outdate => proceduredate then index = 0 ; 	/* Om man skrivs in innan op ut och efter op, så räknas det som index-vårdtillfälle*/									
if index = 0 ; 
LoS_index = los ;	 /* Date dischage - Date admission	*/
index = 0 ; 
format index index. ; 
keep lopnr LoS_index index;							
run; 
/* -	Re-admissions within 3 months. Defined as hospital admissions occurring 1-90 days 
	after procedure date, not including reversal of loop ileostomy (JFG00). */
data readm ; ; set EA_ipr3;
if outdate < proceduredate then index = -1 ;						  /*Om man skrivs ut innan opdat */
if indate <= proceduredate & outdate => proceduredate then index = 0 ; 	/* Om man skrivs in innan op ut och efter op, så räknas det som index-vårdtillfälle*/
if proceduredate < indate <= proceduredate+90  then index = 1 ; 		/* Läggs in efter utskrivning från index-vårdtillfälle*/
if indate > 90 + proceduredate  then index = 2 ; 		/* Läggs in 90 dagar efter utskrivning från index-vårdtillfälle*/
if proceduredate = . then index = . ; 
format index index. ;
drop surgerycodes opd1--opd30 ;
run; 
proc sort data = readm ; 
by lopnr index indate ; run; 
data readm; set readm; 
by lopnr index indate ; 
counter +1 ; 
if first.index then counter = 1 ; 
run; 
data readm; set readm; 
by lopnr index indate ; 
if last.index ;
run; 
proc sort data = readm nodupkey ; 
by lopnr index ; run; 
data readm ; merge readm zrs2 ; 
by lopnr index ;
run; 
data readm; set readm; 
additional_readmissions = counter ; 
if counter = . then additional_readmissions = 0 ; 
keep lopnr index additional_readmissions  ; 
run; 
/*-	Re-operations within 3 months. Defined as surgical procedures registered within 
	time frame +1-90 days from procedure date, excluding reversal of loop ileostomy (JFG00) */
data Reop ; set EA_ipr3;
keep lopnr surgerycodes opd1--opd30 
		proceduredate indate outdate; 
run; 
proc sort data =  Reop ; 
by lopnr surgerycodes proceduredate indate outdate; 
run; 
proc transpose data = Reop out = reop ; 
by lopnr surgerycodes proceduredate indate outdate; 
var opd1--opd30 ; 
run; 
data reop; set reop ; 
if outdate < proceduredate then index = -1 ;						  /*Om man skrivs ut innan opdat */
if indate <= proceduredate & outdate => proceduredate then index = 0 ; 	/* Om man skrivs in innan op ut och efter op, så räknas det som index-vårdtillfälle*/
if proceduredate < indate <= proceduredate+90  then index = 1 ; 		/* Läggs in efter utskrivning från index-vårdtillfälle*/
if indate > 90 + proceduredate  then index = 2 ; 		/* Läggs in 90 dagar efter utskrivning från index-vårdtillfälle*/
if proceduredate = . then index = . ; 
if COL1 = . then delete; 
format index index. ; 
drop COL2  ; 
run; 
proc sort data = reop; 
by lopnr index COL1 ; 
run; 
data reop; set reop; 
by lopnr index COL1 ; 
counter +1 ; 
if first.index then counter = 1 ; 
run; 
data reop; set reop; 
by lopnr index COL1 ; 
if last.index ;
run; 
proc sort data = reop nodupkey; 
by lopnr index ; 
run; 
data reop; merge reop zrs2; 
by lopnr index;  
additional_surgery = counter ; 
if counter = . then additional_surgery = 0 ; 
keep lopnr index surgerycodes _LABEL_ additional_surgery ; 
run; 
/*_____________________________________________________________________________________________________	*/
/*Data set with predictor/exposure, etc variables*/
data X ; merge SCRCR CCI bcntry migrations  utbildning keke cci ; 
by lopnr ; 
if SET = 1 ; 
run; 
proc sort data = X nodupkey ; 
by lopnr ; run; 
data X ; set X ; 
drop 	adj_ct  ; 
							/*Continuous variables log transformed*/
	BMIc = log(BMI) ; 
	diagagec = log(diagage) ;
	DispInkKE04_c = log(DispInkKE04) ;
	Year_c = log(Year_) ;
	Time_Diag_OP_c = log(Time_Diag_OP);
if CCI_unweighted = . then  CCI_unweighted = 0 ;    /*No value > 0 means = 0*/
if CCI_weighted = . then  CCI_weighted = 0 ; 
if 0 <= Time_Diag_ANY <= 4*7 then  Time_Diag_ANY_dik = 0 ; 
if 4*7 < Time_Diag_ANY<= 8*7 then  Time_Diag_ANY_dik = 1 ; 
if  Time_Diag_ANY > 8*7 then  Time_Diag_ANY_dik = 2 ; 
		if 0 <= Time_Diag_ANY <= 2*7 then  Time_Diag_ANY_dik2 = 0 ; 
		if 2*7 < Time_Diag_ANY <= 4*7 then  Time_Diag_ANY_dik2 = 1 ; 
		if 4*7 < Time_Diag_ANY<= 8*7 then  Time_Diag_ANY_dik2 = 2 ; 
		if  Time_Diag_ANY > 8*7 then  Time_Diag_ANY_dik2 = 3 ; 
				if 0 <=  Time_Diag_OP <= 4*7 then Time_diag_op_dik = 0 ; 
				if 4*7 <  Time_Diag_OP <= 8*7 then Time_diag_op_dik = 1 ; 
				if Time_Diag_OP > 8*7 then Time_diag_op_dik = 2 ;
format Time_Diag_ANY_dik Time_diag_op_dik  timedik. Time_Diag_ANY_dik2   timedikk.  ;
run;  
/* Standardize continuous variables	*/
proc stdize data = X out = X2 method = std;
var BMIc  diagagec   DispInkKE04_c Year_c Time_Diag_OP_c; 
run; 
/*	____________________________________________________________________________	*/
data X2; set X2; 
if asa_class = 5 then asa_class = 4 ; 		
keep  lopnr lopnr_cnter location SET 
		neoadj_ct 
		neoadj_rt 
		utbildning 
		surgery_hospital  
		 sex  bcntry
						BMI BMIc 
						diagage diagagec 
						CCI_weighted
						DispInkKE04_c DispInkKE04
						Year_ Year_c
						Time_Diag_OP Time_Diag_OP_c
			asa_class
			ct cn cm pt_cat pn pm
			uicc_final  A2_konv A2_lapa lung
		Time_Diag_ANY First_TRT_type 
		Time_Diag_ANY_dik
		Time_Diag_ANY_dik2
		Time_diag_op_dik;
format sex sex. asa_class asa. neoadj_ct neoadj_rt ny. 
		bcntry cntry. utbildning sunn. uicc_final stage. 
		ct ct. cn cn. cm cm. 
		pt_cat pt. pn pn. pm pm. A2_lapa lap.; 
	run; 
proc sort; by lopnr; 
run;
/*______________________________________________________________________________________________________________	*/
proc sort data = mortalitet ; 
by lopnr index ; run; 
proc sort data = LoS_index ; 
by lopnr index ; run; 
proc sort data = reop ; 
by lopnr index ; run; 
proc sort data = readm ; 
by lopnr index ; run; 

data Y ; merge mortalitet LoS_index reop readm ; 
by lopnr index ; 
run; 
data Y ; merge Y set_; 
by lopnr; 
if SET = 1 ; 
keep lopnr  index
		FUdiagdate FUopdate censored dead_at_FU
		los_index 
		additional_surgery 
		additional_readmissions ;
run; 
proc sort; by lopnr; 
run; 
proc sort data = Y nodupkey ; 
by lopnr index; run; 
/*______________________________________________________________________________________________________________	*/
/* Save data	*/
data ny.X210706; set X2 ; 
run; 
data ny.Y210706; set Y ; 
run; 
