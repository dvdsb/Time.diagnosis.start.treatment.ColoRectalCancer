proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data	*/
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ;
libname ny "H:\Data\Derived\ny210706"; 

data Ea_cci_patients ; set dat.Ea_cci_20210608; 	/* Charlson Comorbidity Index  */
run; 
data Ea_cdr ; set dat.Ea_cdr_20210608; 		/*Cause of death registry*/
run; 
data Ea_demography ; set dat.Ea_demography_20210608;    /*Statistics Sweden demography data base*/
run; 
data Ea_ipr ; set dat.Ea_ipr_20210608;    /*In patient registry*/
run; 
data Ea_lisa ; set dat.Ea_lisa_20210608; 		/*LISA*/
run; 
data Ea_migrations ; set dat.Ea_migrations_20210608; 
run; 
data Ea_scr; set dat.Ea_scr_20210608;  /* Cancer registry*/
run; 
data Ea_scrcr; set dat.Ea_scrcr_20210608;  /*Swedish colorectal cancer registry*/
run; 
data CHK; set derived.CHK210505;		/* To handle multiple rows per patient */
run; 
/* Inclusion criteria:
I1. -	Elective abdominal surgery with a curative intent in Sweden during 2008-2016.
I2. -	Colon cancer or rectal cancer. 
Exclusion criteria: 
E1. -	Emergency surgery
E2. -	Diagnosed for another cancer diagnosis during the last 5 years, excl skin tumours, 
	defined as ICD codes beginning with C43 or C44. Patients with a previous diagnose of C18, C19, or C20 
	(colorectal cancer) were not excluded from the study since this was an inclusion criterion. 
E3. -	Local tumour excision.
E4. -	Metastasized disease at diagnosis (mstage_clin)). */
data Ea_scrcr2 ; set Ea_scrcr;
keep lopnr  diagdate_scrcr  proceduredate
		location /* 1:kolon, 2: rektum */  
		procedure  /* 1=Yes, 0=No*/
	 emergency_surgery      /* 1: Planned, 2: Emergent*/
	 curative_proc     /*0=No, 1=Yes, 2=Unclear, 3=Unknown*/
	 palliative      /* 0=No, 1=Yes */ 
	cm 
	procedure_type ;
run; 									
data Ea_scrcr3 ; set Ea_scrcr2;
by lopnr diagdate_scrcr; 
/* If Emergency surgery = NO and Curative procedure not NO : Include 
(this means that if there is elective surgery AND missing on curative intent, the patient will be included)
 If Emergency surgery = YES OR Curative procedure =  NO : Exclude */
if emergency_surgery = 1 & curative_proc ne 0 then I1= 1; 
if emergency_surgery = 2 OR curative_proc = 0 then I1= 0;
	if location in (1, 2) then I2 = 1 ; 
	if location ~in (1, 2) then I2 = 0 ; 
		if	procedure_type in (1, 2, 4) then E3 = 1; 
		if	procedure_type in (3, .) then E3 = 0; 
			if cm = 2 then E4 = 1 ; 
			if cm ne 2 then E4 = 0 ; 
lopnr_cnter +1 ; if first.lopnr then lopnr_cnter=1; 
format B1 B2 crit. ; 
keep lopnr diagdate_scrcr proceduredate 
		I1 I2 E3 E4 lopnr_cnter location; 
run;    /*  63001 rows */
proc sort; by lopnr diagdate_scrcr; run; 
/*____________________________________________________________________________________________ */
/* Handle patients with several rows  */
data rader; set CHK; 
 if dbl ne '' ; 
keep lopnr diagdate inklusion location lopnr_cnter  dbl text ; 
 run; 
proc sort data = rader; 
by lopnr location lopnr_cnter ; 
run; 
data rader; set rader ; 
by lopnr location  ; 
loc +1 ; if first.location then loc=1; 
run; 
proc sort; by lopnr lopnr_cnter  ; run; 
data rader; set rader ; 
by lopnr lopnr_cnter  ;
if last.lopnr ; 
if lopnr_cnter ne loc then loc2 = 1;
if lopnr_cnter = loc then loc2 = 0;
run; 
proc format; 
value loc 	0 = 'Flera rader men samma diagnos på alla' 
			1 = 'Flera rader men EJ samma diagnos på alla' ; 
value ddd   0 = 'Flera rader men samma diagnosdatum på alla' 
			1 = 'Flera rader men EJ samma diagnosdatum på alla' ; 
value eee   0 = 'Flera rader men samma inklusionsbeslut på alla' 
			1 = 'Flera rader men EJ samma inklusionsbeslut på alla' ; 
run; 
data A_ ; set rader; 
keep lopnr loc2 inklusion;
format loc2 loc. ; 
run;  	
proc sort; by lopnr; run; 	
		data rdate; set CHK; 
		if dbl ne '' ; 
		keep lopnr diagdate inklusion location lopnr_cnter  dbl text ; 
		run;
		proc sort data = rdate; 
		by lopnr diagdate lopnr_cnter ; 
		run; 
		data rdate; set rdate ; 
		by lopnr diagdate  ; 
		diagdate_cnt +1 ; if first.diagdate then diagdate_cnt=1; 
		run; 
		data rdate2; set rdate ; 
		by lopnr diagdate  ; 
		if last.lopnr; 
		rader_diagdatum = compress(lopnr_cnter||'_'||diagdate_cnt); 
		if lopnr_cnter = diagdate_cnt then DD = 0 ; 
		if lopnr_cnter ne diagdate_cnt then DD = 1 ; 
		run; 
		data B_ ; set rdate2; 
		keep lopnr DD ; 
		format DD ddd. ; 
		run;   
		proc sort; by lopnr; run;  
/*	************************************************************************************************	*/
/*Exclusion criteria:  
E2. -	Diagnosed for another cancer diagnosis during the last 5 years, excl skin tumours, 
	defined as ICD codes beginning with C43 or C44. Patients with a previous diagnose of C18, C19, or C20 
	(colorectal cancer) were not excluded from the study since this was an inclusion criterion. */
										/*  2003 - 2016    */
proc format; 
value ex 1 = "C18/19/20" 2= "C43/C44" 3 = "Annan cancerdiagnos" 
		 4 = ">5 years" 5 = "< 5 years" 6 = "after"
		 7 = "date SCRCR=SCR" 8 = "date SCRCR!=SCR"; 
run; 

			data Ea_scr2; set Ea_scr; 
			cd = substr(icdo10, 1,3) ;
			if cd in ('C18', 'C19', 'C20') then icd=1;
			if cd in ('C43', 'C44') then icd=2;
			if icd = . then icd = 3 ; 
			label diagdate_scr = "Diag_date_SCR"; 
			diagdate_ = diagdate_scrcr ;
			format  diagdate_ diagdate_scr YYMMDD10.; 
			keep icdo10 icd lopnr diagdate_  diagdate_scr ;
			run; 
			proc sort; by lopnr diagdate_ diagdate_scr ; run; 									
			data Ea_scr3; set Ea_scr2; 
			by lopnr diagdate_ diagdate_scr; 	
			lopnr_cnter_SCR +1 ; if first.lopnr then lopnr_cnter_SCR=1; 
			run;                                    /*  69892  */
			proc sort; by lopnr diagdate_scr; run; 
data EA_scrcr3_scr3; merge Ea_scrcr3  Ea_scr3 A_ B_ ; 
by lopnr ; 
tidsdiff = diagdate_scrcr - diagdate_scr; 
if tidsdiff > 5*365.25 then timing = 4; 
if 0 <= tidsdiff <= 5*365.25  then timing = 5; 
if tidsdiff < 0  then timing = 6; 
	if diagdate = diagdate_ then date_check = 7 ; 
	if diagdate ne diagdate_ then date_check = 8 ; 
/* Diagnosed for another cancer diagnosis during the last 5 years */
if icd = 3 & timing = 5 then E2 = 1 ; 
if E2 = . then E2 = 0 ; 
format icd timing date_check ex. ; 
run;
/*_____________________________________________________________________________________	*/
/* Inclusion criteria:
I1. -	Elective abdominal surgery with a curative intent in Sweden during 2008-2016.
I2. -	Colon cancer or rectal cancer. 
Exclusion criteria: 
E1. -	Emergency surgery
E2. -	Diagnosed for another cancer diagnosis during the last 5 years, excl skin tumours, 
	defined as ICD codes beginning with C43 or C44. Patients with a previous diagnose of C18, C19, or C20 
	(colorectal cancer) were not excluded from the study since this was an inclusion criterion. 
E3. -	Local tumour excision.
E4. -	Metastasized disease at diagnosis (mstage_clin)). */
data FlowChart1; set EA_scrcr3_scr3 ; 
run; 									
										/*78810 rows, 52868 patients*/
data FlowChart2; set FlowChart1; 
if I2 = 1 ; 
run; 										

										/*78810 rows, 52868 patients*/
data FlowChart3; set FlowChart2; 
if I1 = 1 ; 
run; 
										/*50440 rows, 34840 patients*/

data FlowChart4; set FlowChart3; 
if E2 = 0 ; 
run; 
										/*48383 rows, 34799 patients*/
data FlowChart5; set FlowChart4; 
if E3 = 0 ; 
run; 	
										/*48344 rows, 34777 patients*/
data FlowChart6; set FlowChart5; 
if E4 = 0 ; 
run; 									/*44267 rows, 32538 patients*/

/*Many rows take first date  */
data FlowChart7; set FlowChart6; 
if loc2 ne . & lopnr_cnter > 1 then delete ; 
run; 		
													/*42643 rows, 32363 patients*/
proc sort data = FlowChart7 nodupkey;
by lopnr  ; run; 
data FlowFinal; set FlowChart7; 
SET = 1 ; 
year_ = year(diagdate_scrcr) ; 
keep lopnr lopnr_cnter SET diagdate_scrcr year_ ;
run; 
/* Save data set */
data ny.FlowFinal210706; set FlowFinal; 
run; 



 
