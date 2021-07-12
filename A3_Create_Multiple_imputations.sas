proc datasets lib=work mt=data kill; 
run; quit; 
/* Read data */
options nofmterr ; 
libname dat 'H:\Data\Original' ;
libname derived 'H:\Data\Derived' ;
libname ny "H:\Data\Derived\ny210706"; 

data X ; set ny.X210706; 
run; 
proc format ; 
value timedik 0 = '0-28 days' 1 = '29-56 days' 2 = '57- days' ; 
value timediksh 1 = '0-28 days' 2 = '29-56 days'  ; 
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
value asa 1="I"  2= "II" 3="III" 4 = "IV/V" 5 = "V"; 
value ny 0 = "No" 1 = "Yes" ; 
value lap 0 = 'Open' 1 = "Laparsokopi";
run; 
/*	************************************************************************	*/ 
proc sort data = X; by lopnr ; 
run; 
data X ; set X ; 
if asa_class = 5 then asa_class = 4 ; 		
format sex sex. asa_class asa. neoadj_ct neoadj_rt ny. 
		bcntry cntry. utbildning sunn. uicc_final stage. 
		ct ct. cn cn. cm cm. 
		pt_cat pt. pn pn. pm pm. 
		 A2_lapa lap. 
		lung ny. ; 
run; 
proc sort ; by lopnr ; 
run; 
								/* Multiple imputations */
									data MP ; set X ;
									keep lopnr sex asa_class neoadj_ct neoadj_rt 
									location surgery_hospital 
									utbildning uicc_final  bcntry
									ct cn cm pt_cat pn pm  
									cci_weighted DispInkKE04_c 
									BMIc year_c diagagec A2_konv A2_lapa lung 
									Time_Diag_OP_c ;
									run; 
									/* 50 imputations */
								proc mi data=MP seed=1347 nimpute=50 out=IMP noprint;
								   class 	sex uicc_final asa_class 
											neoadj_ct neoadj_rt bcntry
  										 	utbildning pt_cat
											a2_lapa lung ;
								   fcs nbiter=10 discrim(sex/ classeffects=include) 
								   				discrim(uicc_final/ classeffects=include) 
								   				discrim(pt_cat/ classeffects=include) 
												discrim(asa_class/classeffects=include) 
								   				discrim(neoadj_ct/classeffects=include) 
												discrim(neoadj_rt/classeffects=include) 
												discrim(bcntry/classeffects=include) 
												discrim(utbildning/classeffects=include) 
												discrim(a2_lapa/classeffects=include) 
												discrim(lung/ classeffects=include) 
												reg(BMIc)
												reg(diagagec)
												reg(cci_weighted) 
												reg(DispInkKE04_c)
												reg(year_c)
												reg(Time_Diag_OP_c) ;
								   	var lopnr sex asa_class neoadj_ct neoadj_rt 
									location surgery_hospital 
									utbildning uicc_final  bcntry
									ct cn cm pt_cat pn pm  
									cci_weighted DispInkKE04_c 
									BMIc diagagec year_c a2_lapa 
									lung Time_Diag_OP_c ;
									run;
proc sort data = IMP ; 
by lopnr _imputation_ ; run; 
/* Save data	*/
data ny.IMP_50imps_210706; set IMP;
run; 
