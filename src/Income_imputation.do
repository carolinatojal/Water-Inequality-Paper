********************************************************************************
** Generates the imputed income from LAPOP survey
********************************************************************************
cd ${folder_data}

use "lapop_clean_2021.dta", replace


****************************************************************************************************

*Adjust expenditure variables
 
 **** Tap water expenditures

gen tap_exp=psc2r1_ppp
replace tap_exp=0 if psc2r1_ppp==.a
replace tap_exp=0 if psc2r1_ppp==.b
replace tap_exp=0 if psc2r1_ppp==.c
replace tap_exp=0 if psc2r1_ppp==. & psc1c4_ppp!=. & psc2c1_ppp!=.

**** Bottled water expenditures

gen bottled_exp=psc1c4_ppp
replace bottled_exp=0 if psc1c4_ppp==.a
replace bottled_exp=0 if psc1c4_ppp==.b
replace bottled_exp=0 if psc1c4_ppp==.c
replace bottled_exp=0 if psc1c4_ppp==. & psc2r1_ppp!=. & psc2c1_ppp!=.

**** Tank water expenditures

gen tank_exp=psc2c1_ppp
replace tank_exp=0 if psc2c1_ppp==.a
replace tank_exp=0 if psc2c1_ppp==.b
replace tank_exp=0 if psc2c1_ppp==.c
replace tank_exp=0 if psc2c1_ppp==. & psc2r1_ppp!=. & psc1c4_ppp!=.


**** Total water expenditures
gen total_exp=tap_exp+bottled_exp+tank_exp

*replace total_exp=. if total_exp==0
*replace total_exp=. if tap_exp==0 & bottled_exp==0 & tank_exp==0
replace tap_exp=. if psc2r1_ppp==.
replace tap_exp=. if psc2r1_ppp==.a
replace tap_exp=. if psc2r1_ppp==.b

replace total_exp=. if psc2r1_ppp==. & psc1c4_ppp==. & psc2c1_ppp==.




**** We manipulate the data to create some explanatory variables for income 
* The proportion of children under 12 in the house
gen childrenratio= q12bn/q12c

* A dummy variable for respondents who declare white ethnicity 
gen white=0
replace white=1 if etid==1
replace white=. if etid==.a
replace white=. if etid==.b

* A dummy variable for respondents who declare mixed ethnicity
gen mixed=0
replace mixed=1 if etid==2
replace mixed=. if etid==.a
replace mixed=. if etid==.b

* A dummy variable for respondents who declare no education degree at all
gen noeduc=0
replace noeduc=1 if edr<=1
replace noeduc=. if edr==.a
replace noeduc=. if edr==.b

* A dummy variable for respondents who declare university degree
gen higheduc=0
replace higheduc=1 if edr==3
replace higheduc=. if edr==.a
replace higheduc=. if edr==.b




****** Loop to interpolate the income by country (store the results in dta files for each country)

drop if income==. // drop obs with missing income

tempfile data
save `data'

levelsof pais, local(levels) 
 foreach l of local levels {
  keep if pais == `l'
  

*  We take the logs of the interval boundaries
replace min_income_ppp=0.0000001 if min_income_ppp==0
gen log_min_incomeppp =log(min_income_ppp) 
gen log_max_incomeppp =log(max_income_ppp) 

 

*** Interval regression for income


intreg log_min_incomeppp log_max_incomeppp noeduc higheduc childrenratio r4 r6 r7 r15 r18n r16 r27 mixed, het(noeduc higheduc age estratopri) 

*** Multiple imputation process following Rios-Avila et al (2022)

intreg_mi ilincome_ppp, reps(50) seed(10)  // 


gen ilogincome_ppp = . 
tempfile tosave
save `tosave'

mi import wide, imputed(ilogincome_ppp=  ilincome_ppp* ) 
mi passive: gen iincome_ppp = exp(ilogincome_ppp) 

*for the incomes in the top brackets we will cap the ones that are above 2 sd of the generated mean in that brackets

 forval rep = 1/50 {
bys income: egen mean_bkt=mean(_`rep'_iincome_ppp) 
bys income: egen sd_bkt=sd(_`rep'_iincome_ppp) 
gen limit_upperbkt=mean_bkt+2*sd_bkt
replace _`rep'_iincome_ppp=limit_upperbkt if _`rep'_iincome_ppp>limit_upperbkt & _`rep'_iincome_ppp!=. & income==5
drop mean_bkt sd_bkt limit_upperbkt
 }

  save "lapop_clean_2021pais`l'.dta", replace
  use `data', replace
 }
 
****** Once we have performed the multiple imputation for each country, we append the data to reconstruct the full sample 

 use "lapop_clean_2021pais1.dta", replace
 
 forval i = 2/15 {
 	append using lapop_clean_2021pais`i'.dta
 }

 append using lapop_clean_2021pais17.dta
 
  forval i = 21/24 {
 	append using lapop_clean_2021pais`i'.dta
 } 
 

keep if country=="Brazil" | country=="Colombia"| country=="Costa Rica" | country=="Uruguay"

save "lapop_2021_income.dta", replace