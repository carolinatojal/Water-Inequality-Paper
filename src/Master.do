********************************************************************************
* Master Code
*Paper: Water expenditure, service quality and inequality in Latin
*America and the Caribbean
* authors: Mara Perez-Urdiales and Carolina Tojal R. dos Santos

********************************************************************************

global path "S:\WaterInequality\submission\"

global folder_data "${path}Data\"
global folder_do "${path}StataDos\"
global folder_results "${path}Results\"
global folder_graphs "${path}Graphs\"


*******************************************************************************
*1) Import LAPOP data, clean variables, imput income from the survey responses

do ${folder_do}Income_imputation.do

*2) Generates summary statistics
* Tables: 1, 2, 6
* Figures: 2, 3, 4, 5, 9

do ${folder_do}SummaryStats.do

*3) Analysis: gini index and concentration measures
*Tables: 3,4,5 

do ${folder_do}Concentration_index.do

*4) Graphs: Lorentz and Concentration Curves
*Figure: 7
do ${folder_do}Graphs_concentration.do