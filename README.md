
<!-- README.md is generated from README.Rmd. Please edit that file -->

# “Survival in relation to time to start of curative treatment of colon and rectal cancer is confounded by increased survival after laparoscopic surgery: A national register-based observational non-inferiority study”

Daniel Rydbeck, David Bock, Eva Haglind, Eva Angenete, Aron Onerup

# Description

Registry datasets was located on Colorectal Cancer data Base Sweden
(CRCBaSe) external server at Karolinska Institutet (KI), Sweden. Data
management and statistical analysis was performed via VPN Remote Access.
SAS software was used.

*Individual patient level data can not be publicly available or shared
due to restrictions in the ethics approval agreement (Ethical permission
was obtained from the Regional ethical committee in Stockholm February
26th 2014, Dnr 2014/71-31/1 for creation of the data base)*. The current
study was registered at ClinicalTrials.gov with trial registration
number NCT04571047, date of first registry September 30 2020.

# SAS code

The following SAS program code programs for data management and
statistical analysis are available:  
**1. A1\_analys\_set\_derivation**  
Derive analysis set based on inclusion and exclusion criteria.  
**2. A2\_Read\_data\_Fix\_derivation**  
Create analysis data set and derive relevant variables (covariates,
exposure and endpoints).  
**3. A3\_Create\_Multiple\_imputations**  
Create data set with multiple imputations (50) on the missing values of
the covariates used for confounder adjustment.  
**4. A4\_demography**  
Demography and patient characteristics.  
**5. B1\_Primary\_Outcome\_Surv\_curves**  
Adjusted survival curves for primary endpoint: all-cause mortality  
**6. B2\_Regressions\_models**  
Regression analyses for primary and secondary endpoints  
**7. B3\_Dose\_response\_Survival**  
Estimate dose-response relationship between time from diagnosis to start
of treatment and 5 year survival  
**8. C1\_PostHoc\_1\_Surv\_curves**  
Post hoc analysis 1: Heterogeneity in the relationship time from
diagnosis to start of treatment and all-cause mortality with rehard to
surgical technique (Laparoscopy/Open). Adjusted survival curves  
**10. C2\_PostHoc\_1\_Cox\_regression**  
Post hoc analysis 1: Heterogeneity in the relationship time from
diagnosis to start of treatment and all-cause mortality with regard to
surgical technique (Laparoscopy/Open). Cox regression.  
**11. D\_PostHoc\_2\_Surv\_curves\_Cox\_regression**  
Post hoc analysis 2: The relationship between surgical technique
(Laparoscopy/Open) and all-cause mortality. Adjusted survival curves and
Cox regression.
