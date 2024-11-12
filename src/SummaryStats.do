
********************************************************************************
** Generates summary statistics 

********************************************************************************

cd ${folder_data}

*data: uses the imputed inconome from LAPOP
*countries: Brazil , Colombia, Costa Rica and Uruguay 

use "lapop_2021_income.dta", clear
 

**********************************************************************************
*WEIGHTS

*wt: weights for to analyze each country separatly
*weight1500: weights for comparisosn accross countries 

**********************************************************************************



*Select and adjust variables

  forval n = 1/50 { //loop over income draws
gen income_`n'=_`n'_iincome_ppp
  }
  
egen income_imp=rowmean(income_*)

drop *_iincome_ppp 

gen expensestap=tap_exp
gen expenseswater=total_exp

*gen accesspiped=psc2f1_piped
gen accesspiped=0
replace accesspiped=1 if psc2f1_piped==. & tap_exp>0 & tap_exp!=.
replace accesspiped=1 if piped_dw==1 |  piped_ou==1 // if used piped water for drinking or other uses 
replace accesspiped=0 if accesspiped==. & improved==1
replace accesspiped=0 if accesspiped==. 

gen pipedfordrinking=piped_dw
gen bottledfordrinking=bottled


bys country: sum income_imp, d




*****************************************************************************

* Table 1: main stats
preserve

eststo clear
eststo: estpost sum income_imp  expensestap expenseswater accesspiped pipedfordrinking bottledfordrinking 

 
esttab est1  using "${folder_results}mainsummarystats_4countries.tex", replace f cells("mean(fmt(%9.2fc)) sd(fmt(%9.2fc)) min(fmt(%9.2fc)) max(fmt(%9.2fc)) count(fmt(%9.0fc))") gaps compress par align(S) noobs nonumber longtable booktabs coeflabel(income_imp "Income (USD PPP)"  expensestap "Exp tap water (USD PPP)" expenseswater "Exp total water (USD PPP)" accesspiped "Tap access (share)" pipedfordrinking "Tap drinking (share)" bottledfordrinking "Bottled drinking (share)") posthead("`names'" "\midrule") nolines nomtitle substitute(\_ _ )  

restore 




*****************************************************************************************



* Table 2: Access to tap, Tap for drinking, Bottled for drinking, Other for drinking 


gen share_exp_tap=tap_exp/total_exp
gen share_exp_bottled=bottled_exp/total_exp
gen share_exp_tank=tank_exp/total_exp



preserve


collapse (mean) accesspiped share_exp_tap share_exp_bottled [aweight=wt], by (country pais)
 
 
eststo  clear
eststo: estpost  tabstat accesspiped share_exp_tap share_exp_bottled  , by(country) stat(mean) nototal


local names "\multicolumn{1}{l}{\shortstack{Country\\}}&\multicolumn{1}{l}{\shortstack{Acess to Piped Water\\ (Share population)}}& \multicolumn{1}{c}{\shortstack{Tap Water Exp.\\(Share of Total Water Exp.)}} & \multicolumn{1}{c}{\shortstack{Bottled Water Exp.\\(Share of Total Water Exp.)}} \\"

esttab est1  using "${folder_results}summarystats_share_expwater_4countries.tex", replace f varlabels(`e(labels)') cells(" accesspiped(fmt(%9.2fc)) share_exp_tap(fmt(%9.2fc)) share_exp_bottled(fmt(%9.2fc)) share_exp_tank(fmt(%9.2fc))") align(S) noobs nonumber longtable booktabs collabels(none) substitute(\_ _ ) posthead("`names'" "\midrule") nolines nomtitle



restore 


*************************************************************************************
 *Figure 2: Access to piped Water/ Sources of Drinking Water/
 
 
preserve

collapse (mean) accesspiped pipedfordrinking bottledfordrinking [aweight=wt], by (country pais)

gsort country
gen id_pais=_n

labmask id_pais, values(country)


graph bar accesspiped pipedfordrinking bottledfordrinking, ///
over(id_pais, lab(angle(45)) sort(order)) ///
legend(region(lcolor(white)) rows(1)) bar(1, color(gs12)) bar(2,fcolor(dknavy) ) bar(3,  fcolor( ltblue)) scheme(s1mono) ytitle("Share of Households") yvaroptions(relabel(1 "Acess to Tap Water" 2 "Tap Water for drinking"  3 "Bottled Water for Drinking"))  ysize(5) xsize(12) scale(1.1)
graph export ${folder_graphs}summary_access_4countries.pdf, replace


restore

*********************************************************************************

*Figure 3:  Income by country 


graph box income_imp  [aweight=wt], over(country, lab(angle(45))) noout note("") ///
legend(region(lcolor(white)) rows(1)) scheme(s1mono) ytitle("Income (USD PPP)") yvaroptions(relabel(1 "Income" )) 
graph export ${folder_graphs}boxplot_income_4countries.pdf, replace




 ********************************************************************************

*Figure 4: Tap Water Expenditure by country 


preserve
mi extract 0, clear

graph box total_exp tap_exp [aweight=wt], over(country) noout note("") ///
legend(region(lcolor(white)) rows(1)) bar(1,fcolor(midblue) ) bar(2,fcolor(dknavy) )  scheme(s1mono) ytitle("Expenditure (USD PPP)") yvaroptions(relabel(1 "Total Water" 2 "Tap Water" )) 
graph export ${folder_graphs}boxplot_exp_4countries.pdf, replace
restore



*****************************************************************************************

*Figure 5:  Share of income with water expenses by drinking by income quintile 
* Country by country 

levelsof pais, local(levels) 
foreach l of local levels {
 	
preserve 
keep if pais == `l'
 
local country_name=country[1]
 
 drop if expenseswater>income_imp & expenseswater!=.
drop if expensestap>income_imp & expensestap!=.

gen share_waterincome=expenseswater/income_imp
gen share_tapincome=expensestap/income_imp


collapse (mean) share_waterincome share_tapincome [aweight=wt], by (income)
 
drop if income==.


graph bar share_waterincome share_tapincome, over(income)  ///
legend(region(lcolor(white)) ) bar(1, color(navy)) bar(2,fcolor(midblue) ) scheme(s1mono) ytitle("Share of Income") b1title("Income Quintiles") yvaroptions(relabel(1 "All water expenses" 2 "Tap water expenses" )) ylabel(0(.1)1)  title("`country_name'")
graph export ${folder_graphs}summary_income_waterexpenses_`l'.pdf, replace

restore 
 
}


*******************************************************************************************
*Figure 9: Drinking Sources by Income


levelsof pais, local(levels) 
foreach l of local levels {
 	
preserve 
keep if pais == `l'
 
local country_name=country[1]
 

collapse (mean) pipedfordrinking bottledfordrinking [aweight=wt], by (income)
 
drop if income==.

gen otherdrinking=1-pipedfordrinking-bottledfordrinking

graph bar pipedfordrinking bottledfordrinking otherdrinking, over(income) stack ///
legend(region(lcolor(white)) ) bar(1, color(dknavy)) bar(2,fcolor(ltblue) ) bar(3,  fcolor(olive_teal)) scheme(s1mono) ytitle("Share of Households") b1title("Income Quintiles") yvaroptions(relabel(1 "Tap Water for Drinking" 2 "Botlled Water for Drinking"  3 "Other Sources of Water for Drinking")) title("`country_name'")
graph export ${folder_graphs}summary_income_typedrinking_`l'.pdf, replace

restore 
 
}


********************************************************************************
* Table 6:  Reasons for drinking bottled water 
tab bottled_why_simplified, g(reasons)

preserve
* Drop countries that seems to have problems in the data


collapse (mean) reasons* [aweight=wt], by (country pais)
eststo  clear
eststo: estpost tabstat reasons*, by(country) stat(mean) nototal


local names "\multicolumn{1}{l}{\shortstack{Country\\}}&\multicolumn{1}{l}{\shortstack{Better\\Taste}}& \multicolumn{1}{l}{\shortstack{Better\\Color}} &\multicolumn{1}{l}{\shortstack{Better\\Quality}} & \multicolumn{1}{l}{\shortstack{Avoid\\Contamination}} &\multicolumn{1}{l}{\shortstack{Better\\Availability}}&\multicolumn{1}{l}{\shortstack{Custom\\}}&\multicolumn{1}{l}{\shortstack{Other\\Reasons}}\\"

esttab est1  using "${folder_results}reasons_bottled_4countries.tex", replace f varlabels(`e(labels)') cells("reasons1(fmt(%9.2fc)) reasons2(fmt(%9.2fc)) reasons3(fmt(%9.2fc)) reasons4(fmt(%9.2fc)) reasons5(fmt(%9.2fc)) reasons6(fmt(%9.2fc)) reasons7(fmt(%9.2fc))") align(S) noobs nonumber longtable booktabs collabels(none) substitute(\_ _ ) posthead("`names'" "\midrule") nolines nomtitle

restore



