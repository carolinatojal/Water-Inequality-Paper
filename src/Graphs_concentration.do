********************************************************************************
** Graphs of gini index and concentraction curves for water expenditures 
********************************************************************************


cd ${folder_data}


*data: uses the imputed inconome from LAPOP
use "lapop_2021_income.dta", clear


********************************************************************************

* There are households with total water expenditures that are too large to be true 
keep if total_exp<4000 | total_exp==. // this is adhoc, only equador has expenses above this threshold 
drop if total_exp==. // this drops about 1/3 of the data 
drop if tap_exp==.
drop if urban==.


********************************************************************************
*Graphs Concentration indexes and Lorenz curve
********************************************************************************

** Loop to generate graphs for each country 
 decode pais,gen(country_name) // create variavle with country labels to use in the loop

 levelsof pais, local(levels) 
 foreach l of local levels {
 	
preserve 
keep if pais == `l'


local country=country_name[1]

gen income_eq=_1_iincome_ppp/(q12c^0.5) // here I use one income draw
 
drop if income_eq==. // drop if no income draw, we need the same number of obs with income and water expenditure

* Sort by income to create the rank
sort income_eq
glcurve income_eq [aw=wt], pvar(rank) nograph

*create cumulative share of income 
egen total_income=total(income_eq*wt)
gen cum_income=sum(income_eq*wt)
gen cumshare_income=cum_income/total_income


*create cumulative share of tapwater expenditures
gen watertap_eq=tap_exp/(q12c^0.5)
egen total_tapexp=total(watertap_eq*wt)
gen cum_tapexp=sum(watertap_eq*wt)
gen cumshare_tapexp=cum_tapexp/total_tapexp

*create cumulative share of total water expenses 
gen water_eq=total_exp/(q12c^0.5)
egen total_waterexp=total(water_eq*wt)
gen cum_waterexp=sum(water_eq*wt)
gen cumshare_waterexp=cum_waterexp/total_waterexp


*Graph

twoway (line cumshare_income rank, lcolor(grey%60) lpattern(solid)) (line cumshare_tapexp rank, lcolor(navy) lpattern(shortdash)) (line cumshare_waterexp rank, lcolor(midblue) lpattern(longdash)) (line rank rank, lcolor(grey%80) lpattern(dot)), ylabel(, tposition(inside) angle(horizontal) format(%4.1f) labsize(small))  ///
	xlabel(, tposition(inside)  format(%4.1f)  labsize(small)) ///
	legend(label(1 "Lorenz") label(2 "Concentration Tap Water") label(3 "Concentration All Water") label(4 "Equality")nobox region(lstyle(none))) ///  legend(off) 
	scheme(s1mono) ytitle("Cumulative income share" "Cumulative water expenditure share") xtitle("Cumulative share of people (ordered by income)") title("Concentration Curves `country'")
graph export ${folder_graphs}curvesweighted_country`l'.pdf, replace




restore

 }


********************************************************************************
*Tables for IADB Fact Sheet: not included in the main paper
********************************************************************************
 
 foreach l in "Uruguay" "Brasil" "Colombia" "Costa Rica"  {
 	
preserve 
keep if country_name=="`l'" 

gen income_eq=_1_iincome_ppp/(q12c^0.5) // here I use one income draw
 
drop if income_eq==. // drop if no income draw, we need the same number of obs with income and water expenditure

* Sort by income to create the rank
sort income_eq
glcurve income_eq [aw=wt], pvar(rank) nograph



*create cumulative share of income 
egen total_income=total(income_eq*wt)
gen cum_income=sum(income_eq*wt)
gen cumshare_income=cum_income/total_income


*create cumulative share of tapwater expenditures
gen watertap_eq=tap_exp/(q12c^0.5)
egen total_tapexp=total(watertap_eq*wt)
gen cum_tapexp=sum(watertap_eq*wt)
gen cumshare_tapexp=cum_tapexp/total_tapexp

*create cumulative share of total water expenses 
gen water_eq=total_exp/(q12c^0.5)
egen total_waterexp=total(water_eq*wt)
gen cum_waterexp=sum(water_eq*wt)
gen cumshare_waterexp=cum_waterexp/total_waterexp


xtile pct = income_eq [aw=wt], nq(5)
bys pct (income_eq): gen id = _n
bys pct: egen cutoff_id = max(id)
keep if id == cutoff_id

keep pct cumshare_income cumshare_tapexp cumshare_waterexp id cutoff_id


gen cum_pop="20" 
replace cum_pop="40" if pct==2
replace cum_pop="60" if pct==3
replace cum_pop="80" if pct==4
drop if pct==5 // 100% will not show up in the table 
drop if pct==.

replace cumshare_income=100*cumshare_income
replace cumshare_tapexp=100*cumshare_tapexp
replace cumshare_waterexp=100*cumshare_waterexp

eststo  clear
eststo: estpost  tabstat cumshare_income cumshare_tapexp cumshare_waterexp , by(cum_pop) stat(mean) nototal


local names "\multicolumn{1}{l}{\shortstack{\% of Population\\Ranked by Income}}&\multicolumn{1}{l}{\shortstack{Accumulated\\ \% Income}}& \multicolumn{1}{c}{\shortstack{Accumulated\\ \% Tap Water Expenditures}} &\multicolumn{1}{c}{\shortstack{Accumulated\\ \% Total Water Expenditures}}\\"

esttab est1  using "${folder_results}summarystats_factsheet_`l'.tex", replace f varlabels(`e(labels)') cells("cumshare_income(fmt(%9.0fc)) cumshare_tapexp(fmt(%9.0fc)) cumshare_waterexp(fmt(%9.0fc))") align(S) noobs nonumber longtable booktabs collabels(none) substitute(\_ _ ) posthead("`names'" "\midrule") nolines nomtitle


restore
 }
 

 
 