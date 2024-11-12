
********************************************************************************
** Computes the Gini Indexes and the Concentration index of water expenditures 
***


cd ${folder_data}

*data: uses the imputed inconome from LAPOP
use "lapop_2021_income.dta", clear

**********************************************************************************
*WEIGHTS

*wt: weights for to analyze each country separatly
*weight1500: weights for comparisosn accross countries 

mi svyset upm [pw=wt], strata(strata)
********************************************************************************



* There are households with total water expenditures that are too large to be true 
keep if total_exp<4000 | total_exp==. // this is adhoc, only equador has expenses above this threshold 
drop if total_exp==. // this drops about 1/3 of the data 
drop if tap_exp==.
drop if urban==.


**************************************************************************************

*Compute indexes for each country


* Loop over countries: 
 levelsof pais, local(levels) 
 foreach l of local levels {
 	
	preserve 
 keep if pais == `l'
 


**** Gini and Concentration coefficients 


* Compute one index for each income draw and then average among them 

  forval n = 1/50 { //loop over income draws
 
 
 gen income_eq=_`n'_iincome_ppp/(q12c^0.5)


drop if income_eq==. // drop if no income draw, we need the same number of obs with income and water expenditure

* Sort by income to create the rank
sort income_eq
glcurve income_eq [aw=wt], pvar(rank) nograph //creates the ranking considering weights

* Create mean income
qui sum income_eq [aw=wt] 
gen meanincome = r(mean)

* Create the variance of the rank
qui sum rank [aw=wt] 
gen varrank=r(Var)


* Estimate the OLS regression, the Gini Index would be the estimated coefficient for rank
gen dep=2*varrank*(income_eq/meanincome)
reg dep rank [aw = wt]

gen gini_`n'=_b[rank]


** Water tap expenses concentration coefficient 
* Compute tap water expenditures equivalized
gen watertap_eq=tap_exp/(q12c^0.5)
* Compute the mean of tap water expenditures (the rank remains the same as in the Gini Index)
qui sum watertap_eq [aw=wt] 
gen meanwatertapexp = r(mean)


* Estimate the OLS regression, the tap expenses concentration index would be the estimated coefficient for rank. The results show, as expected, a lower index which is due to the fact that there is less variation in tap water expenses than in income
gen depwatertap=2*varrank*(watertap_eq/meanwatertapexp)

reg depwatertap rank [aw = wt]
gen conc_tapwater_`n'=_b[rank]

** Water total expenses concentration coefficient 
* Compute total water expenditures equivalized
gen water_eq=total_exp/(q12c^0.5)  // THIS IS BECAUSE OF ECONOMIES OF SCALE WITHIN THE HOUSEHOLD
* Compute the mean of total water expenditures (the rank remains the same as in the Gini Index, but we should consider reranking depending on the sample size)
qui sum water_eq [aw=wt] 
gen meanwater_eq = r(mean)

* Estimate the OLS regression, the total expenses concentration index would be the estimated coefficient for rank
gen depwater=2*varrank*(water_eq/meanwater_eq)
reg depwater rank [aw=wt] 

gen conc_allwater_`n'=_b[rank]

* Compute the post income after paying tapwater
gen post_income_tap_eq=income_eq-watertap_eq
* Compute the mean of income post total water expenses (the rank remains the same as in the Gini Index)
qui sum post_income_tap_eq [aw=wt] 
gen meanpostincome_tap = r(mean)


* Estimate the OLS regression, the gini index for income post total water expenses would be the estimated coefficient for rank
gen deppostincome_tap=2*varrank*(post_income_tap_eq/meanpostincome_tap) //KEEP THE INCOME RANK AND THE 
qui reg deppostincome_tap rank [aw=wt] 

gen ginipost_tap_`n'=_b[rank]

* Sort by post-income after paying for tap water_eq

sort post_income_tap_eq
glcurve post_income_tap_eq [aw=wt], pvar(rankpost_tap) nograph

* Create the variance of the rank
qui sum rankpost_tap [aw=wt] 
gen varrankpost_tap=r(Var)

* Estimate the OLS regression, the gini index for income post tap water expenses based on its own rank would be the estimated coefficient for rank
gen deppostincome_tap_post=2*varrankpost_tap*(post_income_tap_eq/meanpostincome_tap) //KEEP THE INCOME RANK AND THE 
qui reg deppostincome_tap_post rankpost_tap [aw=wt] 

gen ginipost_tap_post_`n'=_b[rankpost_tap]

* Compute the post income after paying water
gen post_income_all_eq=income_eq-water_eq

* Sort by post-income to create the rank
sort post_income_all_eq
glcurve post_income_all_eq [aw=wt], pvar(rankpost) nograph

* Create the variance of the rank
qui sum rankpost [aw=wt] 
gen varrankpost=r(Var)


* Compute the mean of income post total water expenses (the rank remains the same as in the Gini Index)
qui sum post_income_all_eq [aw=wt] 
gen meanpostincome_all = r(mean)

* Estimate the OLS regression, the gini index for income post total water expenses reranking the observations would be the estimated coefficient for rank
gen deppostincome_allpost=2*varrankpost*(post_income_all_eq/meanpostincome_all) //KEEP THE INCOME RANK AND THE 
qui reg deppostincome_allpost rankpost [aw=wt]

gen ginipost_allwaterpost_`n'=_b[rankpost]

* Estimate the OLS regression, the gini index considering the initial ranking for income post total water expenses would be the estimated coefficient for rank
gen deppostincome_all=2*varrank*(post_income_all_eq/meanpostincome_all) //KEEP THE INCOME RANK AND THE 
qui reg deppostincome_all rank [aw=wt]

gen ginipost_allwater_`n'=_b[rank]


drop income_eq rank meanincome varrank dep watertap_eq meanwatertapexp depwatertap depwatertap water_eq meanwater_eq depwater depwater post_income_tap_eq  meanpostincome_tap deppostincome_tap post_income_all_eq meanpostincome_all deppostincome_all rankpost varrankpost deppostincome_allpost rankpost_tap varrankpost_tap deppostincome_tap_post 

  }

  
* Average the indexes obstained with the different income draws  
egen gini_income=rowmean(gini_*)
egen conc_tapwater=rowmean(conc_tapwater_*)
egen conc_allwater=rowmean(conc_allwater_*)  
egen ginipost_tap=rowmean(ginipost_tap_*)
egen ginipost_allwater=rowmean(ginipost_allwater_*)
egen ginipost_allwaterpost=rowmean(ginipost_allwaterpost_*)
egen ginipost_tap_post=rowmean(ginipost_tap_post_*)

*Kakwani index tap water
gen k_tapwater=conc_tapwater-gini_income

*Kakwani index all water
gen k_all=conc_allwater-gini_income

* Redistribution effect for total expenditures

gen re_all=gini_income-ginipost_allwaterpost

* Vertical effect for total expenditures

gen ve_all= gini_income-ginipost_allwater

* Reranking effect for total expenditures

gen rr_all=re_all-ve_all

* Redistribution effect for tap expenditures

gen re_tap_all=gini_income-ginipost_tap_post

* Vertical effect for tap expenditures

gen ve_tap_all= gini_income-ginipost_tap

* Reranking effect for tap expenditures

gen rr_tap_all=re_tap_all-ve_tap_all


keep pais country gini_income conc_tapwater k_tapwater conc_allwater k_all ginipost_tap ginipost_allwater ginipost_allwaterpost ginipost_tap_post re_all ve_all rr_all re_tap_all ve_tap_all rr_tap_all
duplicates drop 

save "${folder_results}\indexes_pais`l'.dta", replace
 
restore
}

 
*Append the indexes for all Countries

 use "${folder_results}\indexes_pais6.dta", replace
 
 
 foreach i in 8 14 15 {
 	append using ${folder_results}\indexes_pais`i'.dta
 }


********************************************************************************
*Tab 3: Tap water indexes

eststo  clear
eststo: estpost tabstat gini_income ginipost_tap_post re_tap_all ve_tap_all rr_tap_all , by(country) stat(mean) nototal


local names "\multicolumn{1}{l}{\shortstack{Country\\}}&\multicolumn{1}{l}{\shortstack{Gini\\}}& \multicolumn{1}{c}{\shortstack{Gini\\Post Piped Water}} &\multicolumn{1}{c}{\shortstack{Redistribution Effect\\Piped  Water}}  & \multicolumn{1}{c}{\shortstack{Vertical Effect\\Tap Water}} & \multicolumn{1}{c}{\shortstack{Reranking Effect\\Piped Water}}  \\"

esttab est1  using "${folder_results}indexes_rerank_tapwater_weighted.tex", replace f varlabels(`e(labels)') cells("gini_income(fmt(%9.3fc)) ginipost_tap_post(fmt(%9.3fc)) re_tap_all(fmt(%9.3fc)) ve_tap_all(fmt(%9.3fc)) rr_tap_all(fmt(%9.3fc)) ") align(S) noobs nonumber longtable booktabs collabels(none) substitute(\_ _ ) posthead("`names'" "\midrule") no


********************************************************************************
* Tab 4:  All water indexes

eststo  clear
eststo: estpost tabstat gini_income ginipost_allwaterpost re_all ve_all rr_all , by(country) stat(mean) nototal


local names "\multicolumn{1}{l}{\shortstack{Country\\}}&\multicolumn{1}{l}{\shortstack{Gini\\}}& \multicolumn{1}{c}{\shortstack{Gini\\Post All Water}} &\multicolumn{1}{c}{\shortstack{Redistribution Effect\\All Water}}  & \multicolumn{1}{c}{\shortstack{Vertical Effect\\All Water}} & \multicolumn{1}{c}{\shortstack{Reranking Effect\\All Water}} \\"

esttab est1  using "${folder_results}indexes_rerank_allwater_weighted.tex", replace f varlabels(`e(labels)') cells("gini_income(fmt(%9.3fc)) ginipost_allwaterpost(fmt(%9.3fc)) re_all(fmt(%9.3fc)) ve_all(fmt(%9.3fc)) rr_all(fmt(%9.3fc))") align(S) noobs nonumber longtable booktabs collabels(none) substitute(\_ _ ) posthead("`names'" "\midrule") nolines nomtitle 
 
 
***********************************************************************************
*Tab 5: Concentration and Kakwani indexes



eststo  clear
eststo: estpost tabstat gini_income conc_tapwater k_tapwater conc_allwater k_all , by(country) stat(mean) nototal


local names "\multicolumn{1}{l}{\shortstack{Country\\}}&\multicolumn{1}{l}{\shortstack{Gini\\}}& \multicolumn{1}{c}{\shortstack{Concentration\\Piped water}} &\multicolumn{1}{c}{\shortstack{Kakwani\\Piped water}}  & \multicolumn{1}{c}{\shortstack{Concentration\\All water}} & \multicolumn{1}{c}{\shortstack{Kakwani\\All Water}} \\"

esttab est1  using "${folder_results}concentration_kakwani_indexes_weighted.tex", replace f varlabels(`e(labels)') cells("gini_income(fmt(%9.3fc)) conc_tapwater(fmt(%9.3fc)) k_tapwater(fmt(%9.3fc)) conc_allwater(fmt(%9.3fc)) k_all(fmt(%9.3fc))") align(S) noobs nonumber longtable booktabs collabels(none) substitute(\_ _ ) posthead("`names'" "\midrule") nolines nomtitle







 
 